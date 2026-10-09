// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseProgress _$CourseProgressFromJson(Map<String, dynamic> json) =>
    CourseProgress(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      lessonNumber: (json['lesson_number'] as num).toInt(),
      quizPassed: json['quiz_passed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$CourseProgressToJson(CourseProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'farmer_id': instance.farmerId,
      'lesson_number': instance.lessonNumber,
      'quiz_passed': instance.quizPassed,
      'completed_at': instance.completedAt?.toIso8601String(),
    };
