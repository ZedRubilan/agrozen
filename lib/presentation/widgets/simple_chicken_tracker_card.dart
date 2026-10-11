import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../domain/broiler/broiler_grower_library.dart';

/// Ultra-simple, non-overwhelming 1-tap Chicken Tracker & Categorizer Card.
///
/// Gives the farmer a single calm place to see and categorize their chickens:
/// 1. 🟢 **Healthy & Active** (`currentCount - isolatedCount`)
/// 2. 🟡 **Watchlist / Under Observation** (`isolatedCount` — weak/small birds with `-` / `+` 1-tap buttons)
/// 3. 🔴 **Lost Today** (`todayMortality` — with quick `+1` or full log)
/// Plus today's essential **Feed** and **Weight** progress with 1-tap quick actions.
class SimpleChickenTrackerCard extends StatelessWidget {
  final int batchDay;
  final int initialCount;
  final int currentCount;
  final int isolatedCount;
  final int todayMortality;
  final double todayFeedKg;
  final double lastWeightG;
  final String language;
  final ValueChanged<int> onUpdateIsolatedCount;
  final VoidCallback onQuickAddMortality;
  final VoidCallback onOpenLogMortality;
  final VoidCallback onOpenLogFeed;
  final VoidCallback onOpenLogWeight;
  final VoidCallback? onScanChickenPhoto;

  const SimpleChickenTrackerCard({
    super.key,
    required this.batchDay,
    required this.initialCount,
    required this.currentCount,
    required this.isolatedCount,
    required this.todayMortality,
    required this.todayFeedKg,
    required this.lastWeightG,
    required this.language,
    required this.onUpdateIsolatedCount,
    required this.onQuickAddMortality,
    required this.onOpenLogMortality,
    required this.onOpenLogFeed,
    required this.onOpenLogWeight,
    this.onScanChickenPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final int safeIsolated = isolatedCount.clamp(0, max(0, currentCount)).toInt();
    final int healthyCount = max(0, currentCount - safeIsolated);
    final req = BroilerGrowerLibrary.calculateFlockRequirements(
      day: batchDay,
      birdCount: currentCount,
    );
    final daySpec = BroilerGrowerLibrary.specForDay(batchDay);
    final targetFeedKg = req.totalDailyFeedKg;
    final targetWeightG = daySpec.targetWeightG.round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.checklist_rtl_rounded,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr(
                        lang: language,
                        uz: "Jo'jalar hisobi va toifalari",
                        ru: 'Учёт и категории цыплят',
                        en: 'Chicken Tracker & Categories',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      AppStrings.tr(
                        lang: language,
                        uz: "1-bosishda holatni belgilang",
                        ru: 'Быстрая сортировка стада в 1 нажатие',
                        en: 'Categorize your flock in 1 tap',
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$currentCount / $initialCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Flock Categories Row: Healthy | Watchlist (Isolated) | Lost Today
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Healthy & Active
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              AppStrings.tr(
                                lang: language,
                                uz: "Sog'lom",
                                ru: 'Здоровые',
                                en: 'Healthy',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$healthyCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF14532D),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr(
                          lang: language,
                          uz: 'Faol to\'dada',
                          ru: 'В общем стаде',
                          en: 'Active flock',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Watchlist / Isolated (Weak or Small) with - / + buttons
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              AppStrings.tr(
                                lang: language,
                                uz: 'Kuzatuvda',
                                ru: 'В изоляторе',
                                en: 'Watchlist',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$safeIsolated',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF78350F),
                              height: 1.05,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMiniStepBtn(
                                label: '−',
                                color: const Color(0xFFFDE68A),
                                textColor: const Color(0xFF92400E),
                                onTap: safeIsolated > 0
                                    ? () =>
                                        onUpdateIsolatedCount(safeIsolated - 1)
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              _buildMiniStepBtn(
                                label: '+',
                                color: const Color(0xFFD97706),
                                textColor: Colors.white,
                                onTap: safeIsolated < currentCount
                                    ? () =>
                                        onUpdateIsolatedCount(safeIsolated + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr(
                          lang: language,
                          uz: 'Holsiz / kichik',
                          ru: 'Слабые / мелкие',
                          en: 'Weak / small',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Lost Today (Mortality) with +1 or log
              Expanded(
                child: GestureDetector(
                  onTap: onOpenLogMortality,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                AppStrings.tr(
                                  lang: language,
                                  uz: 'Bugun nobod',
                                  ru: 'Падёж',
                                  en: 'Lost Today',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$todayMortality',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7F1D1D),
                                height: 1.05,
                              ),
                            ),
                            _buildMiniStepBtn(
                              label: '+1',
                              color: const Color(0xFFFECACA),
                              textColor: const Color(0xFF991B1B),
                              onTap: currentCount > 0
                                  ? onQuickAddMortality
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.tr(
                            lang: language,
                            uz: 'Yozish uchun bosing',
                            ru: 'Нажмите для лога',
                            en: 'Tap to log',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compact Essential Feed & Weight Row
          Row(
            children: [
              Expanded(
                child: _buildQuickCarePill(
                  icon: Icons.grain_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: AppStrings.tr(
                    lang: language,
                    uz: 'Bugungi yem',
                    ru: 'Корм сегодня',
                    en: "Today's Feed",
                  ),
                  valueText:
                      '${todayFeedKg.toStringAsFixed(1)} / ${targetFeedKg.toStringAsFixed(0)} kg',
                  actionLabel: AppStrings.tr(
                    lang: language,
                    uz: '+ Yozish',
                    ru: '+ Внести',
                    en: '+ Log',
                  ),
                  onTap: onOpenLogFeed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickCarePill(
                  icon: Icons.scale_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: AppStrings.tr(
                    lang: language,
                    uz: "O'rtacha vazn",
                    ru: 'Средний вес',
                    en: 'Avg Weight',
                  ),
                  valueText:
                      '${lastWeightG > 0 ? lastWeightG.toInt() : "—"} / $targetWeightG g',
                  actionLabel: AppStrings.tr(
                    lang: language,
                    uz: '+ O\'lchash',
                    ru: '+ Вес',
                    en: '+ Weigh',
                  ),
                  onTap: onOpenLogWeight,
                ),
              ),
            ],
          ),

          // 1-Tap AI Photo Check Button
          if (onScanChickenPhoto != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onScanChickenPhoto,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_enhance_rounded,
                      size: 18,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.tr(
                          lang: language,
                          uz: "Jo'jani rasmga olib tekshirish (Gemini AI)",
                          ru: 'Проверить цыплёнка по фото (Gemini AI)',
                          en: 'Scan Chicken Photo with Gemini AI',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStepBtn({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCarePill({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String valueText,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
