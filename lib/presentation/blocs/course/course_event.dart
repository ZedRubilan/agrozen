import 'package:equatable/equatable.dart';
abstract class CourseEvent extends Equatable {
  const CourseEvent();
  @override
  List<Object> get props => [];
}
class LoadCourse extends CourseEvent {}
class SelectLesson extends CourseEvent {
  final int lessonNumber;
  const SelectLesson(this.lessonNumber);
}
class SubmitQuiz extends CourseEvent {
  final int lessonNumber;
  final List<dynamic> answers;
  const SubmitQuiz(this.lessonNumber, this.answers);
}
