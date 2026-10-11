import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/domain/broiler/broiler_grower_library.dart';

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
    '09_lighting_density',
    '10_growth_fcr',
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
    '09_lighting_density': '09_yoruglik_zichlik',
    '10_growth_fcr': '10_osish_fcr',
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
    '09_lighting_density': [
      'yorug', 'chiroq', 'qorong', 'lyuks', 'zichlik', 'kvadrat', 'maydon',
      'свет', 'освещ', 'темнот', 'люкс', 'плотност', 'посадк', 'квадрат',
      'light', 'lighting', 'dark', 'darkness', 'lux', 'density', 'stocking',
      'space', 'crowded', 'feeder space',
    ],
    '10_growth_fcr': [
      'vazn', "o'sish", 'osish', 'semir', 'fcr', 'konvers', 'epef', 'tortish',
      'вес', 'привес', 'рост', 'конверс', 'взвеш', 'рентабел', 'откорм',
      'weight', 'growth', 'gain', 'fcr', 'conversion', 'efficiency', 'weighing',
      'harvest', 'withdrawal', 'grow faster',
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
    '09_lighting_density': {
      'ru': 'Освещение и плотность посадки',
      'uz': "Yorug'lik rejimi va zichlik",
      'en': 'Lighting & Stocking Density',
    },
    '09_yoruglik_zichlik': {
      'ru': 'Освещение и плотность посадки',
      'uz': "Yorug'lik rejimi va zichlik",
      'en': 'Lighting & Stocking Density',
    },
    '10_growth_fcr': {
      'ru': 'Привес, FCR и эффективность EPEF',
      'uz': "O'sish sur'ati, FCR va vazn nazorati",
      'en': 'Weight Gain, FCR & EPEF Efficiency',
    },
    '10_osish_fcr': {
      'ru': 'Привес, FCR и эффективность EPEF',
      'uz': "O'sish sur'ati, FCR va vazn nazorati",
      'en': 'Weight Gain, FCR & EPEF Efficiency',
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

  /// Stopwords across English, Russian, and Uzbek that must not trigger
  /// false-positive topic matches on their own.
  static const Set<String> _stopwords = {
    // English
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'any', 'can',
    'had', 'her', 'was', 'one', 'our', 'out', 'get', 'has', 'him', 'his',
    'how', 'man', 'new', 'now', 'see', 'two', 'way', 'who', 'boy', 'did',
    'its', 'let', 'put', 'say', 'she', 'too', 'use', 'what', 'when', 'where',
    'which', 'while', 'with', 'have', 'from', 'this', 'that', 'they', 'will',
    'would', 'there', 'their', 'about', 'could', 'should', 'tell', 'please',
    'bro', 'hey', 'hello', 'your', 'mine', 'some', 'into', 'than', 'then',
    'them', 'these', 'those', 'does', 'doing', 'done', 'give', 'gave', 'just',
    'like', 'make', 'made', 'many', 'more', 'most', 'much', 'must', 'need',
    'only', 'other', 'over', 'same', 'such', 'take', 'very', 'want', 'well',
    'were', 'work', 'year', 'good', 'morning', 'afternoon', 'evening',
    // Uzbek
    'uchun', 'bilan', 'ham', 'esa', 'shu', 'buni', 'unga', 'ular', 'men',
    'sen', 'siz', 'biz', 'nima', 'qanday', 'qachon', 'qayerda', 'necha',
    'nechta', 'kerak', "bo'lishi", 'bolishi', "bo'ladi", 'boladi', 'qilish',
    'berish', 'iltimos', 'haqida', 'menga', 'ning', 'dan', 'deb', 'yoki',
    'lekin', 'ammo', 'agar', 'hamma', 'barcha', 'har', 'bir', 'ikki',
    'salom', 'assalomu', 'alaykum', 'qalay', 'qalaysiz', 'yaxshimisiz',
    'ishlar', 'ahvollar', 'rahmat', 'tashakkur', 'aka', 'uka', 'broyler',
    'broylerlar',
    // Russian
    'что', 'как', 'для', 'при', 'или', 'это', 'все', 'еще', 'уже', 'мне',
    'мои', 'мой', 'моя', 'нам', 'нас', 'вам', 'вас', 'них', 'чем', 'где',
    'когда', 'какой', 'какая', 'какие', 'какова', 'нужно', 'надо', 'можно',
    'если', 'быть', 'есть', 'пожалуйста', 'делать', 'дела', 'жизнь', 'давать',
    'про', 'под', 'над', 'без', 'они', 'оно', 'она', 'мы', 'вы', 'ты', 'он',
    'так', 'тут', 'там', 'кто', 'чьи', 'сам', 'раз', 'два', 'три', 'привет',
    'здравствуйте', 'спасибо', 'бройлер', 'бройлеров', 'бройлерам',
  };

  static const Set<String> _greetingWords = {
    'hello', 'hi', 'hey', 'howdy', 'greetings', 'sup', 'yo',
    'salom', 'assalomu', 'assalom', 'alaykum', 'qalay', 'qalaysiz',
    'yaxshimisiz', 'hormang', 'charchamang', 'tinchmisiz',
    'привет', 'здравствуйте', 'здравствуй', 'добрый', 'доброе', 'салам',
    'ассалому', 'здарова',
  };

  static const List<String> _smallTalkPhrases = [
    'how are you', "how's it going", 'how is it going', 'what is up', "what's up",
    'who are you', 'what are you', 'what can you do', 'how can you help',
    'can you help', 'help me', 'thank you', 'thanks', 'good morning',
    'good afternoon', 'good evening', 'nice to meet',
    'ishlar qalay', 'ahvollar qalay', 'kimsiz', 'sen kimsan', 'siz kimsiz',
    'nima qila olasan', 'nima qila olasiz', 'qanday yordam', 'yordam bering',
    'rahmat', 'katta rahmat', 'tashakkur', 'xayrli tong', 'xayrli kun',
    'xayrli kech', 'assalomu alaykum', 'va alaykum assalom',
    'как дела', 'как жизнь', 'кто ты', 'кто вы', 'что ты умеешь',
    'что вы умеете', 'чем можешь помочь', 'помоги', 'помогите',
    'спасибо', 'благодарю', 'доброе утро', 'добрый день', 'добрый вечер',
  ];

  static const List<String> _flockStatusPhrases = [
    'how old are my', 'what day is my', 'how many birds', 'how many chicks',
    'my flock', 'flock status', 'batch status', 'how are my chicks',
    'how are my birds', 'who is my vet', 'my veterinarian', 'local vet',
    'weather outside', 'outdoor weather', 'outside temperature',
    "jo'jalarim necha", 'jojalarim necha', 'partiyam necha', 'nechanchi kun',
    "nechta jo'ja", 'nechta parranda', 'partiya holati', 'veterinarim kim',
    'veterinar raqami', 'tuman veterinari', 'ob-havo qanday', 'tashqi harorat',
    'сколько дней моим', 'какой день партии', 'какой сегодня день',
    'сколько у меня птиц', 'сколько у меня цыплят', 'сколько голов',
    'статус партии', 'как мои цыплята', 'кто мой ветеринар', 'номер ветеринара',
    'какая погода',
  ];

  /// Detects the language of [question], falling back to [fallback] ('uz', 'ru', 'en').
  static String detectLanguage(String question, {String fallback = 'uz'}) {
    final norm = _norm(question);
    // 1. Check for Cyrillic script -> Russian
    if (RegExp(r'[а-яё]').hasMatch(norm)) {
      return 'ru';
    }
    final words = RegExp(r"[a-z0-9']+")
        .allMatches(norm)
        .map((m) => (m.group(0) ?? '').replaceAll(RegExp(r"^'+|'+$"), ''))
        .where((w) => w.isNotEmpty)
        .toSet();

    const uzMarkers = {
      'salom', 'assalomu', 'alaykum', 'qalay', 'qalaysiz', 'yaxshimisiz',
      'rahmat', 'qanday', 'qachon', 'necha', 'nechta', 'nima', 'uchun',
      'bilan', 'kerak', "bo'lishi", "jo'ja", "jo'jalar", 'joja', 'harorat',
      'namlik', 'yem', 'suv', 'shamollatish', 'emlash', 'kasallik',
      "to'shama", 'xonani', 'tovuq', 'issiq', 'sovuq', 'kunlik', 'bosh',
      'tayyorgarlik', 'dezinfeksiya', 'vaksina', 'dori',
    };
    const enMarkers = {
      'hello', 'hi', 'hey', 'how', 'what', 'when', 'where', 'why', 'who',
      'which', 'can', 'should', 'would', 'could', 'please', 'thanks', 'thank',
      'chicks', 'chick', 'birds', 'bird', 'flock', 'broiler', 'broilers',
      'feed', 'feeding', 'water', 'drinker', 'temperature', 'humidity',
      'ventilation', 'disease', 'vaccine', 'vaccination', 'bedding', 'litter',
      'house', 'barn', 'day', 'days', 'week', 'weeks', 'old', 'my', 'the',
      'are', 'is', 'do', 'does', 'help', 'morning', 'afternoon', 'evening',
    };

    var uzScore = 0;
    var enScore = 0;
    for (final w in words) {
      if (uzMarkers.contains(w) || w.contains("o'") || w.contains("g'")) {
        uzScore += 2;
      }
      if (enMarkers.contains(w)) {
        enScore += 2;
      }
    }

    if (enScore > uzScore && enScore >= 2) return 'en';
    if (uzScore > enScore && uzScore >= 2) return 'uz';
    final fb = fallback.trim().toLowerCase();
    if (fb == 'en' || fb == 'ru' || fb == 'uz') return fb;
    return 'uz';
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

  static bool _containsWordPrefix(String haystack, String token) {
    final escaped = RegExp.escape(token);
    return RegExp("(?:^|[^a-zA-Zа-яА-ЯёЁ0-9'])$escaped").hasMatch(haystack);
  }

  /// Scores articles for [question] and returns the top [max] matches.
  Future<List<_Match>> _retrieve(
    String question,
    String lang,
    int max,
  ) async {
    final normalizedQuestion = _norm(question);
    final allTokens = RegExp(r"[a-zA-Zа-яА-ЯёЁ0-9']+")
        .allMatches(normalizedQuestion)
        .map((m) => (m.group(0) ?? '').replaceAll(RegExp(r"^'+|'+$"), ''))
        .where((t) => t.length > 2)
        .toList();

    final tokens = allTokens.where((t) => !_stopwords.contains(t)).toList();
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
      var aliasHits = 0;
      var contentHits = 0;
      final haystack = _norm(content);
      final aliases = _aliases[topic] ?? const <String>[];

      // Check multi-word aliases against normalizedQuestion
      for (final a in aliases) {
        if (a.contains(' ') && normalizedQuestion.contains(a)) {
          score += 6;
          aliasHits++;
        }
      }

      for (final token in tokens) {
        final matchedAlias = aliases.any((a) {
          if (a.contains(' ')) return false;
          if (token == a) return true;
          if (a.length >= 3 && token.startsWith(a)) return true;
          if (token.length >= 4 && a.startsWith(token)) return true;
          return false;
        });

        if (matchedAlias) {
          score += 5;
          aliasHits++;
        }
        if (_containsWordPrefix(haystack, token)) {
          score += 2;
          contentHits++;
        }
      }

      // Require at least one domain alias hit, or multiple meaningful content hits,
      // or a specific domain word (>= 4 chars) appearing in content.
      final hasMeaningfulMatch = aliasHits > 0 ||
          contentHits >= 2 ||
          (contentHits == 1 && tokens.any((t) => t.length >= 4 && _containsWordPrefix(haystack, t)));

      if (score > 0 && hasMeaningfulMatch) {
        scored.add(_Match(topic: topic, score: score, content: content));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.length > max) scored.removeRange(max, scored.length);
    return scored;
  }

  bool _isConversationalQuery(String question) {
    final norm = _norm(question).trim();
    if (norm.isEmpty) return false;
    for (final phrase in _smallTalkPhrases) {
      if (norm.contains(phrase)) return true;
    }
    final words = RegExp(r"[a-zA-Zа-яА-ЯёЁ0-9']+")
        .allMatches(norm)
        .map((m) => (m.group(0) ?? '').replaceAll(RegExp(r"^'+|'+$"), ''))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return false;
    if (words.length <= 5 && words.any(_greetingWords.contains)) {
      return true;
    }
    return false;
  }

  bool _isFlockStatusQuery(String question) {
    final norm = _norm(question).trim();
    if (norm.isEmpty) return false;
    return _flockStatusPhrases.any(norm.contains);
  }

  RagResult _buildConversationalResponse({
    required String question,
    required String lang,
    dynamic context,
  }) {
    final norm = _norm(question);
    final isThanks = norm.contains('thank') ||
        norm.contains('rahmat') ||
        norm.contains('tashakkur') ||
        norm.contains('спасибо') ||
        norm.contains('благодар');

    final farmerName = context?.farmerName?.toString() ?? '';
    final hasName = farmerName.isNotEmpty &&
        farmerName.toLowerCase() != 'fermer' &&
        farmerName.toLowerCase() != 'farmer';
    final nameGreeting = hasName ? ', $farmerName' : '';

    if (isThanks) {
      final reply = lang == 'en'
          ? "You're very welcome$nameGreeting! I'm always here to help your flock stay healthy and reach optimal weight. Ask me anytime about temperature, feeding, water, or ventilation!"
          : (lang == 'ru'
              ? 'Всегда пожалуйста$nameGreeting! Рад помочь вам вырастить здоровое и крепкое поголовье. Обращайтесь в любое время по вопросам температуры, кормления, воды или вентиляции!'
              : "Arzimaydi$nameGreeting! Jo'jalaringiz sog'lom va barakali bo'lishida yordam berishdan doim xursandman. Harorat, yem, suv yoki shamollatish bo'yicha istalgan paytda savol berishingiz mumkin!");
      return RagResult(
        answer: reply,
        sources: [
          lang == 'en'
              ? 'AgroZen AI Assistant'
              : (lang == 'ru' ? 'ИИ Помощник AgroZen' : 'AgroZen AI Maslahatchi')
        ],
      );
    }

    if (context != null) {
      final bDay = context.batchDay;
      final cCount = context.currentCount;
      final tTemp = context.targetTemperatureC.toStringAsFixed(0);
      final recKg = context.recommendedFlockFeedKg.toStringAsFixed(1);
      final perBird = context.targetDailyFeedPerBirdG.toStringAsFixed(0);
      final phase = context.growthPhase;

      final reply = lang == 'en'
          ? "Hello$nameGreeting! I am your AgroZen poultry mentor, ready to help.\n\n"
              "Here is your live flock snapshot:\n"
              "• Flock Stage: Day $bDay of 42 ($phase) — $cCount birds\n"
              "• Target Barn Temperature: $tTemp°C at chick level\n"
              "• Today's Feed Norm: ~$recKg kg ($perBird g per bird)\n\n"
              "Ask me any question about temperature, feeding phases, water, ventilation, vaccination, or share a flock photo for inspection!"
          : (lang == 'ru'
              ? "Здравствуйте$nameGreeting! Я ваш цифровой наставник AgroZen по бройлерному птицеводству.\n\n"
                  "Сводка по вашей партии на сегодня:\n"
                  "• Возраст стада: $bDay-й день из 42 ($phase) — $cCount голов\n"
                  "• Целевая температура в птичнике: $tTemp°C на уровне птиц\n"
                  "• Суточная норма корма: ~$recKg кг ($perBird г на голову)\n\n"
                  "Задавайте любой вопрос по микроклимату, кормам, воде, вентиляции, вакцинации или отправьте фото птичника!"
              : "Assalomu alaykum$nameGreeting! Men sizning AgroZen parrandachilik bo'yicha shaxsiy AI yordamchingizman.\n\n"
                  "Partiyangizning bugungi ko'rsatkichlari:\n"
                  "• Jo'jalar yoshi: $bDay-kun ($phase) — $cCount bosh\n"
                  "• Xonadagi me'yoriy harorat: $tTemp°C (jo'ja bo'yi sathida)\n"
                  "• Bugungi yem me'yori: ~$recKg kg (har bir boshga $perBird g)\n\n"
                  "Menga harorat, yemlash, suv, shamollatish, emlash bo'yicha savol bering yoki tovuqxona suratini yuboring!");

      return RagResult(
        answer: reply,
        sources: [
          lang == 'en'
              ? 'AgroZen Live Flock Dossier'
              : (lang == 'ru' ? 'Досье партии AgroZen' : 'AgroZen Partiya Dosyesi')
        ],
      );
    }

    final defaultReply = lang == 'en'
        ? "Hello! I am your AgroZen AI poultry advisor. I can help you with:\n\n"
            "• Barn temperature and humidity norms (Days 1–42)\n"
            "• Starter, Grower, and Finisher feeding schedules\n"
            "• Drinking water quality and nipple drinker setup\n"
            "• Ventilation, cooling, and ammonia control\n"
            "• Vaccination schedules and disease warning signs\n\n"
            "What would you like to know about your broilers today?"
        : (lang == 'ru'
            ? "Здравствуйте! Я ваш ИИ-консультант AgroZen по выращиванию бройлеров. Я могу подсказать:\n\n"
                "• Нормы температуры и влажности по дням (1–42 дни)\n"
                "• Рационы кормления: Старт, Рост и Финиш\n"
                "• Настройку поения и температуру воды\n"
                "• Правила вентиляции и защиты от жары\n"
                "• График вакцинации и признаки болезней\n\n"
                "Какой вопрос по птичнику вас интересует?"
            : "Assalomu alaykum! Men AgroZen parrandachilik bo'yicha AI maslahatchingizman. Sizga quyidagi mavzularda yordam bera olaman:\n\n"
                "• Kunlik harorat va namlik me'yorlari (1–42 kun)\n"
                "• Start, O'sish va Finish yemlash bosqichlari\n"
                "• Suv harorati va nippel sug'orgichlarni sozlash\n"
                "• Shamollatish va ammiakdan himoya qilish\n"
                "• Emlash jadvali va kasallik alomatlari\n\n"
                "Bugun jo'jalaringiz bo'yicha qanday savolingiz bor?");

    return RagResult(
      answer: defaultReply,
      sources: [
        lang == 'en'
            ? 'AgroZen AI Assistant'
            : (lang == 'ru' ? 'ИИ Помощник AgroZen' : 'AgroZen AI Maslahatchi')
      ],
    );
  }

  RagResult _buildFlockStatusResponse({
    required String lang,
    dynamic context,
  }) {
    final bDay = context?.batchDay ?? 1;
    final cCount = context?.currentCount ?? 500;
    final iCount = context?.initialCount ?? 500;
    final tTemp = (context?.targetTemperatureC ?? 33.0).toStringAsFixed(0);
    final recKg = (context?.recommendedFlockFeedKg ?? 12.0).toStringAsFixed(1);
    final perBird = (context?.targetDailyFeedPerBirdG ?? 24.0).toStringAsFixed(0);
    final tWeight = (context?.targetWeightG ?? 185.0).toStringAsFixed(0);
    final phase = context?.growthPhase ??
        (lang == 'en' ? 'Starter' : (lang == 'ru' ? 'Старт' : 'Start'));
    final district = context?.district ?? 'Toshkent';
    final vetName = context?.localVet?['name']?.toString() ??
        (lang == 'en'
            ? 'District Veterinary Service'
            : (lang == 'ru' ? 'Районная ветслужба' : "Tuman veterinariya bo'limi"));
    final vetPhone = context?.localVet?['phone']?.toString() ?? '';
    final vetInfo = vetPhone.isNotEmpty ? '$vetName ($vetPhone)' : vetName;
    final outsideTemp = context?.outsideTemp as double?;

    final weatherLine = outsideTemp != null
        ? (lang == 'en'
            ? '\n• Outdoor Weather ($district): ${outsideTemp.toStringAsFixed(1)}°C'
            : (lang == 'ru'
                ? '\n• Погода на улице ($district): ${outsideTemp.toStringAsFixed(1)}°C'
                : '\n• Tashqi ob-havo ($district): ${outsideTemp.toStringAsFixed(1)}°C'))
        : '';

    final text = lang == 'en'
        ? "Live Flock Status ($district):\n\n"
            "• Flock Age: Day $bDay of 42 ($phase phase)\n"
            "• Active Birds: $cCount alive (out of $iCount initial)\n"
            "• Target House Temperature: $tTemp°C at bedding height\n"
            "• Daily Feed Requirement: ~$recKg kg total ($perBird g/bird)\n"
            "• Benchmark Weight Target: ~$tWeight g$weatherLine\n"
            "• Assigned District Vet: $vetInfo"
        : (lang == 'ru'
            ? "Текущий статус вашей партии ($district):\n\n"
                "• День цикла: $bDay-й день из 42 (Фаза: $phase)\n"
                "• Поголовье: $cCount живых птиц (из $iCount начальных)\n"
                "• Норма температуры в птичнике: $tTemp°C на уровне подстилки\n"
                "• Суточная норма корма: ~$recKg кг ($perBird г/голову)\n"
                "• Эталонный вес: ~$tWeight г$weatherLine\n"
                "• Дежурный ветеринар района: $vetInfo"
            : "Joriy partiyangiz holati ($district):\n\n"
                "• Partiya kuni: $bDay-kun / 42 kundan (Bosqich: $phase)\n"
                "• Parrandalar soni: $cCount ta tirik (boshlang'ich $iCount tadan)\n"
                "• Xonadagi harorat me'yori: $tTemp°C (to'shama sathida)\n"
                "• Bugungi yem normasi: jami ~$recKg kg (boshiga $perBird g)\n"
                "• Me'yoriy vazn mo'ljali: ~$tWeight g$weatherLine\n"
                "• Biriktirilgan tuman veterinari: $vetInfo");

    return RagResult(
      answer: text,
      sources: [
        lang == 'en'
            ? 'AgroZen Live Flock Dossier'
            : (lang == 'ru' ? 'Досье партии AgroZen' : 'AgroZen Partiya Dosyesi')
      ],
    );
  }

  /// Retrieves raw topic contents and human-readable titles for cloud AI RAG context.
  Future<({List<String> contents, List<String> titles})> getRelevantTopicContext({
    required String question,
    required String language,
  }) async {
    final effectiveLang = detectLanguage(question, fallback: language);
    var matches = await _retrieve(question, effectiveLang, 2);
    var usedLang = effectiveLang;
    if (matches.isEmpty && effectiveLang != language.toLowerCase()) {
      matches = await _retrieve(question, language, 2);
      if (matches.isNotEmpty) {
        usedLang = language.toLowerCase();
      }
    }
    final contents = matches.map((m) => m.content).toList();
    final titles = matches
        .map((m) => titleFor(m.topic, usedLang))
        .toSet()
        .toList();
    return (contents: contents, titles: titles);
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
    final effectiveLang = detectLanguage(question, fallback: language);

    // 1. Try domain knowledge retrieval in effective language first, then fallback language
    var matches = await _retrieve(question, effectiveLang, 2);
    var usedLang = effectiveLang;
    if (matches.isEmpty && effectiveLang != language.toLowerCase()) {
      matches = await _retrieve(question, language, 2);
      if (matches.isNotEmpty) {
        usedLang = language.toLowerCase();
      }
    }

    // 2. If no specific poultry manual matched, check if the farmer is asking
    // about their live flock status or sending a greeting / conversational turn.
    if (matches.isEmpty) {
      if (_isFlockStatusQuery(question)) {
        return _buildFlockStatusResponse(lang: effectiveLang, context: context);
      }
      if (_isConversationalQuery(question)) {
        return _buildConversationalResponse(
          question: question,
          lang: effectiveLang,
          context: context,
        );
      }
      return null;
    }

    final sources = matches
        .map((m) => titleFor(m.topic, usedLang))
        .toSet()
        .toList();

    // Surface the most relevant excerpt rather than inventing text.
    final snippets = <String>[];
    for (final match in matches) {
      final excerpt = _bestParagraph(match.content, question);
      if (excerpt.isNotEmpty) snippets.add(excerpt);
    }
    if (snippets.isEmpty) return null;

    final lang = usedLang.toLowerCase();
    final intro = lang == 'en'
        ? 'From the verified AgroZen knowledge base:'
        : lang == 'ru'
            ? 'Из проверенной базы знаний AgroZen:'
            : "AgroZen tekshirilgan bilimlar bazasidan:";

    String contextualNote = '';
    if (context != null) {
      final matchedTopics = matches.map((m) => m.topic).toSet();
      final int bDay = (context.batchDay as int?) ?? 1;
      final int cCount = (context.currentCount as int?) ?? 500;
      final double? outsideTemp = context.outsideTemp as double?;
      final req = BroilerGrowerLibrary.calculateFlockRequirements(
        day: bDay,
        birdCount: cCount,
        outsideTempC: outsideTemp,
      );
      final spec = req.spec;

      if (matchedTopics.contains('temperature') ||
          matchedTopics.contains('03_temperature') ||
          matchedTopics.contains('ventilation') ||
          matchedTopics.contains('04_ventilation')) {
        final tTemp = context.targetTemperatureC.toStringAsFixed(0);
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
            ? "• Live Farm Target (Day $bDay): Target house temperature is $tTemp°C, RH ${spec.humidityMinPct}–${spec.humidityMaxPct}%$weatherSnippet.\n\n"
            : (lang == 'ru'
                ? "• Показатель для вашей партии ($bDay-й день): Целевая температура птичника — $tTemp°C, влажность ${spec.humidityMinPct}–${spec.humidityMaxPct}%$weatherSnippet.\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): Xonadagi me'yoriy harorat aynan $tTemp°C, namlik ${spec.humidityMinPct}–${spec.humidityMaxPct}% bo'lishi kerak$weatherSnippet.\n\n");
      } else if (matchedTopics.contains('feed') || matchedTopics.contains('05_feeding')) {
        final recKg = context.recommendedFlockFeedKg.toStringAsFixed(1);
        final perBird = context.targetDailyFeedPerBirdG.toStringAsFixed(0);
        contextualNote = lang == 'en'
            ? "• Live Farm Target (Day $bDay): For $cCount birds, recommended feed today is ~$recKg kg ($perBird g/bird, ${spec.feedFormDescription('en')}).\n\n"
            : (lang == 'ru'
                ? "• Расчёт для вашей партии ($bDay-й день): Для $cCount птиц норма корма на сегодня — ~$recKg кг ($perBird г/голову, ${spec.feedFormDescription('ru')}).\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): $cCount ta jo'jangizga bugungi yem tavsiyasi — ~$recKg kg ($perBird g/bosh, ${spec.feedFormDescription('uz')}).\n\n");
      } else if (matchedTopics.contains('06_water')) {
        final waterL = req.totalDailyWaterLiters.toStringAsFixed(1);
        final nipples = req.recommendedNipples;
        contextualNote = lang == 'en'
            ? "• Live Farm Target (Day $bDay): For $cCount birds, daily drinking water target is ~$waterL L across at least $nipples nipple drinkers.\n\n"
            : (lang == 'ru'
                ? "• Расчёт для вашей партии ($bDay-й день): Для $cCount птиц суточная норма воды — ~$waterL л (минимум $nipples ниппельных поилок).\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): $cCount ta parrandaga bugungi suv me'yori — ~$waterL litr (kamida $nipples ta nippel sug'orgich).\n\n");
      } else if (matchedTopics.contains('09_lighting_density')) {
        final areaNow = req.requiredBarnAreaCurrentSqM.toStringAsFixed(1);
        contextualNote = lang == 'en'
            ? "• Live Farm Target (Day $bDay): Lighting schedule is ${spec.lightHours}h light / ${spec.darkHours}h dark (${spec.lightIntensityLux} lux); max density is ${spec.maxBirdsPerSqMeter} birds/m² (~$areaNow m² for $cCount birds).\n\n"
            : (lang == 'ru'
                ? "• Расчёт для вашей партии ($bDay-й день): Освещение ${spec.lightHours} ч света / ${spec.darkHours} ч темноты (${spec.lightIntensityLux} люкс); плотность до ${spec.maxBirdsPerSqMeter} гол./м² (~$areaNow м² на $cCount голов).\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): Yorug'lik ${spec.lightHours} soat yorug' / ${spec.darkHours} soat qorong'u (${spec.lightIntensityLux} lyuks); zichlik 1 m² ga max ${spec.maxBirdsPerSqMeter} bosh ($cCount bosh uchun ~$areaNow m²).\n\n");
      } else if (matchedTopics.contains('10_growth_fcr')) {
        final wTarget = spec.targetWeightG.toStringAsFixed(0);
        final gain = spec.dailyGainG.toStringAsFixed(0);
        final fcr = spec.targetFcr.toStringAsFixed(2);
        contextualNote = lang == 'en'
            ? "• Live Farm Target (Day $bDay): Benchmark weight is $wTarget g (+$gain g/day gain) with target FCR $fcr.\n\n"
            : (lang == 'ru'
                ? "• Расчёт для вашей партии ($bDay-й день): Эталонный вес — $wTarget г (суточный привес +$gain г) при целевом FCR $fcr.\n\n"
                : "• Sizning partiyangiz uchun ($bDay-kun): Etalon vazn — $wTarget g (kunlik o'sish +$gain g), maqsadli FCR ko'rsatkichi $fcr.\n\n");
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

  /// Standard emergency isolation and veterinary referral message.
  String emergencyMessage(String language, {dynamic context}) {
    final norm = language.trim().toLowerCase();
    final vetName = context?.localVet?['name']?.toString() ?? '';
    final vetPhone = context?.localVet?['phone']?.toString() ?? '';
    final vetSuffix = vetName.isNotEmpty
        ? (vetPhone.isNotEmpty ? ' ($vetName: $vetPhone)' : ' ($vetName)')
        : '';

    if (norm.startsWith('en')) {
      return 'This appears to be an urgent situation. Do not wait or self-treat the flock:\n\n'
          '1. Isolate symptomatic birds from healthy ones.\n'
          '2. Suspend poultry transfer and sales immediately.\n'
          '3. Call your district veterinarian immediately$vetSuffix — contact info is on the Diary screen.\n\n'
          'AgroZen does not provide diagnoses or prescribe medication.';
    }
    if (norm.startsWith('ru')) {
      return 'Похоже на экстренную ситуацию. Не ждите и не лечите птицу самостоятельно:\n\n'
          '1. Изолируйте заболевших птиц от здоровых.\n'
          '2. Прекратите вывоз и продажу птицы.\n'
          '3. Немедленно позвоните ветеринару вашего района$vetSuffix — контакты на экране Дневника.\n\n'
          'AgroZen не ставит диагнозы и не назначает лекарства.';
    }
    return "Shoshilinch holatga o'xshaydi. Kutmang va parrandani o'zingiz davolamang:\n\n"
        "1. Kasal parrandani sog'lomlaridan ajrating.\n"
        "2. Parrandani tashqariga chiqarishni to'xtating.\n"
        "3. Darhol tumaningiz veterinariga qo'ng'iroq qiling$vetSuffix — kontaktlar Kundalik ekranida.\n\n"
        "AgroZen tashxis qo'ymaydi va dori buyurmadi.";
  }

  String _bestParagraph(String content, String question) {
    final normalizedQuestion = _norm(question);
    final tokens = RegExp(r"[a-zA-Zа-яА-ЯёЁ0-9']+")
        .allMatches(normalizedQuestion)
        .map((m) => (m.group(0) ?? '').replaceAll(RegExp(r"^'+|'+$"), ''))
        .where((t) => t.length > 2 && !_stopwords.contains(t))
        .toSet();

    final sanitized = _stripHtmlComments(content);
    final rawParagraphs = sanitized.split(RegExp(r'\n\s*\n'));
    final paragraphs = <String>[];
    for (final p in rawParagraphs) {
      final clean = p.trim();
      if (clean.isEmpty ||
          clean.startsWith('#') ||
          RegExp(r'^[-*_]{3,}$').hasMatch(clean)) {
        continue;
      }
      paragraphs.add(clean);
    }

    var bestIndex = -1;
    var bestScore = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      final clean = paragraphs[i];
      var score = 0;
      final lower = _norm(clean);
      for (final t in tokens) {
        if (lower.contains(t)) score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    if (bestIndex == -1 && paragraphs.isNotEmpty) {
      bestIndex = 0;
    }

    if (bestIndex == -1) return '';

    var best = paragraphs[bestIndex];
    // If the selected paragraph is a short lead-in ending with ':' and there is
    // a follow-up paragraph with details/bullets, include the follow-up too.
    if ((best.endsWith(':') || best.length < 140) &&
        bestIndex + 1 < paragraphs.length) {
      final nextPara = paragraphs[bestIndex + 1];
      if (best.length + nextPara.length + 2 <= 700) {
        best = '$best\n\n$nextPara';
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


