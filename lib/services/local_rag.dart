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

  /// Mapping of canonical numbered topic names to Uzbek file names in `knowledge/broilers/uz/`.
  static const Map<String, String> _uzTopicMap = {
    '01_preparation': '01_tayyorgarlik',
    '02_first_days': '02_birinchi_kunlar',
    '03_temperature': '03_harorat',
    '04_ventilation': '04_shamollatish',
    '05_feeding': '05_oziqlantirish',
    '06_water': '06_suv',
    '07_vaccination': '07_emlash',
    '08_diseases': '08_kasalliklar',
  };

  /// Maps legacy summary topic names to their full numbered counterparts so we
  /// only fall back to the legacy summary when the numbered file is absent.
  static const Map<String, String> _legacyToNumbered = {
    'temperature': '03_temperature',
    'ventilation': '04_ventilation',
    'feed': '05_feeding',
    'vaccination': '07_vaccination',
  };

  /// Aliases so farmers writing in any supported language or plain speech still
  /// hit the right article.
  static const Map<String, List<String>> _aliases = {
    'temperature': [
      'harorat', 'issiq', 'sovuq', 'temperatura', 'gradus', 'цельс',
      'температур', 'холод', 'жар', 'qizib', 'xona', 'temperature',
      'heat', 'cold', 'warm', 'brooder', 'degree', 'celsius', 'humidity',
      'namlik', 'влажност',
    ],
    '03_temperature': [
      'harorat', 'issiq', 'sovuq', 'temperatura', 'gradus', 'цельс',
      'температур', 'холод', 'жар', 'qizib', 'xona', 'temperature',
      'heat', 'cold', 'warm', 'brooder', 'degree', 'celsius', 'humidity',
      'namlik', 'влажност',
    ],
    'feed': [
      'yem', 'ovqat', 'korm', 'корм', 'кормлен', 'granula', 'granul',
      'start', 'finish', 'protein', 'oqsil', 'белок', 'aralash',
      'feed', 'feeding', 'starter', 'grower', 'finisher', 'pellet',
      'crumble', 'ration', 'nutrition',
    ],
    '05_feeding': [
      'yem', 'ovqat', 'korm', 'корм', 'кормлен', 'granula', 'granul',
      'start', 'finish', 'protein', 'oqsil', 'белок', 'aralash',
      'feed', 'feeding', 'starter', 'grower', 'finisher', 'pellet',
      'crumble', 'ration', 'nutrition',
    ],
    'vaccination': [
      'emlash', 'vaktsina', 'вакцин', 'прививк', 'nyukasl', 'новорос',
      'gamboro', 'гамборо', 'kasall', 'болез', 'dori', 'антибиот',
      'antibiotic', 'tashxis', 'диагноз', 'симптом', 'vaccin',
      'newcastle', 'bronchitis', 'immun',
    ],
    '07_vaccination': [
      'emlash', 'vaktsina', 'вакцин', 'прививк', 'nyukasl', 'новорос',
      'gamboro', 'гамборо', 'kasall', 'болез', 'vaccin',
      'newcastle', 'bronchitis', 'immun',
    ],
    'ventilation': [
      'shamol', 'shamollatish', 'вентиляц', 'havo', 'ammiak', 'аммиак',
      'свежий воздух', 'prito', 'приток', 'ventilat', 'airflow', 'ammonia',
      'draft', 'tunnel', 'fan', 'oxygen',
    ],
    '04_ventilation': [
      'shamol', 'shamollatish', 'вентиляц', 'havo', 'ammiak', 'аммиак',
      'свежий воздух', 'prito', 'приток', 'ventilat', 'airflow', 'ammonia',
      'draft', 'tunnel', 'fan', 'oxygen',
    ],
    '06_water': [
      'suv', 'vod', 'вод', 'пойлок', 'пилки', 'поениц', 'nipplet', 'ниппел',
      'obihidrat', 'обезвож', 'water', 'drinker', 'nipple', 'dehydrat',
      'flushing',
    ],
    '01_preparation': [
      'tayyor', 'подготов', 'dezinfek', 'дезинфекц', 'bruder', 'брудер',
      "to'shama", 'подстил', 'завоз', 'prepar', 'disinfect', 'bedding',
      'litter', 'shavings', 'preheat',
    ],
    '02_first_days': [
      'birinchi kun', 'первые', 'zob', 'зоб', 'soat', "jo'ja", 'joja',
      'цыпленок', 'цыплят', 'first day', 'chick', 'crop fill', 'arrival',
      'placement',
    ],
    '08_diseases': [
      'kasallik', 'симптом', 'priznak', 'признак', 'coccid', 'кокцид',
      'ascite', 'асцит', 'nafas', 'дыхан', 'holsiz', 'вялост',
      'disease', 'symptom', 'illness', 'sick', 'droppings', 'diarrhea',
      'letharg',
    ],
  };

  /// Normalizes text for keyword matching.
  ///
  /// Lowercases, folds Russian `ё` -> `е` so «Падёж» matches «падеж», and
  /// normalizes Uzbek curly/modifier apostrophes (`’`, `‘`, `ʻ`, `` ` ``) to `'`.
  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r"[’‘ʻ`]"), "'");

  /// Strips HTML comments (`<!-- ... -->`) so author metadata never leaks into
  /// scoring or farmer-visible snippets.
  static String _stripHtmlComments(String s) =>
      s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

  /// Keywords that mean the farmer is describing an emergency.
  /// These are STEMS, not full words, so «падёж», «падежа» and «падежом» all
  /// match.
  static const List<String> _emergencyKeywords = [
    'olim', "o'lim", 'olum', "o'lum", 'nobod', 'массов', 'гиб', 'gib',
    'padej', 'падеж', 'tuyuk', 'туя', 'oqish', 'понос', 'ishit',
    'задыха', 'zayix', 'душн', 'тепловой стресс',
    'dying', 'dead', 'mortality', 'suffocat', 'gasping', 'panting',
    'diarrhea', 'bloody', 'paralyz', 'newcastle', 'coccidiosis', 'convuls',
  ];

  /// Human-readable titles shown to the farmer, keyed by file name.
  /// The file names themselves are meaningless to a farmer.
  static const Map<String, Map<String, String>> _titles = {
    'temperature': {
      'ru': 'Температура и влажность',
      'uz': 'Harorat va namlik',
      'en': 'Temperature and Humidity',
    },
    '03_temperature': {
      'ru': 'Температура и влажность',
      'uz': 'Harorat va namlik',
      'en': 'Temperature and Humidity',
    },
    '03_harorat': {
      'ru': 'Температура и влажность',
      'uz': 'Harorat va namlik',
      'en': 'Temperature and Humidity',
    },
    'feed': {
      'ru': 'Фазы кормления',
      'uz': 'Oziqlantirish bosqichlari',
      'en': 'Feeding Phases',
    },
    '05_feeding': {
      'ru': 'Фазы кормления',
      'uz': 'Oziqlantirish bosqichlari',
      'en': 'Feeding Phases',
    },
    '05_oziqlantirish': {
      'ru': 'Фазы кормления',
      'uz': 'Oziqlantirish bosqichlari',
      'en': 'Feeding Phases',
    },
    'vaccination': {
      'ru': 'Ветеринарные правила',
      'uz': 'Veterinariya qoidalari',
      'en': 'Veterinary Rules',
    },
    '07_vaccination': {
      'ru': 'Вакцинация',
      'uz': 'Emlash',
      'en': 'Vaccination',
    },
    '07_emlash': {
      'ru': 'Вакцинация',
      'uz': 'Emlash',
      'en': 'Vaccination',
    },
    'ventilation': {
      'ru': 'Вентиляция и микроклимат',
      'uz': 'Shamollatish va mikroiqlim',
      'en': 'Ventilation & Microclimate',
    },
    '04_ventilation': {
      'ru': 'Вентиляция и микроклимат',
      'uz': 'Shamollatish va mikroiqlim',
      'en': 'Ventilation & Microclimate',
    },
    '04_shamollatish': {
      'ru': 'Вентиляция и микроклимат',
      'uz': 'Shamollatish va mikroiqlim',
      'en': 'Ventilation & Microclimate',
    },
    '06_water': {
      'ru': 'Вода и поилки',
      'uz': 'Suv va suv berish',
      'en': 'Water & Drinkers',
    },
    '06_suv': {
      'ru': 'Вода и поилки',
      'uz': 'Suv va suv berish',
      'en': 'Water & Drinkers',
    },
    '01_preparation': {
      'ru': 'Подготовка помещения до завоза',
      'uz': 'Xonani tayyorlash',
      'en': 'Barn Preparation Prior to Arrival',
    },
    '01_tayyorgarlik': {
      'ru': 'Подготовка помещения до завоза',
      'uz': 'Xonani tayyorlash',
      'en': 'Barn Preparation Prior to Arrival',
    },
    '02_first_days': {
      'ru': 'Приём цыплят и первые 3 дня',
      'uz': "Jo'jalarni qabul qilish va birinchi kunlar",
      'en': 'Chick Placement & First 3 Days',
    },
    '02_birinchi_kunlar': {
      'ru': 'Приём цыплят и первые 3 дня',
      'uz': "Jo'jalarni qabul qilish va birinchi kunlar",
      'en': 'Chick Placement & First 3 Days',
    },
    '08_diseases': {
      'ru': 'Признаки болезни — когда нужен ветеринар',
      'uz': 'Kasallik belgilari — qachon veterinar kerak',
      'en': 'Disease Signs & Veterinary Referral',
    },
    '08_kasalliklar': {
      'ru': 'Признаки болезни — когда нужен ветеринар',
      'uz': 'Kasallik belgilari — qachon veterinar kerak',
      'en': 'Disease Signs & Veterinary Referral',
    },
  };

  /// Returns the display title for a knowledge file, falling back to the raw
  /// file name if the topic has no title entry.
  static String titleFor(String topic, String language) {
    final lang = language.toLowerCase();
    final byTopic = _titles[topic];
    if (byTopic == null) return topic;
    return byTopic[lang] ?? byTopic['uz'] ?? topic;
  }

  Future<String?> _loadTopicForLanguage(String lang, String topic) async {
    final normalizedLang = lang.trim().toLowerCase();
    if (normalizedLang == 'uz' && _uzTopicMap.containsKey(topic)) {
      try {
        final uzContent = await _repo.getTopicContent(lang, _uzTopicMap[topic]!);
        if (uzContent.trim().isNotEmpty) return uzContent;
      } catch (_) {
        // Fall through to canonical topic name (e.g. in unit tests with _FakeBundle)
      }
    }
    try {
      final content = await _repo.getTopicContent(lang, topic);
      if (content.trim().isNotEmpty) return content;
    } catch (_) {}
    return null;
  }

  /// Scores articles for [question] and returns the top [max] matches.
  Future<List<_Match>> _retrieve(
    String question,
    String lang,
    int max,
  ) async {
    final normalizedQuestion = _norm(question);
    final tokens = RegExp(r"[a-zA-Zа-яА-ЯёЁ0-9']+")
        .allMatches(normalizedQuestion)
        .map((m) => (m.group(0) ?? '').replaceAll(RegExp(r"^'+|'+$"), ''))
        .where((t) => t.length > 2)
        .toList();

    if (tokens.isEmpty) return const [];

    final scored = <_Match>[];
    final loadedTopics = <String>{};

    for (final topic in _topics) {
      // Skip legacy summary duplicate if its full numbered article already loaded.
      final numberedCounterpart = _legacyToNumbered[topic];
      if (numberedCounterpart != null &&
          loadedTopics.contains(numberedCounterpart)) {
        continue;
      }

      final rawContent = await _loadTopicForLanguage(lang, topic);
      if (rawContent == null) continue;
      loadedTopics.add(topic);

      final content = _stripHtmlComments(rawContent);
      var score = 0;
      final haystack = _norm(content);
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
    dynamic context,
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

    final lang = language.toLowerCase();
    final intro = lang == 'en'
        ? 'From the verified AgroZen knowledge base:'
        : lang == 'ru'
            ? 'Из проверенной базы знаний AgroZen:'
            : "AgroZen tekshirilgan bilimlar bazasidan:";

    String contextualNote = '';
    if (context != null) {
      final matchedTopics = matches.map((m) => m.topic).toSet();
      if (matchedTopics.contains('temperature') ||
          matchedTopics.contains('03_temperature') ||
          matchedTopics.contains('ventilation') ||
          matchedTopics.contains('04_ventilation')) {
        final bDay = context.batchDay;
        final tTemp = context.targetTemperatureC.toStringAsFixed(0);
        final outsideTemp = context.outsideTemp as double?;
        String weatherSnippet = '';
        if (outsideTemp != null) {
          final diff = outsideTemp - context.targetTemperatureC;
          final diffStr = diff >= 0 ? '+${diff.toStringAsFixed(1)}°C' : '${diff.toStringAsFixed(1)}°C';
          if (lang == 'en') {
            weatherSnippet = ' (Outdoor weather: ${outsideTemp.toStringAsFixed(1)}°C, $diffStr vs target)';
          } else if (lang == 'ru') {
            weatherSnippet = ' (На улице: ${outsideTemp.toStringAsFixed(1)}°C, дельта $diffStr)';
          } else {
            weatherSnippet = ' (Tashqi harorat: ${outsideTemp.toStringAsFixed(1)}°C, farq $diffStr)';
          }
        }
        contextualNote = lang == 'en'
            ? "• Live Farm Target (Day $bDay): Target house temperature is $tTemp°C$weatherSnippet.\n\n"
            : (lang == 'ru'
                ? "• Показатель для вашей партии ($bDay-й день): Целевая температура птичника — $tTemp°C$weatherSnippet.\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): Xonadagi me'yoriy harorat aynan $tTemp°C bo'lishi kerak$weatherSnippet.\n\n");
      } else if (matchedTopics.contains('feed') || matchedTopics.contains('05_feeding')) {
        final bDay = context.batchDay;
        final cCount = context.currentCount;
        final recKg = context.recommendedFlockFeedKg.toStringAsFixed(1);
        final perBird = context.targetDailyFeedPerBirdG.toStringAsFixed(0);
        contextualNote = lang == 'en'
            ? "• Live Farm Target (Day $bDay): For $cCount birds, recommended feed today is ~$recKg kg ($perBird g/bird).\n\n"
            : (lang == 'ru'
                ? "• Расчёт для вашей партии ($bDay-й день): Для $cCount птиц норма корма на сегодня — ~$recKg кг ($perBird г/голову).\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): $cCount ta jo'jangizga bugungi yem tavsiyasi — ~$recKg kg ($perBird g/bosh).\n\n");
      }
    }

    return RagResult(
      answer: '$intro\n\n$contextualNote${snippets.join('\n\n---\n\n')}',
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
    'davol', 'леч', 'tablet', 'таблет', 'prick', 'колот',
    'сироп', 'suspens', 'порош', 'kukun', 'medicine', 'drug', 'dose',
    'treatment', 'cure',
  ];

  /// The farmer is asking for treatment. We must refuse and refer.
  bool wantsMedicine(String question) {
    final lower = _norm(question);
    return _medicalKeywords.any(lower.contains);
  }

  /// The mandatory non-prescriptive refusal, in the farmer's language.
  String medicineRefusal(String language) {
    final lang = language.toLowerCase();
    if (lang == 'en') {
      return 'AgroZen does not prescribe medication or antibiotics independently. '
          'Dosages and treatment protocols must only be determined by a veterinarian. '
          'Describe symptoms to a certified specialist: for any signs of illness, '
          'immediately contact your district veterinarian.';
    }
    if (lang == 'ru') {
      return 'AgroZen не назначает лекарства и антибиотики самостоятельно. '
          'Дозировки и схемы лечения определяет только ветеринар. '
          'Опишите симптомы специалисту — при любых признаках болезни '
          'немедленно обратитесь к ветеринару вашего района.';
    }
    return "AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi. "
        "Dozalarni va davolash tartibini faqat veterinar belgilaydi. "
        "Alomatlarni mutaxassisga ayting: kasallik belgilarida darhol "
        "tumaningiz veterinariga murojaat qiling.";
  }

  String _bestParagraph(String content, String question) {
    final normalizedQuestion = _norm(question);
    final tokens = RegExp(r"[a-zA-Zа-яА-ЯёЁ0-9']+")
        .allMatches(normalizedQuestion)
        .map((m) => (m.group(0) ?? '').replaceAll(RegExp(r"^'+|'+$"), ''))
        .where((t) => t.length > 2)
        .toSet();

    final sanitized = _stripHtmlComments(content);
    final paragraphs = sanitized.split(RegExp(r'\n\s*\n'));
    var best = '';
    var bestScore = 0;

    for (final para in paragraphs) {
      final clean = para.trim();
      if (clean.isEmpty ||
          clean.startsWith('#') ||
          RegExp(r'^[-*_]{3,}$').hasMatch(clean)) {
        continue;
      }
      var score = 0;
      final lower = _norm(clean);
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
        if (clean.isEmpty ||
            clean.startsWith('#') ||
            RegExp(r'^[-*_]{3,}$').hasMatch(clean)) {
          continue;
        }
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

