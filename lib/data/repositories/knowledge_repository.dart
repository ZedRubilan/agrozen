import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/daily_plan.dart';

class KnowledgeRepository {
  final AssetBundle _bundle;

  KnowledgeRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  List<DailyPlan>? _dailyPlansCache;
  Map<String, dynamic>? _normsCache;
  List<Map<String, dynamic>>? _vetsCache;
  List<Map<String, dynamic>>? _videosCache;

  static const List<String> _defaultTopicFiles = [
    'temperature.md',
    'feed.md',
    'vaccination.md',
    'ventilation.md',
  ];

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
      final content = await _bundle.loadString('knowledge/broiler_plan.json');
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
    } catch (e) {
      throw Exception('Failed to load broiler plan asset: $e');
    }
  }

  /// Get normative data for broilers (Ross-308 / Cobb-500)
  Future<Map<String, dynamic>> getNorms() async {
    if (_normsCache != null) {
      return _normsCache!;
    }
    try {
      final content = await _bundle.loadString('knowledge/norms.json');
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        _normsCache = parsed;
        return _normsCache!;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load norms asset: $e');
    }
  }

  /// Get veterinarians for a specific district (e.g. 'Toshkent', 'Samarqand')
  Future<List<Map<String, dynamic>>> getVetByDistrict(String district) async {
    try {
      final allVets = await getAllVets();
      final normalizedQuery = district.trim().toLowerCase();
      final filtered = allVets.where((vet) {
        final vetDistrict = (vet['district'] as String? ?? '').toLowerCase();
        final vetName = (vet['name'] as String? ?? '').toLowerCase();
        return vetDistrict.contains(normalizedQuery) ||
            normalizedQuery.contains(vetDistrict) ||
            vetName.contains(normalizedQuery);
      }).toList();

      return filtered.isNotEmpty ? filtered : allVets;
    } catch (e) {
      throw Exception('Failed to get vets for district $district: $e');
    }
  }

  /// Get all registered veterinarians
  Future<List<Map<String, dynamic>>> getAllVets() async {
    if (_vetsCache != null) {
      return _vetsCache!;
    }
    try {
      final content = await _bundle.loadString('knowledge/vets.json');
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['districts'] is List
              ? (decoded['districts'] as List)
              : []);
      _vetsCache = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      return _vetsCache!;
    } catch (e) {
      throw Exception('Failed to load vets asset: $e');
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
      final content = await _bundle.loadString('knowledge/videos.json');
      final dynamic decoded = jsonDecode(content);
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['videos'] is List
              ? (decoded['videos'] as List)
              : []);
      _videosCache = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      return _videosCache!;
    } catch (e) {
      throw Exception('Failed to load videos asset: $e');
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
