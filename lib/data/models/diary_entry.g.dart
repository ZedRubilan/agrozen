// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiaryEntry _$DiaryEntryFromJson(Map<String, dynamic> json) => DiaryEntry(
  id: json['id'] as String,
  batchId: json['batch_id'] as String,
  entryDate: DateTime.parse(json['entry_date'] as String),
  entryType: json['entry_type'] as String,
  value: (json['value'] as num).toDouble(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$DiaryEntryToJson(DiaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batch_id': instance.batchId,
      'entry_date': instance.entryDate.toIso8601String(),
      'entry_type': instance.entryType,
      'value': instance.value,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };
