import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_lesson.dart';
import '../models/course_progress.dart';
import '../providers/supabase_provider.dart';

class CourseRepository {
  final SupabaseProvider _provider;
  final AssetBundle _bundle;

  static const int totalLessonsCount = 5;
  static const String _localProgressKey = 'local_course_progress_cache';

  CourseRepository({
    SupabaseProvider? provider,
    AssetBundle? bundle,
  })  : _provider = provider ?? SupabaseProvider(),
        _bundle = bundle ?? rootBundle;

  final Map<String, List<CourseLesson>> _lessonsCache = {};

  static String _normalizeLang(String language) {
    final code = language.trim().toLowerCase();
    if (code.startsWith('en')) return 'en';
    if (code.startsWith('ru')) return 'ru';
    return 'uz';
  }

  /// Get all lessons for the specified language ('uz', 'ru', or 'en')
  Future<List<CourseLesson>> getLessons(String language) async {
    final lang = _normalizeLang(language);
    if (_lessonsCache.containsKey(lang)) {
      return _lessonsCache[lang]!;
    }

    final List<CourseLesson> lessons = [];
    for (int i = 1; i <= totalLessonsCount; i++) {
      final lesson = await getLesson(i, lang);
      if (lesson != null) {
        lessons.add(lesson);
      }
    }
    if (lessons.isNotEmpty) {
      _lessonsCache[lang] = lessons;
    }
    return lessons;
  }

  /// Get a specific lesson by number and language.
  /// Supports both `getLesson(int lessonNumber, String language)` and
  /// `getLesson(String language, int lessonNumber)` parameter orders.
  Future<CourseLesson?> getLesson(dynamic first, dynamic second) async {
    final int lessonNumber = first is int ? first : (second as int);
    final String language = first is String ? first : (second as String);
    final lang = _normalizeLang(language);
    final path = 'knowledge/course/$lang/lesson_$lessonNumber.json';

    try {
      final content = await _bundle
          .loadString(path)
          .timeout(const Duration(milliseconds: 2000));
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        return CourseLesson.fromJson(parsed);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get quiz data for a specific lesson
  Future<CourseQuiz?> getQuizForLesson(
    int lessonNumber,
    String language,
  ) async {
    final lesson = await getLesson(lessonNumber, language);
    return lesson?.quiz;
  }

  Future<List<CourseProgress>> _loadLocalProgress(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_localProgressKey);
    final List<CourseProgress> result = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        result.addAll(
          decoded.map(
            (e) => CourseProgress.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      } catch (_) {}
    }
    final completedIds = prefs.getStringList('completed_lessons') ?? const [];
    for (final idStr in completedIds) {
      final num = int.tryParse(idStr);
      if (num != null && !result.any((p) => p.lessonNumber == num)) {
        result.add(
          CourseProgress(
            id: 'local-prog-$num',
            farmerId: prefs.getString('farmer_id') ?? 'local-farmer',
            lessonNumber: num,
            quizPassed: true,
            completedAt: DateTime.now(),
          ),
        );
      }
    }
    return result;
  }

  Future<void> _saveLocalProgress(
    SharedPreferences prefs,
    CourseProgress progress,
  ) async {
    final current = await _loadLocalProgress(prefs);
    current.removeWhere(
      (p) =>
          p.farmerId == progress.farmerId &&
          p.lessonNumber == progress.lessonNumber,
    );
    current.add(progress);
    await prefs.setString(
      _localProgressKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    if (progress.quizPassed) {
      final list = List<String>.from(
        prefs.getStringList('completed_lessons') ?? const <String>[],
      );
      final lessonKey = progress.lessonNumber.toString();
      if (!list.contains(lessonKey)) {
        list.add(lessonKey);
        await prefs.setStringList('completed_lessons', list);
      }
    }
  }

  /// Save or update farmer's progress on a lesson
  Future<CourseProgress> saveProgress({
    required String farmerId,
    required int lessonNumber,
    required bool quizPassed,
  }) async {
    final now = DateTime.now();
    if (_provider.isConfigured) {
      try {
        final data = {
          'farmer_id': farmerId,
          'lesson_number': lessonNumber,
          'quiz_passed': quizPassed,
          'completed_at': quizPassed ? now.toIso8601String() : null,
        };

        final result = await _provider.upsertCourseProgress(data);
        final saved = CourseProgress.fromJson(result);
        final prefs = await SharedPreferences.getInstance();
        await _saveLocalProgress(prefs, saved);
        return saved;
      } catch (_) {}
    }

    final fallback = CourseProgress(
      id: 'local-prog-$farmerId-$lessonNumber',
      farmerId: farmerId,
      lessonNumber: lessonNumber,
      quizPassed: quizPassed,
      completedAt: quizPassed ? now : null,
    );
    final prefs = await SharedPreferences.getInstance();
    await _saveLocalProgress(prefs, fallback);
    return fallback;
  }

  /// Get all completed/attempted course progress for a farmer
  Future<List<CourseProgress>> getFarmerProgress(String farmerId) async {
    if (_provider.isConfigured) {
      try {
        final list = await _provider.getCourseProgressForFarmer(farmerId);
        return list.map((item) => CourseProgress.fromJson(item)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    return _loadLocalProgress(prefs);
  }

  /// Get farmer progress for a single lesson
  Future<CourseProgress?> getLessonProgress(
    String farmerId,
    int lessonNumber,
  ) async {
    if (_provider.isConfigured) {
      try {
        final data = await _provider.getCourseProgressForLesson(
          farmerId,
          lessonNumber,
        );
        if (data != null) return CourseProgress.fromJson(data);
      } catch (_) {}
    }
    final all = await getFarmerProgress(farmerId);
    for (final p in all) {
      if (p.lessonNumber == lessonNumber) return p;
    }
    return null;
  }

  /// Check whether farmer has passed all quizzes and completed the course
  Future<bool> isCourseCompleted(
    String farmerId, {
    int totalLessons = totalLessonsCount,
  }) async {
    final progressList = await getFarmerProgress(farmerId);
    final passedCount = progressList
        .where((item) => item.quizPassed && item.lessonNumber <= totalLessons)
        .map((item) => item.lessonNumber)
        .toSet()
        .length;
    return passedCount >= totalLessons;
  }
}
