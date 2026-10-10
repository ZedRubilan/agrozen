// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Batch _$BatchFromJson(Map<String, dynamic> json) => Batch(
  id: json['id'] as String,
  farmerId: json['farmer_id'] as String,
  arrivalDate: DateTime.parse(json['arrival_date'] as String),
  initialCount: (json['initial_count'] as num).toInt(),
  currentCount: (json['current_count'] as num?)?.toInt(),
  status: json['status'] as String? ?? 'active',
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BatchToJson(Batch instance) => <String, dynamic>{
  'id': instance.id,
  'farmer_id': instance.farmerId,
  'arrival_date': instance.arrivalDate.toIso8601String(),
  'initial_count': instance.initialCount,
  'current_count': instance.currentCount,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  if (instance.updatedAt != null)
    'updated_at': instance.updatedAt?.toIso8601String(),
};
