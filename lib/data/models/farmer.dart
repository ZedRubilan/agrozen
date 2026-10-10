import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'farmer.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Farmer extends Equatable {
  final String id;
  final String? phone;
  final String? name;
  final String language;
  final String district;
  final bool disclaimerAccepted;
  final int dailyQuestionCount;
  final DateTime? lastQuestionDate;
  @JsonKey(name: 'fcm_token')
  final String? fcmToken;
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Farmer({
    required this.id,
    this.phone,
    this.name,
    this.language = 'uz',
    required this.district,
    this.disclaimerAccepted = false,
    this.dailyQuestionCount = 0,
    this.lastQuestionDate,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => _$FarmerFromJson(json);

  Map<String, dynamic> toJson() => _$FarmerToJson(this);

  Farmer copyWith({
    String? id,
    String? phone,
    String? name,
    String? language,
    String? district,
    bool? disclaimerAccepted,
    int? dailyQuestionCount,
    DateTime? lastQuestionDate,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Farmer(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      language: language ?? this.language,
      district: district ?? this.district,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      dailyQuestionCount: dailyQuestionCount ?? this.dailyQuestionCount,
      lastQuestionDate: lastQuestionDate ?? this.lastQuestionDate,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        name,
        language,
        district,
        disclaimerAccepted,
        dailyQuestionCount,
        lastQuestionDate,
        fcmToken,
        createdAt,
        updatedAt,
      ];
}
