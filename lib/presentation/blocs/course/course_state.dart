import 'package:equatable/equatable.dart';
abstract class CourseState extends Equatable {
  const CourseState();
  @override
  List<Object?> get props => [];
}
class CourseInitial extends CourseState {}
class CourseLoading extends CourseState {}
class CourseLoaded extends CourseState {
  final List<dynamic> lessons;
  final List<dynamic> progressList;
  const CourseLoaded(this.lessons, this.progressList);
}
class LessonViewing extends CourseState {
  final dynamic lesson, quiz;
  const LessonViewing(this.lesson, this.quiz);
}
class QuizCompleted extends CourseState {
  final bool passed;
  final double score;
  const QuizCompleted(this.passed, this.score);
}
class CourseError extends CourseState {
  final String message;
  const CourseError(this.message);
}
