import 'dart:convert';

import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/services/local_rag.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves in-memory markdown so safety rules can be tested without the real
/// asset bundle.
class _FakeBundle extends CachingAssetBundle {
  final Map<String, String> files;

  _FakeBundle(this.files);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = files[key];
    if (content == null) throw Exception('Asset not found: $key');
    return content;
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(await loadString(key));
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

LocalRag _ragWith(Map<String, String> files) =>
    LocalRag(KnowledgeRepository(bundle: _FakeBundle(files)));

void main() {
  group('LocalRag safety rules (non-negotiable)', () {
    test('refuses to prescribe medicine, in both languages', () {
      final rag = _ragWith(const {});

      const uz = "Qanday dori va antibiotik berish kerak?";
      expect(rag.wantsMedicine(uz), isTrue);

      final refusal = rag.medicineRefusal('uz');
      expect(refusal,
          contains('AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi'));
      expect(refusal, contains('darhol tumaningiz veterinariga murojaat qiling'));
    });

    test('refuses in Russian too', () {
      final rag = _ragWith(const {});
      const ru = 'Какой антибиотик давать цыплятам?';
      expect(rag.wantsMedicine(ru), isTrue);

      final refusal = rag.medicineRefusal('ru');
      expect(refusal, contains('AgroZen не назначает лекарства и антибиотики'));
      expect(refusal, contains('ветеринар'));
      // No dosage language anywhere in the refusal.
      expect(refusal, isNot(contains('ml')));
      expect(refusal, isNot(contains('мг')));
    });

    test('detects dosage / diagnosis requests', () {
      final rag = _ragWith(const {});
      expect(rag.wantsMedicine('Какую дозу вакцины колоть?'), isTrue);
      expect(rag.wantsMedicine('Чем лечить кокцидиоз?'), isTrue);
      expect(rag.wantsMedicine('antibiotik dozasi qancha?'), isTrue);
    });

    test('normal husbandry questions are NOT treated as prescriptions', () {
      final rag = _ragWith(const {});
      expect(rag.wantsMedicine("Jo'jalarga qanday harorat kerak?"), isFalse);
      expect(rag.wantsMedicine('Kuniga necha kilo yem beraman?'), isFalse);
      expect(rag.wantsMedicine('Какая температура ночью?'), isFalse);
    });

    test('detects emergencies so we send the farmer to a vet', () {
      final rag = _ragWith(const {});
      expect(rag.looksLikeEmergency("Kecha 20 ta nobod bo'ldi"), isTrue);
      expect(rag.looksLikeEmergency('Падёж за сутки 5 птиц'), isTrue);
      expect(rag.looksLikeEmergency('Шиншиллы массово гибнут'), isTrue);
      expect(rag.looksLikeEmergency('Жарко ли в брудере?'), isFalse);
    });
  });

  group('LocalRag retrieval', () {
    test('answers from the knowledge file and cites it', () async {
      final rag = _ragWith({
        'knowledge/broilers/ru/temperature.md': '# Температура\n\n'
            'В первые 3 дня держите 33-34 °C.\n\n'
            'К 7 дню снижайте до 30 °C.',
      });

      final result = await rag.answer(
        question: 'Какая температура в первые дни?',
        language: 'ru',
      );

      expect(result, isNotNull);
      expect(result!.answer, contains('33-34'));
      expect(result.answer, contains('проверенной базы знаний'));
      expect(result.sources, contains('Температура и влажность'));
      expect(result.hasSources, isTrue);
    });

    test('returns null when the knowledge base has no match', () async {
      final rag = _ragWith({
        'knowledge/broilers/ru/temperature.md': '# Температура\n\nПро температуру птичника.',
      });

      final result = await rag.answer(
        question: 'Когда выиграет чемпионат по футболу?',
        language: 'ru',
      );
      expect(result, isNull);
    });

    test('works in Uzbek', () async {
      final rag = _ragWith({
        'knowledge/broilers/uz/05_feeding.md': "# Oziqlantirish\n\n"
            "Oziqlantirish 3 bosqichdan iborat. Start bosqichida oqsil "
            "22-23% bo'lishi kerak.",
      });

      final result = await rag.answer(
        question: 'Yemni qanday berish kerak?',
        language: 'uz',
      );

      expect(result, isNotNull);
      expect(result!.answer, contains('tekshirilgan bilimlar bazasidan'));
      expect(result.sources, isNotEmpty);
    });

    test('titleFor maps file names to farmer-readable titles', () {
      expect(LocalRag.titleFor('temperature', 'ru'), 'Температура и влажность');
      expect(LocalRag.titleFor('temperature', 'uz'), 'Harorat va namlik');
      expect(LocalRag.titleFor('08_diseases', 'ru'),
          'Признаки болезни — когда нужен ветеринар');
      // Unknown topic falls back to the raw name instead of throwing.
      expect(LocalRag.titleFor('unknown_topic', 'ru'), 'unknown_topic');
    });
  });
}
