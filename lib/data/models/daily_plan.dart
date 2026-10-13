import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'daily_plan.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DailyPlan extends Equatable {
  final int day;
  final String tasksRu;
  final String tasksUz;
  final String tasksEn;
  final String? videoUrl;

  const DailyPlan({
    required this.day,
    required this.tasksRu,
    required this.tasksUz,
    this.tasksEn = '',
    this.videoUrl,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) =>
      _$DailyPlanFromJson(json);

  Map<String, dynamic> toJson() => _$DailyPlanToJson(this);

  String getTasks(String language) {
    final code = language.trim().toLowerCase();
    if (code.startsWith('uz')) {
      return tasksUz;
    }
    if (code.startsWith('en')) {
      if (tasksEn.trim().isNotEmpty) {
        return tasksEn;
      }
      return _fallbackTasksEn(day);
    }
    return tasksRu;
  }

  /// The day's tasks as separate checklist items.
  List<String> taskList(String language) {
    final text = getTasks(language).trim();
    if (text.isEmpty) return const [];
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 1) return lines;
    // Uzbek / Russian plans are stored as one paragraph — split into sentences
    // (a sentence ends with '.' followed by a capitalised word or digit).
    return text
        .split(RegExp(r"(?<=[.!])\s+(?=[A-ZА-ЯЁOʻ0-9])"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _fallbackTasksEn(int day) {
    if (day == 1) {
      return 'Prepare the brooder. Verify litter-level temperature (32–33°C). Keep 24-hour lighting on. Offer warm water (20–22°C) with glucose/vitamins first, then spread starter crumble feed on trays/paper after 2 hours.';
    } else if (day == 2) {
      return 'Maintain temperature at 32°C. Check crop fill on 50 sample chicks (95%+ should have soft feed and water). Clean drinkers and refresh water.';
    } else if (day == 3) {
      return 'Temperature 31–32°C, humidity 60–70%. Begin transitioning chicks to pan/tube feeders. Inspect for weak chicks and maintain draft-free minimum ventilation.';
    } else if (day <= 7) {
      return 'Day $day (Starter Phase): Maintain brooder temperature at 29–31°C, ensure constant access to starter crumble and clean water (18–22°C), keep litter dry around drinkers, and log daily mortality and feed intake.';
    } else if (day <= 14) {
      return 'Day $day (Starter-to-Grower Transition): Maintain house temperature at 26–29°C, raise feeder and drinker height to bird back level, inspect litter for dampness or coccidiosis signs, and weigh a sample of birds on Day 14.';
    } else if (day <= 21) {
      return 'Day $day (Grower Phase): Maintain house temperature at 23–26°C, provide grower pelleted feed, increase ventilation air exchange as biomass grows, and ensure ammonia levels stay undetectable.';
    } else if (day <= 28) {
      return 'Day $day (Early Finisher Phase): Maintain house temperature at 21–23°C, transition smoothly to finisher feed, monitor water-to-feed ratio (1.8–2.0:1), and guard against heat buildup during midday.';
    } else if (day <= 35) {
      return 'Day $day (Finisher Phase): Maintain house temperature at 19–21°C, keep tunnel/exhaust ventilation active to remove heat and moisture, friable litter, and perform weekly sample weighing.';
    } else {
      return 'Day $day (Pre-Market Phase): Maintain 18–20°C house temperature with strong airflow, observe feed/medication withdrawal schedules prior to harvest, and minimize flock stress.';
    }
  }

  DailyPlan copyWith({
    int? day,
    String? tasksRu,
    String? tasksUz,
    String? tasksEn,
    String? videoUrl,
  }) {
    return DailyPlan(
      day: day ?? this.day,
      tasksRu: tasksRu ?? this.tasksRu,
      tasksUz: tasksUz ?? this.tasksUz,
      tasksEn: tasksEn ?? this.tasksEn,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => [
        day,
        tasksRu,
        tasksUz,
        tasksEn,
        videoUrl,
      ];
}
