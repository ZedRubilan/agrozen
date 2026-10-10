import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/course_progress.dart';
import '../../../data/repositories/course_repository.dart';
import 'course_event.dart';
import 'course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository _courseRepository;

  CourseBloc({CourseRepository? courseRepository})
      : _courseRepository = courseRepository ?? CourseRepository(),
        super(const CourseInitial()) {
    on<LoadCourse>(_onLoadCourse);
    on<SelectLesson>(_onSelectLesson);
    on<SubmitQuiz>(_onSubmitQuiz);
  }

  Future<void> _onLoadCourse(
    LoadCourse event,
    Emitter<CourseState> emit,
  ) async {
    emit(const CourseLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_language') ?? 'uz';
      final farmerId = prefs.getString('farmer_id') ?? 'local_farmer';

      final lessons = await _courseRepository.getLessons(lang);
      List<CourseProgress> progressList = [];
      try {
        progressList = await _courseRepository.getFarmerProgress(farmerId);
      } catch (_) {}

      emit(CourseLoaded(lessons, progressList));
    } catch (e) {
      emit(CourseError(e.toString()));
    }
  }

  Future<void> _onSelectLesson(
    SelectLesson event,
    Emitter<CourseState> emit,
  ) async {
    emit(const CourseLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_language') ?? 'uz';
      final lesson = await _courseRepository.getLesson(event.lessonNumber, lang);
      final quiz = await _courseRepository.getQuizForLesson(
        event.lessonNumber,
        lang,
      );
      emit(LessonViewing(lesson, quiz));
    } catch (e) {
      emit(CourseError(e.toString()));
    }
  }

  Future<void> _onSubmitQuiz(
    SubmitQuiz event,
    Emitter<CourseState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_language') ?? 'uz';
      final farmerId = prefs.getString('farmer_id') ?? 'local_farmer';
      final quiz = await _courseRepository.getQuizForLesson(
        event.lessonNumber,
        lang,
      );

      double score = 100.0;
      if (quiz != null && event.answers.isNotEmpty) {
        final answer = event.answers.first;
        final isCorrect = answer == quiz.correctOptionIndex;
        score = isCorrect ? 100.0 : 0.0;
      }

      final passed = score >= 60.0;
      await _courseRepository.saveProgress(
        farmerId: farmerId,
        lessonNumber: event.lessonNumber,
        quizPassed: passed,
      );

      emit(QuizCompleted(passed, score));
    } catch (e) {
      emit(CourseError(e.toString()));
    }
  }
}
