import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course_progress.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CourseProgress extends Equatable {
  final String id;
  final String farmerId;
  final int lessonNumber;
  final bool quizPassed;
  final DateTime? completedAt;

  const CourseProgress({
    required this.id,
    required this.farmerId,
    required this.lessonNumber,
    this.quizPassed = false,
    this.completedAt,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressFromJson(json);

  Map<String, dynamic> toJson() => _$CourseProgressToJson(this);

  CourseProgress copyWith({
    String? id,
    String? farmerId,
    int? lessonNumber,
    bool? quizPassed,
    DateTime? completedAt,
  }) {
    return CourseProgress(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      quizPassed: quizPassed ?? this.quizPassed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        lessonNumber,
        quizPassed,
        completedAt,
      ];
}
