import 'package:equatable/equatable.dart';

abstract class CourseState extends Equatable {
  const CourseState();

  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {
  const CourseInitial();
}

class CourseLoading extends CourseState {
  const CourseLoading();
}

class CourseLoaded extends CourseState {
  final List<dynamic> lessons;
  final List<dynamic> progressList;

  const CourseLoaded(this.lessons, this.progressList);

  @override
  List<Object?> get props => [lessons, progressList];
}

class LessonViewing extends CourseState {
  final dynamic lesson;
  final dynamic quiz;

  const LessonViewing(this.lesson, this.quiz);

  @override
  List<Object?> get props => [lesson, quiz];
}

class QuizCompleted extends CourseState {
  final bool passed;
  final double score;

  const QuizCompleted(this.passed, this.score);

  @override
  List<Object?> get props => [passed, score];
}

class CourseError extends CourseState {
  final String message;

  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}
