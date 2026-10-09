import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course_lesson.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CourseQuiz extends Equatable {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;

  const CourseQuiz({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  factory CourseQuiz.fromJson(Map<String, dynamic> json) =>
      _$CourseQuizFromJson(json);

  Map<String, dynamic> toJson() => _$CourseQuizToJson(this);

  @override
  List<Object?> get props => [question, options, correctOptionIndex, explanation];
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CourseLesson extends Equatable {
  final int lessonNumber;
  final String title;
  final String content;
  final CourseQuiz? quiz;

  const CourseLesson({
    required this.lessonNumber,
    required this.title,
    required this.content,
    this.quiz,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) =>
      _$CourseLessonFromJson(json);

  Map<String, dynamic> toJson() => _$CourseLessonToJson(this);

  CourseLesson copyWith({
    int? lessonNumber,
    String? title,
    String? content,
    CourseQuiz? quiz,
  }) {
    return CourseLesson(
      lessonNumber: lessonNumber ?? this.lessonNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      quiz: quiz ?? this.quiz,
    );
  }

  @override
  List<Object?> get props => [lessonNumber, title, content, quiz];
}
