// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyPlan _$DailyPlanFromJson(Map<String, dynamic> json) => DailyPlan(
  day: (json['day'] as num).toInt(),
  tasksRu: json['tasks_ru'] as String? ?? '',
  tasksUz: json['tasks_uz'] as String? ?? '',
  tasksEn: json['tasks_en'] is List
      ? (json['tasks_en'] as List).map((e) => e.toString()).join(' ')
      : (json['tasks_en'] as String? ?? ''),
  videoUrl: json['video_url'] as String?,
);

Map<String, dynamic> _$DailyPlanToJson(DailyPlan instance) => <String, dynamic>{
  'day': instance.day,
  'tasks_ru': instance.tasksRu,
  'tasks_uz': instance.tasksUz,
  if (instance.tasksEn.isNotEmpty) 'tasks_en': instance.tasksEn,
  'video_url': instance.videoUrl,
};
