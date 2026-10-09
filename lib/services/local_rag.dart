import 'package:agrozen/data/repositories/knowledge_repository.dart';

/// Result of a retrieval step.
class RagResult {
  /// Answer text grounded in the retrieved articles.
  final String answer;

  /// Display names of the knowledge files the answer came from.
  final List<String> sources;

  const RagResult({required this.answer, required this.sources});

  bool get hasSources => sources.isNotEmpty;
}

/// Offline retrieval-augmented generation over `knowledge/broilers/`.
///
/// The safety rule from the product spec is: *"AI answers only from the
/// knowledge base; if there is no answer, say so and send the farmer to a
/// veterinarian."* This class implements that rule without a network call, so
/// the assistant still works in a village with no connectivity.
class LocalRag {
  final KnowledgeRepository _repo;

  const LocalRag(this._repo);

  /// The knowledge topics available in this build. File names without `.md`.
  static const List<String> _topics = [
    '01_preparation',
    '02_first_days',
    '03_temperature',
    '04_ventilation',
    '05_feeding',
    '06_water',
    '07_vaccination',
    '08_diseases',
    'temperature',
    'feed',
    'vaccination',
    'ventilation',
  ];

  /// Aliases so farmers writing in either language or in plain speech still
  /// hit the right article.
  static const Map<String, List<String>> _aliases = {
    'temperature': [
      'harorat', 'issiq', 'sovuq', 'temperatura', 'gradus', 'цельс',
      'температур', 'холод', 'жар', 'qizib', 'xona',
    ],
    'feed': [
      'yem', 'ovqat', 'korm', 'корм', 'кормлен', 'granula', 'granul',
      'start', 'finish', 'protein', 'oqsil', 'белок', 'aralash',
    ],
    'vaccination': [
      'emlash', 'vaktsina', 'вакцин', 'прививк', 'nyukasl', 'новорос',
      'gamboro', 'гамборо', 'kasall', 'болез', 'dori', 'антибиот',
      'antibiotic', 'tashxis', 'диагноз', 'симптом',
    ],
    'ventilation': [
      'shamol', 'shamollatish', 'вентиляц', 'havo', 'ammiak', 'аммиак',
      'свежий воздух', 'prito', 'приток',
    ],
    '06_water': [
      'suv', 'vod', 'вод', 'пойлок', 'пилки', 'поениц', 'nipplet', 'ниппел',
      'obihidrat', 'обезвож',
    ],
    '01_preparation': [
      'tayyor', 'подготов', 'dezinfek', 'дезинфекц', 'bruder', 'брудер',
      'to\'shama', 'подстил', 'завоз',
    ],
    '02_first_days': [
      'birinchi kun', 'первые', 'zob', 'зоб', 'soat', 'jo\'ja', 'joja',
      'цыпленок', 'цыплят',
    ],
    '08_diseases': [
      'kasallik', 'симптом', 'priznak', 'признак', 'coccid', 'кокцид',
      'ascite', 'асцит', 'nafas', 'дыхан', 'holsiz', 'вялост',
    ],
  };

  /// Normalizes a question for keyword matching.
  ///
  /// Lowercases and folds Russian `ё` -> `е`, so «Падёж» matches the stem
  /// «падеж». Without this a farmer writing ё would silently miss every rule.
  static String _norm(String s) => s.toLowerCase().replaceAll('ё', 'е');

  /// Keywords that mean the farmer is describing an emergency.
  /// These are STEMS, not full words, so «падёж», «падежа» and «падежом» all
  /// match.
  static const List<String> _emergencyKeywords = [
    'olim', 'olum', 'nobod', 'массов', 'гиб', 'gib', 'padej', 'падеж',
    'tuyuk', 'туя', 'oqish', 'понос', 'ishit',
    'задыха', 'zayix', 'душн', 'тепловой стресс',
  ];

  /// Human-readable titles shown to the farmer, keyed by file name.
  /// The file names themselves are meaningless to a farmer.
  static const Map<String, Map<String, String>> _titles = {
    'temperature': {
      'ru': 'Температура и влажность',
      'uz': 'Harorat va namlik',
    },
    '03_temperature': {
      'ru': 'Температура и влажность',
      'uz': 'Harorat va namlik',
    },
    'feed': {
      'ru': 'Фазы кормления',
      'uz': 'Oziqlantirish bosqichlari',
    },
    '05_feeding': {
      'ru': 'Фазы кормления',
      'uz': 'Oziqlantirish bosqichlari',
    },
    'vaccination': {
      'ru': 'Ветеринарные правила',
      'uz': 'Veterinariya qoidalari',
    },
    '07_vaccination': {
      'ru': 'Вакцинация',
      'uz': 'Emlash',
    },
    'ventilation': {
      'ru': 'Вентиляция и микроклимат',
      'uz': 'Shamollatish va mikroiqlim',
    },
    '04_ventilation': {
      'ru': 'Вентиляция и микроклимат',
      'uz': 'Shamollatish va mikroiqlim',
    },
    '06_water': {'ru': 'Вода и поилки', 'uz': 'Suv va suv berish'},
    '01_preparation': {
      'ru': 'Подготовка помещения до завоза',
      'uz': 'Xonani tayyorlash',
    },
    '02_first_days': {
      'ru': 'Приём цыплят и первые 3 дня',
      'uz': "Jo'jalarni qabul qilish va birinchi kunlar",
    },
    '08_diseases': {
      'ru': 'Признаки болезни — когда нужен ветеринар',
      'uz': 'Kasallik belgilari — qachon veterinar kerak',
    },
  };

  /// Returns the display title for a knowledge file, falling back to the raw
  /// file name if the topic has no title entry.
  static String titleFor(String topic, String language) {
    final isRu = language.toLowerCase() == 'ru';
    final byTopic = _titles[topic];
    if (byTopic == null) return topic;
    return isRu ? byTopic['ru'] ?? topic : byTopic['uz'] ?? topic;
  }

  /// Scores articles for [question] and returns the top [max] matches.
  Future<List<_Match>> _retrieve(
    String question,
    String lang,
    int max,
  ) async {
    final tokens = RegExp(r'[a-zA-Zа-яА-ЯёЁ0-9]+')
        .allMatches(question.toLowerCase())
        .map((m) => (m.group(0) ?? '').toLowerCase())
        .where((t) => t.length > 2)
        .toList();

    if (tokens.isEmpty) return const [];

    final scored = <_Match>[];

    for (final topic in _topics) {
      String content;
      try {
        content = await _repo.getTopicContent(lang, topic);
      } catch (_) {
        continue; // topic not present in this build
      }

      var score = 0;
      final haystack = content.toLowerCase();
      final aliases = _aliases[topic] ?? const <String>[];

      for (final token in tokens) {
        if (haystack.contains(token)) score += 2;
        if (aliases.any((a) => a.contains(token) || token.contains(a))) {
          score += 4;
        }
      }

      if (score > 0) {
        scored.add(_Match(topic: topic, score: score, content: content));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.length > max) scored.removeRange(max, scored.length);
    return scored;
  }

  /// Runs retrieval and builds an answer.
  ///
  /// Returns `null` when nothing in the knowledge base matches, which the
  /// caller must treat as "I don't know — ask the veterinarian".
  Future<RagResult?> answer({
    required String question,
    required String language,
  }) async {
    final matches = await _retrieve(question, language, 2);
    if (matches.isEmpty) return null;

    final sources = matches
        .map((m) => titleFor(m.topic, language))
        .toSet()
        .toList();

    // Surface the most relevant excerpt rather than inventing text.
    final snippets = <String>[];
    for (final match in matches) {
      final excerpt = _bestParagraph(match.content, question);
      if (excerpt.isNotEmpty) snippets.add(excerpt);
    }
    if (snippets.isEmpty) return null;

    final isRu = language.toLowerCase() == 'ru';
    final intro = isRu
        ? 'Из проверенной базы знаний AgroZen:'
        : "AgroZen tekshirilgan bilimlar bazasidan:";

    return RagResult(
      answer: '$intro\n\n${snippets.join('\n\n---\n\n')}',
      sources: sources,
    );
  }

  /// True when the question reads like an emergency and the farmer should be
  /// sent straight to the veterinarian.
  bool looksLikeEmergency(String question) {
    final lower = _norm(question);
    return _emergencyKeywords.any(lower.contains);
  }

  /// Keywords meaning the farmer is asking for medicine, dosages or a
  /// diagnosis. Product rule: *never prescribe, always refer to the vet*.
  /// Stems, so «дозу», «доза» and «дозировка» all match.
  static const List<String> _medicalKeywords = [
    'dori', 'антибиот', 'antibiot', 'doz', 'доз', 'tashxis', 'диагноз',
    'davol', 'леч', 'tablet', 'таблет', 'prick', 'колот', 'привив',
    'сироп', 'suspens', 'порош', 'kukun',
  ];

  /// The farmer is asking for treatment. We must refuse and refer.
  bool wantsMedicine(String question) {
    final lower = _norm(question);
    return _medicalKeywords.any(lower.contains);
  }

  /// The mandatory non-prescriptive refusal, in the farmer's language.
  String medicineRefusal(String language) {
    final isRu = language.toLowerCase() == 'ru';
    return isRu
        ? 'AgroZen не назначает лекарства и антибиотики самостоятельно. '
            'Дозировки и схемы лечения определяет только ветеринар. '
            'Опишите симптомы специалисту — при любых признаках болезни '
            'немедленно обратитесь к ветеринару вашего района.'
        : "AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi. "
            "Dozalarni va davolash tartibini faqat veterinar belgilaydi. "
            "Alomatlarni mutaxassisga ayting: kasallik belgilarida darhol "
            "tumaningiz veterinariga murojaat qiling.";
  }

  String _bestParagraph(String content, String question) {
    final tokens = RegExp(r'[a-zA-Zа-яА-ЯёЁ0-9]+')
        .allMatches(question.toLowerCase())
        .map((m) => (m.group(0) ?? '').toLowerCase())
        .where((t) => t.length > 2)
        .toSet();

    final paragraphs = content.split(RegExp(r'\n\s*\n'));
    var best = '';
    var bestScore = 0;

    for (final para in paragraphs) {
      final clean = para.trim();
      if (clean.isEmpty || clean.startsWith('#')) continue;
      var score = 0;
      final lower = clean.toLowerCase();
      for (final t in tokens) {
        if (lower.contains(t)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = clean;
      }
    }

    // Fall back to the first prose paragraph when no token matched.
    if (best.isEmpty) {
      for (final para in paragraphs) {
        final clean = para.trim();
        if (clean.isEmpty || clean.startsWith('#')) continue;
        best = clean;
        break;
      }
    }

    if (best.length > 700) best = '${best.substring(0, 700)}…';
    return best;
  }
}

class _Match {
  final String topic;
  final int score;
  final String content;

  const _Match({
    required this.topic,
    required this.score,
    required this.content,
  });
}

