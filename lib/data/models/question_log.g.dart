// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionLog _$QuestionLogFromJson(Map<String, dynamic> json) => QuestionLog(
  id: json['id'] as String,
  farmerId: json['farmer_id'] as String?,
  question: json['question'] as String,
  answer: json['answer'] as String?,
  topicsUsed: (json['topics_used'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  language: json['language'] as String? ?? 'uz',
  source: json['source'] as String? ?? 'text',
  transcribedText: json['transcribed_text'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$QuestionLogToJson(QuestionLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'farmer_id': instance.farmerId,
      'question': instance.question,
      'answer': instance.answer,
      'topics_used': instance.topicsUsed,
      'language': instance.language,
      'source': instance.source,
      'transcribed_text': instance.transcribedText,
      'created_at': instance.createdAt.toIso8601String(),
    };
