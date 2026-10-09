import 'package:flutter/material.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLoanSafe ? const Color(0xFF2D7A4C).withAlpha(50) : Colors.orange.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A338).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFFB8781B),
                    size: 22,
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
                          uz: "Agrokredit va Kutilayotgan Foyda",
                          ru: "Агрокредит и Прогноз прибыли",
                          en: "Bank Loan & Profit Forecast",
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        AppStrings.tr(
                          lang: language,
                          uz: "Agrobank / Xalq banki imtiyozli krediti",
                          ru: "Расчёт окупаемости банковского кредита",
                          en: "Loan repayment feasibility indicator",
                        ),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLoanSafe ? const Color(0xFFEAF5ED) : const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLoanSafe ? Icons.check_circle : Icons.warning_rounded,
                        color: isLoanSafe ? const Color(0xFF2D7A4C) : const Color(0xFFE5A338),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLoanSafe
                            ? AppStrings.tr(lang: language, uz: "Xavfsiz", ru: "В норме", en: "Safe")
                            : AppStrings.tr(lang: language, uz: "Diqqat", ru: "Риск", en: "Caution"),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLoanSafe ? const Color(0xFF2D7A4C) : const Color(0xFFB8781B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Financial Metrics Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinancialItem(
                      label: AppStrings.tr(lang: language, uz: "Bank krediti", ru: "Кредит", en: "Bank Loan"),
                      value: "${(bankLoanUz / 1000000).toStringAsFixed(1)} mln",
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildFinancialItem(
                      label: AppStrings.tr(lang: language, uz: "Kutilayotgan tushum", ru: "Выручка (42d)", en: "Gross Value"),
                      value: "${(totalEstimatedRevenue / 1000000).toStringAsFixed(1)} mln",
                      color: const Color(0xFF2D7A4C),
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildFinancialItem(
                      label: AppStrings.tr(lang: language, uz: "Sof foyda", ru: "Чистая прибыль", en: "Net Profit"),
                      value: "${netAfterLoanPayoff >= 0 ? '+' : ''}${(netAfterLoanPayoff / 1000000).toStringAsFixed(1)} mln",
                      color: netAfterLoanPayoff >= 0 ? const Color(0xFF2D7A4C) : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Encouragement message with vector icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isLoanSafe ? Icons.check_circle_outline : Icons.info_outline,
                  size: 15,
                  color: isLoanSafe ? Colors.green.shade800 : Colors.deepOrange.shade800,
                ),
                const SizedBox(width: 6),
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
                      color: isLoanSafe ? Colors.green.shade900 : Colors.deepOrange.shade800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
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
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
