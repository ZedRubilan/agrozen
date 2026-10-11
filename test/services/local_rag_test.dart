import 'dart:convert';

import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/services/flock_context_service.dart';
import 'package:agrozen/services/local_rag.dart';
import 'package:agrozen/services/tts_service.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('Russian vaccination schedule queries are NOT blocked by wantsMedicine and return guidance', () async {
      final realRag = LocalRag(KnowledgeRepository());
      const query = 'Когда делать прививку от Ньюкасла?';
      expect(realRag.wantsMedicine(query), isFalse);

      final result = await realRag.answer(
        question: query,
        language: 'ru',
      );
      expect(result, isNotNull);
      expect(result!.sources, contains('Вакцинация'));
      expect(result.answer, contains('Ньюкасла'));
    });

    test('detects emergencies in uz, ru, and en so we send the farmer to a vet', () {
      final rag = _ragWith(const {});
      expect(rag.looksLikeEmergency("Kecha 20 ta nobod bo'ldi"), isTrue);
      expect(rag.looksLikeEmergency('Падёж за сутки 5 птиц'), isTrue);
      expect(rag.looksLikeEmergency('Шиншиллы массово гибнут'), isTrue);
      expect(rag.looksLikeEmergency('My chicks are dying and gasping for air'), isTrue);
      expect(rag.looksLikeEmergency('Жарко ли в брудере?'), isFalse);
    });

    test('Uzbek words with straight and curly apostrophes tokenize and match topics/emergencies', () async {
      final realRag = LocalRag(KnowledgeRepository());

      // Straight ' and curly ’ in o'lim
      expect(realRag.looksLikeEmergency("Jo'jalarda o'lim ko'paydi"), isTrue);
      expect(realRag.looksLikeEmergency("Jo’jalarda o’lim ko’paydi"), isTrue);

      // Straight ' and curly ’ in jo'ja and go'ng
      final resStraight = await realRag.answer(
        question: "Birinchi kunlarda jo'ja zobi va eski go'ng tozalash",
        language: 'uz',
      );
      final resCurly = await realRag.answer(
        question: "Birinchi kunlarda jo’ja zobi va eski go’ng tozalash",
        language: 'uz',
      );
      expect(resStraight, isNotNull);
      expect(resCurly, isNotNull);
      expect(resStraight!.sources, equals(resCurly!.sources));
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

    test('real Uzbek numbered articles (01_tayyorgarlik, 02_birinchi_kunlar, 03_harorat, 06_suv, 08_kasalliklar) are reachable', () async {
      final realRag = LocalRag(KnowledgeRepository());

      // 06_suv.md
      final waterRes = await realRag.answer(
        question: 'suv harorati va nipel',
        language: 'uz',
      );
      expect(waterRes, isNotNull);
      expect(waterRes!.sources, contains('Suv va suv berish'));
      expect(waterRes.answer, contains("Suv — broyler uchun eng muhim"));

      // 01_tayyorgarlik.md
      final prepRes = await realRag.answer(
        question: 'dezinfeksiya va tayyorgarlik',
        language: 'uz',
      );
      expect(prepRes, isNotNull);
      expect(prepRes!.sources, contains('Xonani tayyorlash'));

      // 02_birinchi_kunlar.md
      final firstDaysRes = await realRag.answer(
        question: "birinchi kun jo'ja zob tekshirish",
        language: 'uz',
      );
      expect(firstDaysRes, isNotNull);
      expect(firstDaysRes!.sources, contains("Jo'jalarni qabul qilish va birinchi kunlar"));

      // 03_harorat.md
      final tempRes = await realRag.answer(
        question: 'harorat va namlik jadvali',
        language: 'uz',
      );
      expect(tempRes, isNotNull);
      expect(tempRes!.sources, contains('Harorat va namlik'));

      // 08_kasalliklar.md
      final diseaseRes = await realRag.answer(
        question: 'kasallik belgilari va holsizlik',
        language: 'uz',
      );
      expect(diseaseRes, isNotNull);
      expect(diseaseRes!.sources, contains('Kasallik belgilari — qachon veterinar kerak'));
    });

    test('strips raw HTML comments <!-- Source: ... --> and --- separators from snippets', () async {
      final rag = _ragWith({
        'knowledge/broilers/en/06_water.md': '<!--\nSource: Ross Broiler Management Manual\nStatus: Verified\n-->\n\n'
            '# Water and Drinker Management\n\n'
            '---\n\n'
            'Clean water at 18-21°C is critical for broiler chicks.\n\n'
            '---',
      });

      final res = await rag.answer(
        question: 'What water temperature is needed for drinker management?',
        language: 'en',
      );
      expect(res, isNotNull);
      expect(res!.answer, isNot(contains('<!--')));
      expect(res.answer, isNot(contains('-->')));
      expect(res.answer, isNot(contains('Source: Ross')));
      // Single-topic answer should not contain raw --- horizontal rule lines
      expect(res.answer, isNot(contains('\n---')));
      expect(res.answer, contains('18-21°C'));
    });

    test('titleFor maps file names to farmer-readable titles', () {
      expect(LocalRag.titleFor('temperature', 'ru'), 'Температура и влажность');
      expect(LocalRag.titleFor('temperature', 'uz'), 'Harorat va namlik');
      expect(LocalRag.titleFor('08_diseases', 'ru'),
          'Признаки болезни — когда нужен ветеринар');
      // Unknown topic falls back to the raw name instead of throwing.
      expect(LocalRag.titleFor('unknown_topic', 'ru'), 'unknown_topic');
    });

    test('responds warmly to "hello", "salom", and "привет" instead of returning null or unrelated articles', () async {
      final realRag = LocalRag(KnowledgeRepository());

      // Even if UI fallback language is 'uz', typing "hello" detects English and replies warmly
      final enHello = await realRag.answer(
        question: 'hello',
        language: 'uz',
      );
      expect(enHello, isNotNull);
      expect(enHello!.answer.toLowerCase(), contains('hello'));
      expect(enHello.answer, isNot(contains('Verified excerpt from')));

      final uzSalom = await realRag.answer(
        question: 'Assalomu alaykum, qalaysiz?',
        language: 'uz',
      );
      expect(uzSalom, isNotNull);
      expect(uzSalom!.answer, contains('Assalomu alaykum'));

      final ruPrivet = await realRag.answer(
        question: 'Привет, как дела?',
        language: 'uz',
      );
      expect(ruPrivet, isNotNull);
      expect(ruPrivet!.answer, contains('Здравствуйте'));
    });

    test('stopwords like "what", "are", "for" do not falsely match unrelated broiler manuals', () async {
      final rag = _ragWith({
        'knowledge/broilers/en/01_preparation.md':
            '# Preparation\n\nPrepare the poultry barn carefully for incoming chicks. What is needed is clean litter.',
      });

      // Unrelated question containing only stopwords ("what", "are", "for") + unrelated noun
      final unrelated = await rag.answer(
        question: 'What are the rules for football?',
        language: 'en',
      );
      expect(unrelated, isNull);
    });

    test('answers live flock status queries with personalized LiveFlockContext telemetry', () async {
      final rag = _ragWith(const {});
      const mockContext = LiveFlockContext(
        farmerName: 'Sardor aka',
        district: 'Samarqand',
        language: 'en',
        batchDay: 14,
        initialCount: 500,
        currentCount: 492,
        todayMortality: 0,
        todayFeedKg: 25.0,
        lastWeightG: 505.0,
        targetTemperatureC: 27.0,
        targetWeightG: 510.0,
        targetDailyFeedPerBirdG: 53.0,
        growthPhase: 'Grower',
        localVet: {'name': 'Dr. Alisher', 'phone': '+998901234567'},
      );

      final statusRes = await rag.answer(
        question: 'How are my chicks doing?',
        language: 'en',
        context: mockContext,
      );
      expect(statusRes, isNotNull);
      expect(statusRes!.answer, contains('Day 14'));
      expect(statusRes.answer, contains('492'));
      expect(statusRes.answer, contains('27°C'));
      expect(statusRes.answer, contains('Dr. Alisher'));
    });
  });

  group('TTS Voice Priority (Microsoft Natural & Gemini Voice -> Default TTS Fallback)', () {
    test('selectBestNativeVoice prioritizes Microsoft Natural voice first, then Gemini/Neural, then Default TTS', () {
      final voices = [
        {'name': 'en-US-default-local', 'locale': 'en-US'},
        {'name': 'Google en-US Network', 'locale': 'en-US'},
        {'name': 'Microsoft Aria Online (Natural) - English (United States)', 'locale': 'en-US'},
      ];

      final primary = TtsService.selectBestNativeVoice(voices, 'en');
      expect(primary, isNotNull);
      expect(primary!['name'], contains('Microsoft Aria Online (Natural)'));

      // When Microsoft Natural is absent, selects Gemini / Neural / Network voice
      final withoutMs = [
        {'name': 'en-US-default-local', 'locale': 'en-US'},
        {'name': 'Gemini Neural Voice', 'locale': 'en-US'},
      ];
      final secondTier = TtsService.selectBestNativeVoice(withoutMs, 'en');
      expect(secondTier, isNotNull);
      expect(secondTier!['name'], equals('Gemini Neural Voice'));

      // When forceDefault is true (fallback mode), selects local default voice
      final fallback = TtsService.selectBestNativeVoice(voices, 'en', forceDefault: true);
      expect(fallback, isNotNull);
      expect(fallback!['name'], equals('en-US-default-local'));
    });

    test('wrapPcm16LeToWav wraps raw 24kHz PCM bytes with a valid 44-byte RIFF WAVE header', () {
      final pcm = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final wav = TtsService.wrapPcm16LeToWav(pcm, sampleRate: 24000, channels: 1);

      expect(wav.length, equals(44 + pcm.length));
      expect(ascii.decode(wav.sublist(0, 4)), equals('RIFF'));
      expect(ascii.decode(wav.sublist(8, 12)), equals('WAVE'));
      expect(ascii.decode(wav.sublist(12, 16)), equals('fmt '));
      expect(ascii.decode(wav.sublist(36, 40)), equals('data'));
      expect(wav.sublist(44), equals(pcm));
    });
  });
}

