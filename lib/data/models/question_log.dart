import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'question_log.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class QuestionLog extends Equatable {
  final String id;
  final String farmerId;
  final String question;
  final String? answer;
  final List<String>? topicsUsed;
  final String language;
  final String source; // 'text' or 'voice'
  final String? transcribedText;
  final DateTime createdAt;

  const QuestionLog({
    required this.id,
    required this.farmerId,
    required this.question,
    this.answer,
    this.topicsUsed,
    this.language = 'uz',
    this.source = 'text',
    this.transcribedText,
    required this.createdAt,
  });

  factory QuestionLog.fromJson(Map<String, dynamic> json) =>
      _$QuestionLogFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionLogToJson(this);

  QuestionLog copyWith({
    String? id,
    String? farmerId,
    String? question,
    String? answer,
    List<String>? topicsUsed,
    String? language,
    String? source,
    String? transcribedText,
    DateTime? createdAt,
  }) {
    return QuestionLog(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      topicsUsed: topicsUsed ?? this.topicsUsed,
      language: language ?? this.language,
      source: source ?? this.source,
      transcribedText: transcribedText ?? this.transcribedText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        question,
        answer,
        topicsUsed,
        language,
        source,
        transcribedText,
        createdAt,
      ];
}
