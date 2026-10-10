import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/alerts/alert_models.dart';
import '../models/daily_plan.dart';

class VideoGuide {
  final int day;
  final String titleRu;
  final String titleUz;
  final String titleEn;
  final String url;
  final String? duration;

  const VideoGuide({
    required this.day,
    required this.titleRu,
    required this.titleUz,
    this.titleEn = '',
    required this.url,
    this.duration,
  });

  factory VideoGuide.fromJson(Map<String, dynamic> json) {
    return VideoGuide(
      day: (json['day'] as num?)?.toInt() ?? 1,
      titleRu: json['title_ru'] as String? ?? '',
      titleUz: json['title_uz'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      url: json['url'] as String? ?? '',
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'title_ru': titleRu,
        'title_uz': titleUz,
        if (titleEn.isNotEmpty) 'title_en': titleEn,
        'url': url,
        if (duration != null) 'duration': duration,
      };

  String getTitle(String language) {
    final code = language.trim().toLowerCase();
    if (code.startsWith('en')) {
      return titleEn.isNotEmpty
          ? titleEn
          : (titleUz.isNotEmpty ? titleUz : titleRu);
    }
    if (code.startsWith('ru')) {
      return titleRu.isNotEmpty ? titleRu : titleUz;
    }
    return titleUz.isNotEmpty ? titleUz : titleRu;
  }
}

class KnowledgeRepository {
  final AssetBundle _bundle;
  final bool _useStaticCache;

  KnowledgeRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle,
        _useStaticCache = bundle == null || identical(bundle, rootBundle);

  static List<DailyPlan>? _dailyPlansCache;
  static Map<String, dynamic>? _normsCache;
  static NormsData? _parsedNormsCache;
  static List<Map<String, dynamic>>? _vetsCache;
  static List<Map<String, dynamic>>? _videosCache;

  List<DailyPlan>? _instanceDailyPlansCache;
  Map<String, dynamic>? _instanceNormsCache;
  NormsData? _instanceParsedNormsCache;
  List<Map<String, dynamic>>? _instanceVetsCache;
  List<Map<String, dynamic>>? _instanceVideosCache;

  static const Duration _loadTimeout = Duration(milliseconds: 2000);

  /// Clears static caches (useful in test tearDown/setUp).
  static void clearCache() {
    _dailyPlansCache = null;
    _normsCache = null;
    _parsedNormsCache = null;
    _vetsCache = null;
    _videosCache = null;
  }

  static const List<String> _defaultTopicFiles = [
    'temperature.md',
    'feed.md',
    'vaccination.md',
    'ventilation.md',
  ];

  /// Loads and parses `knowledge/norms.json` into [NormsData].
  ///
  /// This is the SINGLE source of truth for alert thresholds, weight targets and
  /// temperature targets. Screens must use this instead of hardcoding norms,
  /// otherwise the deterministic alert engine drifts away from the
  /// vet-verified data.
  Future<NormsData> getParsedNorms() async {
    final cached = _useStaticCache ? _parsedNormsCache : _instanceParsedNormsCache;
    if (cached != null) return cached;

    final raw = await getNorms();
    final parsed = NormsData.fromJson(raw);
    if (_useStaticCache) {
      _parsedNormsCache = parsed;
    } else {
      _instanceParsedNormsCache = parsed;
    }
    return parsed;
  }

  /// Get daily plan for a specific cycle day (1 to 42)
  Future<DailyPlan?> getDailyPlan(int day) async {
    try {
      final plans = await getAllDailyPlans();
      for (final plan in plans) {
        if (plan.day == day) {
          return plan;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load daily plan for day $day: $e');
    }
  }

  /// Get all 42 days of broiler plan
  Future<List<DailyPlan>> getAllDailyPlans() async {
    final cached = _useStaticCache ? _dailyPlansCache : _instanceDailyPlansCache;
    if (cached != null) {
      return cached;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/broiler_plan.json')
          .timeout(_loadTimeout);
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['days'] is List
              ? (decoded['days'] as List)
              : []);
      final plans = list
          .map((item) => DailyPlan.fromJson(item as Map<String, dynamic>))
          .toList();
      if (_useStaticCache) {
        _dailyPlansCache = plans;
      } else {
        _instanceDailyPlansCache = plans;
      }
      return plans;
    } catch (_) {
      final fallback = List.generate(
        42,
        (i) => DailyPlan(
          day: i + 1,
          tasksRu:
              'День ${i + 1}: Поддержание температуры, контроль воды и комбикорма.',
          tasksUz:
              '${i + 1}-kun: Haroratni nazorat qilish, toza suv va aralash yem berish.',
          tasksEn:
              'Day ${i + 1}: Maintain target house temperature, inspect clean water lines and balanced feed.',
          videoUrl:
              'https://www.youtube.com/results?search_query=ross+308+broiler+day+${i + 1}+management',
        ),
      );
      if (!_useStaticCache) {
        _instanceDailyPlansCache = fallback;
      }
      return fallback;
    }
  }

  /// Get normative data for broilers (Ross-308 / Cobb-500)
  Future<Map<String, dynamic>> getNorms() async {
    final cached = _useStaticCache ? _normsCache : _instanceNormsCache;
    if (cached != null) {
      return cached;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/norms.json')
          .timeout(_loadTimeout);
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        if (_useStaticCache) {
          _normsCache = parsed;
        } else {
          _instanceNormsCache = parsed;
        }
        return parsed;
      }
      return _defaultNorms;
    } catch (_) {
      if (!_useStaticCache) {
        _instanceNormsCache = _defaultNorms;
      }
      return _defaultNorms;
    }
  }

  static const Map<String, dynamic> _defaultNorms = {
    'breed': 'Ross-308 / Cobb-500',
    'critical_thresholds': {
      'daily_mortality_alert_percent': 1.0,
      'cumulative_mortality_warning_percent': 4.0,
      'weight_deficit_alert_percent': 15.0,
      'feed_drop_alert_percent': 20.0,
    },
    'alert_thresholds': {
      'daily_mortality_percent': 1.0,
      'weekly_weight_deviation_percent': 15.0,
    },
    'weekly_norms': [
      {'week': 1, 'target_weight_g': 185, 'daily_feed_g': 24, 'temperature_c': 30.0},
      {'week': 2, 'target_weight_g': 465, 'daily_feed_g': 54, 'temperature_c': 27.0},
      {'week': 3, 'target_weight_g': 975, 'daily_feed_g': 95, 'temperature_c': 24.0},
      {'week': 4, 'target_weight_g': 1600, 'daily_feed_g': 140, 'temperature_c': 21.0},
      {'week': 5, 'target_weight_g': 2280, 'daily_feed_g': 175, 'temperature_c': 19.0},
      {'week': 6, 'target_weight_g': 2900, 'daily_feed_g': 195, 'temperature_c': 18.0},
    ],
    'daily_norms': {
      '1': {'weight_g': 42, 'feed_g': 12, 'temp_c': 32.5},
      '3': {'weight_g': 70, 'feed_g': 18, 'temp_c': 31.5},
      '7': {'weight_g': 185, 'feed_g': 38, 'temp_c': 29.5},
      '14': {'weight_g': 510, 'feed_g': 77, 'temp_c': 26.0},
      '21': {'weight_g': 1055, 'feed_g': 119, 'temp_c': 22.5},
      '28': {'weight_g': 1745, 'feed_g': 155, 'temp_c': 20.5},
      '35': {'weight_g': 2480, 'feed_g': 184, 'temp_c': 18.8},
      '42': {'weight_g': 3180, 'feed_g': 208, 'temp_c': 18.0},
    },
    'weekly_weight_targets': {
      '7': 185,
      '14': 510,
      '21': 1055,
      '28': 1745,
      '35': 2480,
      '42': 3180,
    },
    'daily_feed_per_bird': {
      '1': 12,
      '7': 38,
      '14': 77,
      '21': 119,
      '28': 155,
      '35': 184,
      '42': 208,
    },
    'temperature_targets': {
      '1': 32.5,
      '3': 31.5,
      '7': 29.5,
      '14': 26.0,
      '21': 22.5,
      '28': 20.5,
      '35': 18.8,
      '42': 18.0,
    },
  };

  /// Offline fallback used only when `knowledge/vets.json` cannot be read.
  /// MUST stay in sync with `knowledge/vets.json` — a wrong phone number here
  /// would send a farmer in an emergency to the wrong clinic.
  static const List<Map<String, dynamic>> _defaultVets = [
    {'district': 'Toshkent', 'name': 'Dr. Rustam Karimov', 'phone': '+998901234501'},
    {'district': 'Samarqand', 'name': 'Dr. Jamshid Ergashev', 'phone': '+998933334502'},
    {'district': 'Buxoro', 'name': 'Dr. Alisher Narzullayev', 'phone': '+998914004503'},
    {'district': 'Andijon', 'name': 'Dr. Nodirbek Usmonov', 'phone': '+998902004504'},
    {'district': "Farg'ona", 'name': 'Dr. Mansur Qodirov', 'phone': '+998911504505'},
    {'district': 'Namangan', 'name': 'Dr. Salohiddin Mirzayev', 'phone': '+998932114506'},
    {'district': 'Qashqadaryo', 'name': 'Dr. Baxtiyor Normurodov', 'phone': '+998973104507'},
    {'district': 'Surxondaryo', 'name': 'Dr. Ilhom Xoliqov', 'phone': '+998994404508'},
    {'district': 'Jizzax', 'name': 'Dr. Otabek Sobirov', 'phone': '+998905504509'},
    {'district': 'Sirdaryo', 'name': 'Dr. Farrux Yusupov', 'phone': '+998916604510'},
    {'district': 'Xorazm', 'name': 'Dr. Sherzod Matyoqubov', 'phone': '+998937704511'},
    {'district': 'Navoiy', 'name': "Dr. G'ayrat Hamroyev", 'phone': '+998792204512'},
    {'district': "Qoraqalpog'iston", 'name': 'Dr. Azamat Seytov', 'phone': '+998612204513'},
  ];

  static const List<Map<String, dynamic>> _defaultVideos = [
    {
      'day': 1,
      'title_ru': 'Подготовка птичника и прием суточных цыплят',
      'title_uz': "Binoni tayyorlash va bir kunlik jo'jalarni qabul qilish",
      'title_en': 'Barn Preparation and Day-Old Chick Placement',
      'url': 'https://www.youtube.com/results?search_query=ross+308+broiler+day+1+brooder+setup',
      'duration': '8:25',
    },
    {
      'day': 7,
      'title_ru': 'Первая неделя: вакцинация и контроль веса',
      'title_uz': '1-hafta: emlash va vazn nazorati',
      'title_en': 'Week 1: Vaccination and Weight Control',
      'url': 'https://www.youtube.com/results?search_query=ross+308+broiler+week+1+management+weighing',
      'duration': '6:40',
    },
    {
      'day': 14,
      'title_ru': 'Переход на ростовой корм и регулировка вентиляции',
      'title_uz': "O'sish yemiga o'tish va ventilyatsiyani sozlash",
      'title_en': 'Transition to Grower Feed and Ventilation Setup',
      'url': 'https://www.youtube.com/results?search_query=broiler+grower+feed+transition+ventilation',
      'duration': '7:15',
    },
    {
      'day': 21,
      'title_ru': 'Профилактика респираторных болезней и кокцидиоза',
      'title_uz': "Nafas yo'llari kasalliklari va koksidioz profilaktikasi",
      'title_en': 'Prevention of Respiratory Disease and Coccidiosis',
      'url': 'https://www.youtube.com/results?search_query=broiler+coccidiosis+litter+management+prevention',
      'duration': '9:10',
    },
    {
      'day': 28,
      'title_ru': 'Борьба с тепловым стрессом и переход на финишный корм',
      'title_uz': "Issiqlik stressiga qarshi kurash va finish yemiga o'tish",
      'title_en': 'Heat Stress Control and Finisher Feed Transition',
      'url': 'https://www.youtube.com/results?search_query=broiler+heat+stress+tunnel+ventilation+finisher',
      'duration': '8:50',
    },
    {
      'day': 35,
      'title_ru': 'Финальный откорм и качество подстилки',
      'title_uz': "Yakuniy semirtirish va to'shak sifati",
      'title_en': 'Final Fattening and Litter Quality Management',
      'url': 'https://www.youtube.com/results?search_query=ross+308+broiler+week+5+litter+management',
      'duration': '5:30',
    },
    {
      'day': 42,
      'title_ru': 'Подготовка к отлову, прекращение выпойки препаратов и отгрузка',
      'title_uz': "Ushlashga tayyorgarlik, dorilarni to'xtatish va topshirish",
      'title_en': 'Pre-Harvest Preparation and Feed/Medication Withdrawal',
      'url': 'https://www.youtube.com/results?search_query=broiler+harvest+preparation+feed+withdrawal',
      'duration': '10:05',
    },
  ];

  /// Get veterinarians for a specific district (e.g. 'Toshkent', 'Samarqand')
  Future<List<Map<String, dynamic>>> getVetByDistrict(String district) async {
    try {
      final allVets = await getAllVets();
      final normalizedQuery = district.trim().toLowerCase();
      if (normalizedQuery.isEmpty) {
        return const [];
      }
      final filtered = allVets.where((vet) {
        final vetDistrict = (vet['district'] as String? ?? '').toLowerCase();
        final vetName = (vet['name'] as String? ?? '').toLowerCase();
        if (vetDistrict.isEmpty) return false;
        return vetDistrict.contains(normalizedQuery) ||
            normalizedQuery.contains(vetDistrict) ||
            vetName.contains(normalizedQuery);
      }).toList();

      return filtered;
    } catch (_) {
      return _defaultVets;
    }
  }

  /// Get all registered veterinarians
  Future<List<Map<String, dynamic>>> getAllVets() async {
    final cached = _useStaticCache ? _vetsCache : _instanceVetsCache;
    if (cached != null) {
      return cached;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/vets.json')
          .timeout(_loadTimeout);
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['districts'] is List
              ? (decoded['districts'] as List)
              : []);
      final vets = list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final result = vets.isNotEmpty
          ? vets
          : List<Map<String, dynamic>>.from(_defaultVets);
      if (_useStaticCache) {
        _vetsCache = result;
      } else {
        _instanceVetsCache = result;
      }
      return result;
    } catch (_) {
      final fallback = List<Map<String, dynamic>>.from(_defaultVets);
      if (!_useStaticCache) {
        _instanceVetsCache = fallback;
      }
      return fallback;
    }
  }

  /// Get educational video URL for a cycle day
  Future<String?> getVideoForDay(int day) async {
    try {
      // First check daily plan
      final plan = await getDailyPlan(day);
      if (plan?.videoUrl != null && plan!.videoUrl!.isNotEmpty) {
        return plan.videoUrl;
      }

      // Check videos.json
      final videos = await getAllVideos();
      for (final item in videos) {
        if (item['day'] == day) {
          return item['url'] as String?;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get video for day $day: $e');
    }
  }

  /// Get all available videos as raw maps
  Future<List<Map<String, dynamic>>> getAllVideos() async {
    final cached = _useStaticCache ? _videosCache : _instanceVideosCache;
    if (cached != null) {
      return cached;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/videos.json')
          .timeout(_loadTimeout);
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['videos'] is List
              ? (decoded['videos'] as List)
              : []);
      final videos = list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (_useStaticCache) {
        _videosCache = videos;
      } else {
        _instanceVideosCache = videos;
      }
      return videos;
    } catch (_) {
      final fallback = List<Map<String, dynamic>>.from(_defaultVideos);
      if (!_useStaticCache) {
        _instanceVideosCache = fallback;
      }
      return fallback;
    }
  }

  /// Get all available videos parsed as [VideoGuide] models
  Future<List<VideoGuide>> getVideoGuides() async {
    final raw = await getAllVideos();
    return raw.map(VideoGuide.fromJson).toList();
  }

  /// List all available knowledge topic file names for a given language ('uz', 'ru', or 'en')
  Future<List<String>> listTopicNames(String language) async {
    final lower = language.trim().toLowerCase();
    final lang = lower.startsWith('en')
        ? 'en'
        : (lower.startsWith('ru') ? 'ru' : 'uz');
    final prefix = 'knowledge/broilers/$lang/';

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
      final assets = manifest.listAssets();
      final topics = assets
          .where((path) => path.startsWith(prefix) && path.endsWith('.md'))
          .map((path) => path.substring(prefix.length))
          .toList();

      if (topics.isNotEmpty) {
        return topics;
      }
    } catch (_) {
      // Fallback for tests or environments where AssetManifest is mocked/unavailable
    }

    return List<String>.from(_defaultTopicFiles);
  }

  /// Load markdown content for a specific topic article
  Future<String> getTopicContent(String language, String fileName) async {
    final lower = language.trim().toLowerCase();
    final lang = lower.startsWith('en')
        ? 'en'
        : (lower.startsWith('ru') ? 'ru' : 'uz');
    final normalizedFileName =
        fileName.endsWith('.md') ? fileName : '$fileName.md';
    final assetPath = 'knowledge/broilers/$lang/$normalizedFileName';

    try {
      return await _bundle.loadString(assetPath).timeout(_loadTimeout);
    } catch (e) {
      throw Exception('Failed to load topic content from $assetPath: $e');
    }
  }
}
