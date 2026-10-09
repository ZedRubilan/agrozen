import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daily_plan.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DailyPlan extends Equatable {
  final int day;
  final String tasksRu;
  final String tasksUz;
  final String? videoUrl;

  const DailyPlan({
    required this.day,
    required this.tasksRu,
    required this.tasksUz,
    this.videoUrl,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) =>
      _$DailyPlanFromJson(json);

  Map<String, dynamic> toJson() => _$DailyPlanToJson(this);

  String getTasks(String language) {
    if (language.toLowerCase() == 'uz') {
      return tasksUz;
    }
    return tasksRu;
  }

  DailyPlan copyWith({
    int? day,
    String? tasksRu,
    String? tasksUz,
    String? videoUrl,
  }) {
    return DailyPlan(
      day: day ?? this.day,
      tasksRu: tasksRu ?? this.tasksRu,
      tasksUz: tasksUz ?? this.tasksUz,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => [
        day,
        tasksRu,
        tasksUz,
        videoUrl,
      ];
}
