import 'package:equatable/equatable.dart';

abstract class CourseEvent extends Equatable {
  const CourseEvent();

  @override
  List<Object?> get props => [];
}

class LoadCourse extends CourseEvent {
  const LoadCourse();
}

class SelectLesson extends CourseEvent {
  final int lessonNumber;

  const SelectLesson(this.lessonNumber);

  @override
  List<Object?> get props => [lessonNumber];
}

class SubmitQuiz extends CourseEvent {
  final int lessonNumber;
  final List<dynamic> answers;

  const SubmitQuiz(this.lessonNumber, this.answers);

  @override
  List<Object?> get props => [lessonNumber, answers];
}
