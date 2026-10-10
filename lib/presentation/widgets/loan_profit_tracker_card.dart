import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';

/// Card showing the farmer's Bank Loan Repayment & Projected Net Profit.
/// Connects daily flock management directly to financial security and debt payoff.
class LoanProfitTrackerCard extends StatelessWidget {
  final int currentCount;
  final int initialCount;
  final int batchDay;
  final String language;
  final double bankLoanUz; // e.g. 15,000,000 UZS

  const LoanProfitTrackerCard({
    super.key,
    required this.currentCount,
    required this.initialCount,
    required this.batchDay,
    this.language = 'uz',
    this.bankLoanUz = 15000000.0,
  });

  @override
  Widget build(BuildContext context) {
    // Projected calculations for Ross-308 harvest at day 42
    // Average harvest weight: ~2.7 kg
    // Market price per kg live bird in Uzbekistan: ~26,000 UZS
    const double harvestWeightKg = 2.7;
    const double livePricePerKg = 26000.0;
    // Total cumulative feed consumed per bird across 42 days: ~4.3 kg @ 6,200 UZS/kg
    const double feedCostPerBird = 4.3 * 6200.0;
    // Chick purchase cost: ~9,000 UZS
    const double chickCost = 9000.0;
    // Misc veterinary & heating costs: ~2,500 UZS
    const double miscCostPerBird = 2500.0;

    final double totalEstimatedRevenue = currentCount * harvestWeightKg * livePricePerKg;
    final double totalFlockExpenses = currentCount * (feedCostPerBird + chickCost + miscCostPerBird);
    final double projectedNetProfit = totalEstimatedRevenue - totalFlockExpenses;
    final double netAfterLoanPayoff = projectedNetProfit - bankLoanUz;

    final bool isLoanSafe = totalEstimatedRevenue > (bankLoanUz + totalFlockExpenses * 0.7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isLoanSafe ? AppTheme.cardBorder : const Color(0xFFFDBA74),
          width: 1.0,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.amberSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.secondaryAmber.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFB8781B),
                      size: 22,
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
                          uz: "Agrokredit va Kutilayotgan Foyda",
                          ru: "Агрокредит и Прогноз прибыли",
                          en: "Bank Loan & Profit Forecast",
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.tr(
                          lang: language,
                          uz: "Agrobank / Xalq banki imtiyozli krediti",
                          ru: "Расчёт окупаемости банковского кредита",
                          en: "Loan repayment feasibility indicator",
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLoanSafe ? AppTheme.emeraldSoft : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: isLoanSafe
                          ? AppTheme.primaryGreen.withAlpha(40)
                          : const Color(0xFFF97316).withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLoanSafe ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: isLoanSafe ? AppTheme.primaryGreenDark : const Color(0xFFC2410C),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLoanSafe
                            ? AppStrings.tr(lang: language, uz: "Xavfsiz", ru: "В норме", en: "Safe")
                            : AppStrings.tr(lang: language, uz: "Diqqat", ru: "Риск", en: "Caution"),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isLoanSafe ? AppTheme.primaryGreenDark : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial Metrics Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.cardBorder, width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinancialItem(
                      label: AppStrings.tr(lang: language, uz: "Bank krediti", ru: "Кредит", en: "Bank Loan"),
                      value: "${(bankLoanUz / 1000000).toStringAsFixed(1)} mln",
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppTheme.cardBorder),
                  Expanded(
                    child: _buildFinancialItem(
                      label: AppStrings.tr(lang: language, uz: "Kutilayotgan tushum", ru: "Выручка (42d)", en: "Gross Value"),
                      value: "${(totalEstimatedRevenue / 1000000).toStringAsFixed(1)} mln",
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppTheme.cardBorder),
                  Expanded(
                    child: _buildFinancialItem(
                      label: AppStrings.tr(lang: language, uz: "Sof foyda", ru: "Чистая прибыль", en: "Net Profit"),
                      value: "${netAfterLoanPayoff >= 0 ? '+' : ''}${(netAfterLoanPayoff / 1000000).toStringAsFixed(1)} mln",
                      color: netAfterLoanPayoff >= 0 ? AppTheme.primaryGreenDark : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Encouragement message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isLoanSafe ? AppTheme.emeraldSoft.withAlpha(160) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: isLoanSafe ? AppTheme.primaryGreen.withAlpha(25) : const Color(0xFFFDBA74).withAlpha(60),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isLoanSafe ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: isLoanSafe ? AppTheme.primaryGreenDark : const Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      isLoanSafe
                          ? AppStrings.tr(
                              lang: language,
                              uz: "Parvarish me'yorda borsa, bank krediti to'liq yopiladi va rejadagi foyda kafolatlanadi.",
                              ru: "При соблюдении норм ухода кредит полностью окупается и выходит в стабильную прибыль.",
                              en: "Standard flock care guarantees 100% bank debt coverage and healthy profit margins.",
                            )
                          : AppStrings.tr(
                              lang: language,
                              uz: "Nobodlikni kamaytiring — har bir yo'qotilgan jo'ja kutilayotgan foydani kamaytiradi.",
                              ru: "Берегите поголовье — каждый сохранённый цыплёнок защищает вашу кредитную прибыль.",
                              en: "Minimize mortality — every bird saved directly protects your net debt repayment margin.",
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLoanSafe ? AppTheme.primaryGreenDark : const Color(0xFF9A3412),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
