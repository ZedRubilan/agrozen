// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseQuiz _$CourseQuizFromJson(Map<String, dynamic> json) => CourseQuiz(
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctOptionIndex: (json['correct_option_index'] as num).toInt(),
  explanation: json['explanation'] as String?,
);

Map<String, dynamic> _$CourseQuizToJson(CourseQuiz instance) =>
    <String, dynamic>{
      'question': instance.question,
      'options': instance.options,
      'correct_option_index': instance.correctOptionIndex,
      'explanation': instance.explanation,
    };

CourseLesson _$CourseLessonFromJson(Map<String, dynamic> json) => CourseLesson(
  lessonNumber: (json['lesson_number'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String,
  quiz: json['quiz'] == null
      ? null
      : CourseQuiz.fromJson(json['quiz'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CourseLessonToJson(CourseLesson instance) =>
    <String, dynamic>{
      'lesson_number': instance.lessonNumber,
      'title': instance.title,
      'content': instance.content,
      'quiz': instance.quiz?.toJson(),
    };
