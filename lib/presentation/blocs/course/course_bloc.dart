import 'package:flutter_bloc/flutter_bloc.dart';
import 'course_event.dart';
import 'course_state.dart';
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  CourseBloc() : super(CourseInitial()) {
    on<LoadCourse>((event, emit) => emit(const CourseLoaded([], [])));
    on<SelectLesson>((event, emit) => emit(const LessonViewing(null, null)));
    on<SubmitQuiz>((event, emit) => emit(const QuizCompleted(true, 100.0)));
  }
}
