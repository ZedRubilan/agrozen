// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farmer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Farmer _$FarmerFromJson(Map<String, dynamic> json) => Farmer(
  id: json['id'] as String,
  phone: json['phone'] as String?,
  name: json['name'] as String?,
  language: json['language'] as String? ?? 'uz',
  district: json['district'] as String,
  disclaimerAccepted: json['disclaimer_accepted'] as bool? ?? false,
  dailyQuestionCount: (json['daily_question_count'] as num?)?.toInt() ?? 0,
  lastQuestionDate: json['last_question_date'] == null
      ? null
      : DateTime.parse(json['last_question_date'] as String),
  fcmToken: json['fcm_token'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$FarmerToJson(Farmer instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'name': instance.name,
  'language': instance.language,
  'district': instance.district,
  'disclaimer_accepted': instance.disclaimerAccepted,
  'daily_question_count': instance.dailyQuestionCount,
  'last_question_date': instance.lastQuestionDate?.toIso8601String(),
  if (instance.fcmToken != null) 'fcm_token': instance.fcmToken,
  'created_at': instance.createdAt.toIso8601String(),
  if (instance.updatedAt != null)
    'updated_at': instance.updatedAt?.toIso8601String(),
};
