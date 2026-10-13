import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/course_repository.dart';

/// Which of the 5 course lessons the farmer has passed.
class LessonProgress {
  LessonProgress._();

  static const int totalLessons = 5;
  static const String _key = 'completed_lessons';

  static Future<Set<int>> completed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id >= 1 && id <= totalLessons)
        .toSet();
  }

  /// First lesson not yet passed, or null when the course is complete.
  static int? nextLesson(Set<int> done) {
    for (var i = 1; i <= totalLessons; i++) {
      if (!done.contains(i)) return i;
    }
    return null;
  }

  static Future<void> markPassed(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (!list.contains('$lessonId')) {
      list.add('$lessonId');
      await prefs.setStringList(_key, list);
    }
    try {
      await CourseRepository().saveProgress(
        farmerId: prefs.getString('farmer_id') ?? 'local_farmer',
        lessonNumber: lessonId,
        quizPassed: true,
      );
    } catch (_) {
      // Sync is best-effort; local progress is the source of truth.
    }
  }
}
