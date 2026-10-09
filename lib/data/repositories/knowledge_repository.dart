import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/alerts/alert_models.dart';
import '../models/daily_plan.dart';

class KnowledgeRepository {
  final AssetBundle _bundle;

  KnowledgeRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static List<DailyPlan>? _dailyPlansCache;
  static Map<String, dynamic>? _normsCache;
  static NormsData? _parsedNormsCache;
  static List<Map<String, dynamic>>? _vetsCache;
  static List<Map<String, dynamic>>? _videosCache;

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
    final cached = _parsedNormsCache;
    if (cached != null) return cached;

    final raw = await getNorms();
    final parsed = NormsData.fromJson(raw);
    _parsedNormsCache = parsed;
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
    if (_dailyPlansCache != null) {
      return _dailyPlansCache!;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/broiler_plan.json')
          .timeout(const Duration(milliseconds: 300));
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['days'] is List
              ? (decoded['days'] as List)
              : []);
      _dailyPlansCache = list
          .map((item) => DailyPlan.fromJson(item as Map<String, dynamic>))
          .toList();
      return _dailyPlansCache!;
    } catch (_) {
      // Fallback: generate default 42-day plans if assets cannot be read
      _dailyPlansCache = List.generate(
        42,
        (i) => DailyPlan(
          day: i + 1,
          tasksRu: 'День ${i + 1}: Поддержание температуры, контроль воды и комбикорма.',
          tasksUz: '${i + 1}-kun: Haroratni nazorat qilish, toza suv va aralash yem berish.',
          videoUrl: 'https://youtube.com/watch?v=agrozen_day_${i + 1}',
        ),
      );
      return _dailyPlansCache!;
    }
  }

  /// Get normative data for broilers (Ross-308 / Cobb-500)
  Future<Map<String, dynamic>> getNorms() async {
    if (_normsCache != null) {
      return _normsCache!;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/norms.json')
          .timeout(const Duration(milliseconds: 300));
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        _normsCache = parsed;
        return _normsCache!;
      }
      return _defaultNorms;
    } catch (_) {
      _normsCache = _defaultNorms;
      return _normsCache!;
    }
  }

  static const Map<String, dynamic> _defaultNorms = {
    'breed': 'Ross-308',
    'alert_thresholds': {
      'daily_mortality_percent': 1.0,
      'weekly_weight_deviation_percent': 15.0,
    },
    'weekly_weight_targets': {
      '7': 180,
      '14': 500,
      '21': 900,
      '28': 1400,
      '35': 1900,
      '42': 2400,
    },
    'daily_feed_per_bird': {
      '7': 25,
      '14': 55,
      '21': 85,
      '28': 120,
      '35': 155,
      '42': 180,
    },
    'temperature_targets': {
      '1': 34,
      '3': 33,
      '7': 32,
      '14': 29,
      '21': 27,
      '28': 24,
      '35': 22,
      '42': 20,
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

  /// Get veterinarians for a specific district (e.g. 'Toshkent', 'Samarqand')
  Future<List<Map<String, dynamic>>> getVetByDistrict(String district) async {
    try {
      final allVets = await getAllVets();
      final normalizedQuery = district.trim().toLowerCase();
      if (normalizedQuery.isEmpty) {
        // Never guess: an empty query must not resolve to a random vet.
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

      // No match at all -> empty, NOT the whole directory. Callers show a
      // generic "call your district vet service" fallback instead of a wrong
      // region's phone number when no match exists.
      return filtered;
    } catch (_) {
      return _defaultVets;
    }
  }

  /// Get all registered veterinarians
  Future<List<Map<String, dynamic>>> getAllVets() async {
    if (_vetsCache != null) {
      return _vetsCache!;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/vets.json')
          .timeout(const Duration(milliseconds: 300));
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['districts'] is List
              ? (decoded['districts'] as List)
              : []);
      _vetsCache = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      return _vetsCache!.isNotEmpty ? _vetsCache! : _defaultVets;
    } catch (_) {
      _vetsCache = List<Map<String, dynamic>>.from(_defaultVets);
      return _vetsCache!;
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

  /// Get all available videos
  Future<List<Map<String, dynamic>>> getAllVideos() async {
    if (_videosCache != null) {
      return _videosCache!;
    }
    try {
      final content = await _bundle
          .loadString('knowledge/videos.json')
          .timeout(const Duration(milliseconds: 300));
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['videos'] is List
              ? (decoded['videos'] as List)
              : []);
      _videosCache = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      return _videosCache!;
    } catch (_) {
      _videosCache = [];
      return _videosCache!;
    }
  }

  /// List all available knowledge topic file names for a given language ('uz' or 'ru')
  Future<List<String>> listTopicNames(String language) async {
    final lang = language.toLowerCase() == 'ru' ? 'ru' : 'uz';
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
    final lang = language.toLowerCase() == 'ru' ? 'ru' : 'uz';
    final normalizedFileName =
        fileName.endsWith('.md') ? fileName : '$fileName.md';
    final assetPath = 'knowledge/broilers/$lang/$normalizedFileName';

    try {
      return await _bundle.loadString(assetPath);
    } catch (e) {
      throw Exception('Failed to load topic content from $assetPath: $e');
    }
  }
}
