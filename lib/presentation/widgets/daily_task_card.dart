import 'package:flutter/material.dart';
import '../../data/models/daily_plan.dart';

class DailyTaskCard extends StatelessWidget {
  final DailyPlan plan;
  final String language;
  final int? targetTemperature;
  final VoidCallback? onWatchVideo;

  const DailyTaskCard({
    super.key,
    required this.plan,
    this.language = 'uz',
    this.targetTemperature,
    this.onWatchVideo,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = plan.getTasks(language);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        language == 'ru' ? '${plan.day}-й день' : '${plan.day}-kun',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (targetTemperature != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.thermostat, size: 16, color: Colors.deepOrange),
                        const SizedBox(width: 4),
                        Text(
                          '$targetTemperature°C',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              language == 'ru' ? 'Задачи на сегодня:' : 'Bugungi vazifalar:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tasks,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
            if (plan.videoUrl != null && plan.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onWatchVideo ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            language == 'ru'
                                ? 'Видео: ${plan.videoUrl}'
                                : 'Video: ${plan.videoUrl}',
                          ),
                        ),
                      );
                    },
                icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                label: Text(
                  language == 'ru' ? 'Смотреть видеогид' : "Videoni ko'rish",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
