import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import 'agro_icons.dart';

/// A Duolingo-inspired 42-Day Milestone Pathway card that visualizes the flock
/// growth cycle as an engaging step-by-step roadmap rather than a boring progress bar.
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

    // 4 major phases of the Ross-308 42-day cycle
    final phases = [
      _PhaseInfo(
        phaseNumber: 1,
        titleUz: "Start",
        titleRu: "Старт",
        titleEn: "Starter",
        dayRange: "1–7",
        minDay: 1,
        maxDay: 7,
        icon: Icons.egg_outlined,
      ),
      _PhaseInfo(
        phaseNumber: 2,
        titleUz: "O'sish",
        titleRu: "Рост",
        titleEn: "Grower",
        dayRange: "8–21",
        minDay: 8,
        maxDay: 21,
        icon: Icons.eco_outlined,
      ),
      _PhaseInfo(
        phaseNumber: 3,
        titleUz: "Finish",
        titleRu: "Финиш",
        titleEn: "Finisher",
        dayRange: "22–35",
        minDay: 22,
        maxDay: 35,
        icon: Icons.grain_outlined,
      ),
      _PhaseInfo(
        phaseNumber: 4,
        titleUz: "Hosil",
        titleRu: "Убой",
        titleEn: "Harvest",
        dayRange: "36–42",
        minDay: 36,
        maxDay: 42,
        icon: Icons.military_tech_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D7A4C).withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with AgroChickIcon
          Row(
            children: [
              const AgroChickIcon(size: 34),
              const SizedBox(width: 10),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getCurrentPhaseSummary(currentDay, language),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$percent%",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D7A4C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Milestone Pathway Nodes Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(phases.length, (idx) {
              final phase = phases[idx];
              final isCurrent = currentDay >= phase.minDay && currentDay <= phase.maxDay;
              final isCompleted = currentDay > phase.maxDay;

              final phaseTitle = language == 'en'
                  ? phase.titleEn
                  : (language == 'ru' ? phase.titleRu : phase.titleUz);

              final Color nodeBg = isCompleted
                  ? const Color(0xFF2D7A4C)
                  : (isCurrent ? const Color(0xFFE5A338) : Colors.grey.shade100);

              final Color nodeFg = (isCompleted || isCurrent) ? Colors.white : Colors.grey.shade600;

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
                                height: 4,
                                color: idx == 0
                                    ? Colors.transparent
                                    : (currentDay >= phase.minDay
                                        ? const Color(0xFF2D7A4C)
                                        : Colors.grey.shade200),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 4,
                                color: idx == phases.length - 1
                                    ? Colors.transparent
                                    : (currentDay > phase.maxDay
                                        ? const Color(0xFF2D7A4C)
                                        : Colors.grey.shade200),
                              ),
                            ),
                          ],
                        ),
                        // Circular Node Button
                        GestureDetector(
                          onTap: onOpenPlan,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isCurrent ? 44 : 36,
                            height: isCurrent ? 44 : 36,
                            decoration: BoxDecoration(
                              color: nodeBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCurrent ? const Color(0xFFB8781B) : Colors.transparent,
                                width: isCurrent ? 2.5 : 0,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFE5A338).withAlpha(100),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                isCompleted ? Icons.check_rounded : phase.icon,
                                size: isCurrent ? 22 : 18,
                                color: nodeFg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phaseTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? const Color(0xFFB8781B) : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      phase.dayRange,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Actionable prompt to view day checklist
          InkWell(
            onTap: onOpenPlan,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded, size: 16, color: Color(0xFF2D7A4C)),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.tr(
                          lang: language,
                          uz: "Kunlik parvarish rejasini ko'rish",
                          ru: "Открыть ежедневный план ухода",
                          en: "Open daily checklist & tasks",
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D7A4C),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2D7A4C)),
                ],
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
  final IconData icon;

  const _PhaseInfo({
    required this.phaseNumber,
    required this.titleUz,
    required this.titleRu,
    required this.titleEn,
    required this.dayRange,
    required this.minDay,
    required this.maxDay,
    required this.icon,
  });
}
