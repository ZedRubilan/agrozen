import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';

/// Ultra-rounded, Image-first 42-Day Milestone Pathway card
/// Displays the flock growth cycle with photographic milestone avatars and minimal-click clarity.
class FlockPathwayCard extends StatelessWidget {
  final int batchDay;
  final String language;
  final VoidCallback? onOpenPlan;

  const FlockPathwayCard({
    super.key,
    required this.batchDay,
    this.language = 'uz',
    this.onOpenPlan,
  });

  @override
  Widget build(BuildContext context) {
    final currentDay = batchDay.clamp(1, 42);
    final percent = ((currentDay / 42) * 100).toInt();

    // 4 major phases of the Ross-308 42-day cycle with real photographic thumbnails
    final phases = [
      const _PhaseInfo(
        phaseNumber: 1,
        titleUz: "Start",
        titleRu: "Старт",
        titleEn: "Starter",
        dayRange: "1–7",
        minDay: 1,
        maxDay: 7,
        imageAsset: 'assets/images/chick_starter.jpg',
        fallbackIcon: Icons.egg_outlined,
      ),
      const _PhaseInfo(
        phaseNumber: 2,
        titleUz: "O'sish",
        titleRu: "Рост",
        titleEn: "Grower",
        dayRange: "8–21",
        minDay: 8,
        maxDay: 21,
        imageAsset: 'assets/images/broiler_flock.jpg',
        fallbackIcon: Icons.eco_outlined,
      ),
      const _PhaseInfo(
        phaseNumber: 3,
        titleUz: "Finish",
        titleRu: "Финиш",
        titleEn: "Finisher",
        dayRange: "22–35",
        minDay: 22,
        maxDay: 35,
        imageAsset: 'assets/images/feed_grain.jpg',
        fallbackIcon: Icons.grain_outlined,
      ),
      const _PhaseInfo(
        phaseNumber: 4,
        titleUz: "Hosil",
        titleRu: "Убой",
        titleEn: "Harvest",
        dayRange: "36–42",
        minDay: 36,
        maxDay: 42,
        imageAsset: 'assets/images/field_aerial.jpg',
        fallbackIcon: Icons.military_tech_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Avatar Thumbnail & Progress Pill
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: Image.asset(
                  'assets/images/chick_starter.jpg',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 42,
                    height: 42,
                    color: AppTheme.amberSoft,
                    child: const Icon(Icons.egg_alt_rounded, color: AppTheme.goldWarm),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr(
                        lang: language,
                        uz: "$currentDay-kun / 42 kundan",
                        ru: "$currentDay-й день из 42",
                        en: "Day $currentDay of 42",
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentPhaseSummary(currentDay, language),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withAlpha(40),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$percent%",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreenDark,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Milestone Pathway Nodes Row with Image Avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(phases.length, (idx) {
              final phase = phases[idx];
              final isCurrent = currentDay >= phase.minDay && currentDay <= phase.maxDay;
              final isCompleted = currentDay > phase.maxDay;

              final phaseTitle = language == 'en'
                  ? phase.titleEn
                  : (language == 'ru' ? phase.titleRu : phase.titleUz);

              return Expanded(
                child: Column(
                  children: [
                    // Node circle with connecting line behind
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left & Right connectors
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 3.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: idx == 0
                                      ? Colors.transparent
                                      : (currentDay >= phase.minDay
                                          ? AppTheme.primaryGreen
                                          : const Color(0xFFE2EBE4)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: idx == phases.length - 1
                                      ? Colors.transparent
                                      : (currentDay > phase.maxDay
                                          ? AppTheme.primaryGreen
                                          : const Color(0xFFE2EBE4)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Circular Node Button with Photo Avatar
                        GestureDetector(
                          onTap: onOpenPlan,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isCurrent ? 48 : 40,
                            height: isCurrent ? 48 : 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFFF59E0B)
                                    : (isCompleted
                                        ? AppTheme.primaryGreen
                                        : AppTheme.cardBorder),
                                width: isCurrent ? 3 : 1.5,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withAlpha(120),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      phase.imageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: isCompleted
                                            ? AppTheme.primaryGreen
                                            : AppTheme.surfaceSubtle,
                                        child: Icon(
                                          phase.fallbackIcon,
                                          size: 18,
                                          color: isCompleted
                                              ? Colors.white
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isCompleted)
                                    Container(
                                      color: AppTheme.primaryGreenDark.withAlpha(180),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phaseTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent
                            ? const Color(0xFFB45309)
                            : AppTheme.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      phase.dayRange,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Actionable prompt to view day checklist with ultra-rounded pill style
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenPlan,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: AppTheme.cardBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.checklist_rounded,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.tr(
                                lang: language,
                                uz: "Kunlik parvarish rejasini ko'rish",
                                ru: "Открыть ежедневный план ухода",
                                en: "Open daily checklist & tasks",
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreenDark,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppTheme.primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPhaseSummary(int day, String lang) {
    if (day <= 7) {
      return AppStrings.tr(
        lang: lang,
        uz: "Start bosqichi: 32-34°C issiqlik va suvga o'rgatish",
        ru: "Стартовый период: 32-34°C и приучение к воде",
        en: "Starter phase: 32-34°C brooder and initial care",
      );
    } else if (day <= 21) {
      return AppStrings.tr(
        lang: lang,
        uz: "O'sish bosqichi: O'sish yemi va 27°C harorat",
        ru: "Период роста: Корм 'Рост' и 27°C температура",
        en: "Grower phase: Active growth feed & 27°C",
      );
    } else if (day <= 35) {
      return AppStrings.tr(
        lang: lang,
        uz: "Finish bosqichi: Vazn o'sishi va 21°C harorat",
        ru: "Финишный период: Контроль привеса и 21°C",
        en: "Finisher phase: Maximum weight gain & 21°C",
      );
    } else {
      return AppStrings.tr(
        lang: lang,
        uz: "Hosil bosqichi: So'yishga tayyorgarlik va kreditni yopish",
        ru: "Период убоя: Подготовка к реализации и закрытие кредита",
        en: "Harvest phase: Market sales & loan settlement",
      );
    }
  }
}

class _PhaseInfo {
  final int phaseNumber;
  final String titleUz;
  final String titleRu;
  final String titleEn;
  final String dayRange;
  final int minDay;
  final int maxDay;
  final String imageAsset;
  final IconData fallbackIcon;

  const _PhaseInfo({
    required this.phaseNumber,
    required this.titleUz,
    required this.titleRu,
    required this.titleEn,
    required this.dayRange,
    required this.minDay,
    required this.maxDay,
    required this.imageAsset,
    required this.fallbackIcon,
  });
}
