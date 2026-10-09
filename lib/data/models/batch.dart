import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Batch extends Equatable {
  final String id;
  final String farmerId;
  final DateTime arrivalDate;
  final int initialCount;
  final int? currentCount;
  final String status;
  final DateTime createdAt;

  const Batch({
    required this.id,
    required this.farmerId,
    required this.arrivalDate,
    required this.initialCount,
    this.currentCount,
    this.status = 'active',
    required this.createdAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);

  Map<String, dynamic> toJson() => _$BatchToJson(this);

  Batch copyWith({
    String? id,
    String? farmerId,
    DateTime? arrivalDate,
    int? initialCount,
    int? currentCount,
    String? status,
    DateTime? createdAt,
  }) {
    return Batch(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      initialCount: initialCount ?? this.initialCount,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        arrivalDate,
        initialCount,
        currentCount,
        status,
        createdAt,
      ];
}
