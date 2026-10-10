import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../data/models/daily_plan.dart';
import '../../services/external_actions.dart';

/// Redesigned Daily Task & Protocol Card
///
/// Features a high-craft agronomy checklist presentation,
/// ambient temperature indicator badge, and tactile media launcher.
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder, width: 1.0),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Day Pill + Temperature Norm Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withAlpha(40),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: AppTheme.primaryGreenDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        language == 'en'
                            ? 'Day ${plan.day}'
                            : (language == 'ru'
                                ? '${plan.day}-й день'
                                : '${plan.day}-kun'),
                        style: const TextStyle(
                          color: AppTheme.primaryGreenDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (targetTemperature != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: Colors.deepOrange.withAlpha(45),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thermostat_rounded,
                          size: 17,
                          color: Color(0xFFD84315),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$targetTemperature°C',
                          style: const TextStyle(
                            color: Color(0xFFD84315),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Section Title
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.task_alt_rounded,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  language == 'en'
                      ? "Today's Tasks:"
                      : (language == 'ru'
                          ? 'Задачи на сегодня:'
                          : 'Bugungi vazifalar:'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content Container with uniform border and accent strip inside
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder, width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: AppTheme.primaryGreen,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            tasks,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.55,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Video Guide Action Button
            if (plan.videoUrl != null && plan.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onWatchVideo ??
                      () => const ExternalActions().openVideo(context, plan.videoUrl!),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: Colors.red.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          language == 'en'
                              ? 'Watch Video Guide'
                              : (language == 'ru'
                                  ? 'Смотреть видеогид'
                                  : "Videoni ko'rish"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB91C1C),
                            fontSize: 14,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
