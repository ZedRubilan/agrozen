import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'diary_entry.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DiaryEntry extends Equatable {
  final String id;
  final String batchId;
  final DateTime entryDate;
  final String entryType; // 'mortality', 'feed', 'weight'
  final double value;
  final String? notes;
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.batchId,
    required this.entryDate,
    required this.entryType,
    required this.value,
    this.notes,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  DiaryEntry copyWith({
    String? id,
    String? batchId,
    DateTime? entryDate,
    String? entryType,
    double? value,
    String? notes,
    DateTime? createdAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      entryDate: entryDate ?? this.entryDate,
      entryType: entryType ?? this.entryType,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        batchId,
        entryDate,
        entryType,
        value,
        notes,
        createdAt,
      ];
}
