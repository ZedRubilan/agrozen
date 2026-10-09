import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/course_lesson.dart';
import '../models/course_progress.dart';
import '../providers/supabase_provider.dart';

class CourseRepository {
  final SupabaseProvider _provider;
  final AssetBundle _bundle;

  static const int totalLessonsCount = 5;

  CourseRepository({
    SupabaseProvider? provider,
    AssetBundle? bundle,
  })  : _provider = provider ?? SupabaseProvider(),
        _bundle = bundle ?? rootBundle;

  final Map<String, List<CourseLesson>> _lessonsCache = {};

  /// Get all lessons for the specified language ('uz' or 'ru')
  Future<List<CourseLesson>> getLessons(String language) async {
    final lang = language.toLowerCase() == 'ru' ? 'ru' : 'uz';
    if (_lessonsCache.containsKey(lang)) {
      return _lessonsCache[lang]!;
    }

    try {
      final List<CourseLesson> lessons = [];
      for (int i = 1; i <= totalLessonsCount; i++) {
        final lesson = await getLesson(i, lang);
        if (lesson != null) {
          lessons.add(lesson);
        }
      }
      _lessonsCache[lang] = lessons;
      return lessons;
    } catch (e) {
      throw Exception('Failed to load course lessons for language $lang: $e');
    }
  }

  /// Get a specific lesson by number and language
  Future<CourseLesson?> getLesson(int lessonNumber, String language) async {
    final lang = language.toLowerCase() == 'ru' ? 'ru' : 'uz';
    final path = 'knowledge/course/$lang/lesson_$lessonNumber.json';

    try {
      final content = await _bundle.loadString(path);
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        return CourseLesson.fromJson(parsed);
      }
      return null;
    } catch (e) {
      // Return null if lesson asset not found
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

  /// Save or update farmer's progress on a lesson
  Future<CourseProgress> saveProgress({
    required String farmerId,
    required int lessonNumber,
    required bool quizPassed,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'farmer_id': farmerId,
        'lesson_number': lessonNumber,
        'quiz_passed': quizPassed,
        'completed_at': quizPassed ? now.toIso8601String() : null,
      };

      final result = await _provider.upsertCourseProgress(data);
      return CourseProgress.fromJson(result);
    } catch (e) {
      throw Exception(
        'Failed to save course progress for lesson $lessonNumber: $e',
      );
    }
  }

  /// Get all completed/attempted course progress for a farmer
  Future<List<CourseProgress>> getFarmerProgress(String farmerId) async {
    try {
      final list = await _provider.getCourseProgressForFarmer(farmerId);
      return list.map((item) => CourseProgress.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get course progress for farmer $farmerId: $e');
    }
  }

  /// Get farmer progress for a single lesson
  Future<CourseProgress?> getLessonProgress(
    String farmerId,
    int lessonNumber,
  ) async {
    try {
      final data = await _provider.getCourseProgressForLesson(
        farmerId,
        lessonNumber,
      );
      if (data == null) return null;
      return CourseProgress.fromJson(data);
    } catch (e) {
      throw Exception(
        'Failed to get progress for lesson $lessonNumber: $e',
      );
    }
  }

  /// Check whether farmer has passed all quizzes and completed the course
  Future<bool> isCourseCompleted(
    String farmerId, {
    int totalLessons = totalLessonsCount,
  }) async {
    try {
      final progressList = await getFarmerProgress(farmerId);
      final passedCount = progressList
          .where((item) => item.quizPassed && item.lessonNumber <= totalLessons)
          .length;
      return passedCount >= totalLessons;
    } catch (e) {
      throw Exception('Failed to check course completion: $e');
    }
  }
}
