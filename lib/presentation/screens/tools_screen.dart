import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../domain/broiler/broiler_grower_library.dart';
import '../../services/farm_store.dart';
import '../ui/components.dart';
import '../ui/format.dart';

/// Calculators that use the farmer's own numbers: feed efficiency (FCR) from
/// the diary, expected profit at harvest, and equipment for the flock size.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _PriceField {
  final String key;
  final double fallback;
  final TextEditingController controller;

  _PriceField(this.key, this.fallback)
    : controller = TextEditingController(text: Fmt.num(fallback, decimals: 2));

  double get value =>
      double.tryParse(
        controller.text.replaceAll(',', '.').replaceAll(' ', ''),
      ) ??
      0;
}

class _ToolsScreenState extends State<ToolsScreen> {
  FarmSnapshot? _farm;

  final _weight = TextEditingController();
  final _feed = TextEditingController();

  // Prices are saved so the farmer only types local prices once.
  final _chickPrice = _PriceField('price_chick_uzs', 9000);
  final _feedPrice = _PriceField('price_feed_kg_uzs', 6200);
  final _livePrice = _PriceField('price_live_kg_uzs', 26000);
  final _otherCost = _PriceField('price_other_per_bird_uzs', 2500);
  final _loan = _PriceField('loan_amount_uzs', 0);

  List<_PriceField> get _prices => [
    _chickPrice,
    _feedPrice,
    _livePrice,
    _otherCost,
    _loan,
  ];

  String get _lang => _farm?.lang ?? 'uz';
  Fmt get _fmt => Fmt(_lang);
  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weight.dispose();
    _feed.dispose();
    for (final p in _prices) {
      p.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    final prefs = await SharedPreferences.getInstance();
    for (final p in _prices) {
      final saved = prefs.getDouble(p.key);
      if (saved != null) p.controller.text = Fmt.num(saved, decimals: 2);
    }
    if (farm.hasWeight) _weight.text = Fmt.num(farm.lastWeightG, decimals: 0);
    // Only pre-fill the feed total when the diary covers every day of the
    // batch — a partial total would give a falsely excellent FCR.
    final feedDays = farm.history.where((r) => r.feedKg > 0).length;
    if (feedDays >= farm.batchDay) _feed.text = Fmt.num(farm.totalFeedLoggedKg);
    if (!mounted) return;
    setState(() => _farm = farm);
  }

  Future<void> _savePrice(_PriceField field) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(field.key, field.value);
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Hisob-kitoblar', 'Калькуляторы', 'Calculators')),
      ),
      body: farm == null
          ? const LoadingView()
          : PageBody(
              children: [
                Reveal(
                  child: SectionHeader(
                    title: _t(
                      'Yem samaradorligi (FCR)',
                      'Конверсия корма (FCR)',
                      'Feed efficiency (FCR)',
                    ),
                  ),
                ),
                Reveal(index: 1, child: _buildFcr(farm)),
                const Gap(AppSpace.xl),
                Reveal(
                  index: 2,
                  child: SectionHeader(
                    title: _t(
                      'Kutilayotgan foyda',
                      'Ожидаемая прибыль',
                      'Expected profit',
                    ),
                  ),
                ),
                Reveal(index: 3, child: _buildProfit(farm)),
                const Gap(AppSpace.xl),
                Reveal(
                  index: 4,
                  child: SectionHeader(
                    title: _t(
                      'Uskunalar va joy',
                      'Оборудование и площадь',
                      'Equipment & space',
                    ),
                  ),
                ),
                Reveal(index: 5, child: _buildEquipment(farm)),
              ],
            ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String suffix, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      onChanged: (v) {
        onChanged?.call(v);
        setState(() {});
      },
    );
  }

  Widget _buildFcr(FarmSnapshot farm) {
    final weight = _parse(_weight);
    final feed = _parse(_feed);
    final ready = weight != null && weight > 0 && feed != null && feed > 0;
    final report = ready
        ? BroilerGrowerLibrary.evaluateEfficiency(
            batchDay: farm.batchDay,
            initialCount: farm.initialCount,
            currentCount: farm.currentCount,
            actualAverageWeightG: weight,
            totalFeedConsumedKg: feed,
          )
        : null;
    final feedDays = farm.history.where((r) => r.feedKg > 0).length;
    final missingDays = farm.batchDay - feedDays;
    // FCR = feed ÷ live weight. Far better than the day's target is not
    // biologically possible, so the inputs are incomplete — never grade it.
    final rawFcr = ready && farm.currentCount > 0
        ? feed / (farm.currentCount * weight / 1000)
        : null;
    final implausible = rawFcr != null &&
        !BroilerGrowerLibrary.isPlausibleFcr(day: farm.batchDay, fcr: rawFcr);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(
              "Bir kg tirik vazn uchun qancha yem ketganini ko'rsatadi. Qancha kichik bo'lsa, shuncha yaxshi.",
              'Показывает, сколько корма ушло на 1 кг живого веса. Чем меньше, тем лучше.',
              'Shows how much feed went into each kg of live weight. Lower is better.',
            ),
            style: AppText.bodyMuted,
          ),
          const Gap(AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  _weight,
                  _t("O'rtacha vazn", 'Средний вес', 'Average weight'),
                  _t('g', 'г', 'g'),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _numberField(
                  _feed,
                  _t('Jami berilgan yem', 'Всего корма', 'Total feed given'),
                  _t('kg', 'кг', 'kg'),
                ),
              ),
            ],
          ),
          if (missingDays > 0 && farm.totalFeedLoggedKg > 0) ...[
            const Gap(),
            Text(
              _t(
                "Kundalikda $feedDays kunlik yem bor (${_fmt.kg(farm.totalFeedLoggedKg)}), $missingDays kun yozilmagan. 1-kundan beri berilgan jami yemni kiriting.",
                'В дневнике корм за $feedDays дн. (${_fmt.kg(farm.totalFeedLoggedKg)}), $missingDays дн. не записано. Введите весь корм с 1-го дня.',
                'The diary has feed for $feedDays days (${_fmt.kg(farm.totalFeedLoggedKg)}); $missingDays days are missing. Enter all feed given since day 1.',
              ),
              style: AppText.caption.copyWith(color: AppColors.warning),
            ),
          ],
          const Gap(AppSpace.lg),
          if (implausible)
            NoticeBanner(
              tone: Tone.warning,
              icon: Icons.error_outline_rounded,
              title: 'FCR ${rawFcr.toStringAsFixed(2)}',
              message: _t(
                "Bu juda past — haqiqatda bo'lmaydi. Ehtimol, jami yem to'liq emas yoki vazn noto'g'ri. 1-kundan beri berilgan barcha yemni kiriting.",
                'Слишком низко — так не бывает. Скорее всего, учтён не весь корм или неверен вес. Введите весь корм с 1-го дня.',
                "That's too low to be real — the feed total is probably incomplete or the weight is off. Enter all feed given since day 1.",
              ),
            )
          else if (report == null)
            Text(
              _t(
                "Natijani ko'rish uchun vazn va yemni kiriting.",
                'Введите вес и корм, чтобы увидеть результат.',
                'Enter weight and feed to see the result.',
              ),
              style: AppText.caption,
            )
          else ...[
            MetricGrid(
              children: [
                TargetTile(
                  icon: Icons.analytics_rounded,
                  tone: report.actualFcr <= report.targetFcr * 1.05
                      ? Tone.primary
                      : Tone.warning,
                  label: 'FCR',
                  value: rawFcr!,
                  format: (v) => v.toStringAsFixed(2),
                  caption: _t(
                    "Me'yor: ${report.targetFcr.toStringAsFixed(2)}",
                    'Норма: ${report.targetFcr.toStringAsFixed(2)}',
                    'Target: ${report.targetFcr.toStringAsFixed(2)}',
                  ),
                ),
                TargetTile(
                  icon: Icons.emoji_events_rounded,
                  tone: report.grade == 'C' ? Tone.warning : Tone.primary,
                  label: 'EPEF',
                  value: report.epefScore.toDouble(),
                  format: (v) => '${v.round()}',
                  caption: _t(
                    'Baho: ${report.grade}',
                    'Оценка: ${report.grade}',
                    'Grade: ${report.grade}',
                  ),
                ),
              ],
            ),
            const Gap(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GradeBadge(grade: report.grade),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    report.gradeSummary(_lang),
                    style: AppText.bodyMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfit(FarmSnapshot farm) {
    final harvest = BroilerGrowerLibrary.specForDay(42);
    final harvestKg = harvest.targetWeightG / 1000;
    final feedPerBirdKg = harvest.cumulativeFeedPerBirdG / 1000;
    final birds = farm.currentCount;

    final revenue = birds * harvestKg * _livePrice.value;
    final chickCost = farm.initialCount * _chickPrice.value;
    // Feed for birds already lost is mostly not eaten; count the live flock.
    final feedCost = birds * feedPerBirdKg * _feedPrice.value;
    final otherCost = farm.initialCount * _otherCost.value;
    final costs = chickCost + feedCost + otherCost;
    final profit = revenue - costs;
    final afterLoan = profit - _loan.value;

    Widget priceField(_PriceField field, String label, String suffix) =>
        _numberField(
          field.controller,
          label,
          suffix,
          onChanged: (_) => _savePrice(field),
        );

    final som = _t("so'm", 'сум', 'UZS');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(
              "42-kunda ${_fmt.birds(birds)} × ${Fmt.num(harvestKg, decimals: 2)} kg sotilsa. O'z narxlaringizni kiriting.",
              'Если продать ${_fmt.birds(birds)} × ${Fmt.num(harvestKg, decimals: 2)} кг на 42-й день. Укажите свои цены.',
              'If ${_fmt.birds(birds)} are sold at ${Fmt.num(harvestKg, decimals: 2)} kg on day 42. Enter your local prices.',
            ),
            style: AppText.bodyMuted,
          ),
          const Gap(AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: priceField(
                  _livePrice,
                  _t('Tirik vazn 1 kg', 'Живой вес 1 кг', 'Live weight 1 kg'),
                  som,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: priceField(
                  _feedPrice,
                  _t('Yem 1 kg', 'Корм 1 кг', 'Feed 1 kg'),
                  som,
                ),
              ),
            ],
          ),
          const Gap(),
          Row(
            children: [
              Expanded(
                child: priceField(
                  _chickPrice,
                  _t("1 ta jo'ja", '1 цыплёнок', '1 chick'),
                  som,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: priceField(
                  _otherCost,
                  _t('Boshqa xarajat / bosh', 'Прочее / гол.', 'Other / bird'),
                  som,
                ),
              ),
            ],
          ),
          const Gap(),
          priceField(
            _loan,
            _t(
              'Kredit (ixtiyoriy)',
              'Кредит (необязательно)',
              'Loan (optional)',
            ),
            som,
          ),
          const Gap(AppSpace.lg),
          _ProfitCard(
            label: _t('Sof foyda', 'Чистая прибыль', 'Net profit'),
            amount: profit,
            format: _fmt.money,
            afterLoanLabel: _loan.value > 0
                ? _t(
                    'Kredit qaytarilgandan keyin',
                    'После погашения кредита',
                    'After repaying the loan',
                  )
                : null,
            afterLoan: afterLoan,
          ),
          const Gap(AppSpace.lg),
          _moneyRow(_t('Daromad', 'Выручка', 'Revenue'), revenue),
          const SizedBox(height: AppSpace.sm),
          _CostBar(
            revenue: revenue,
            parts: [
              (
                _t("Jo'jalar", 'Цыплята', 'Chicks'),
                chickCost,
                AppColors.sunDeep,
              ),
              (_t('Yem', 'Корм', 'Feed'), feedCost, AppColors.info),
              (_t('Boshqa', 'Прочее', 'Other'), otherCost, AppColors.primary),
            ],
            format: _fmt.money,
            costsLabel: _t('Xarajatlar', 'Расходы', 'Costs'),
          ),
          const Gap(),
          Text(
            _t(
              "Bu taxmin. Haqiqiy natija narxlar, nobudlik va vaznga bog'liq.",
              'Это оценка. Реальный итог зависит от цен, падежа и веса.',
              'This is an estimate. The real result depends on prices, losses and weight.',
            ),
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(
    String label,
    double amount, {
    String? detail,
    bool strong = false,
  }) {
    final color = amount < 0 && strong ? AppColors.danger : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: strong ? AppText.cardTitle : AppText.body),
                if (detail != null) Text(detail, style: AppText.caption),
              ],
            ),
          ),
          Text(
            _fmt.money(amount),
            style: (strong ? AppText.cardTitle : AppText.body).copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipment(FarmSnapshot farm) {
    final req = farm.requirements;
    return MetricGrid(
      children: [
        TargetTile(
          icon: Icons.water_drop_rounded,
          tone: Tone.info,
          label: _t(
            'Nippel ichgichlar',
            'Ниппельные поилки',
            'Nipple drinkers',
          ),
          value: req.recommendedNipples.toDouble(),
          format: (v) => '${v.round()}',
          caption: _t("11 ta jo'jaga 1 ta", '1 на 11 птиц', '1 per 11 birds'),
        ),
        TargetTile(
          icon: Icons.grain_rounded,
          tone: Tone.warning,
          label: _t('Yemdonlar', 'Кормушки', 'Feeder pans'),
          value: req.recommendedFeederPans.toDouble(),
          format: (v) => '${v.round()}',
          caption: _t("50 ta jo'jaga 1 ta", '1 на 50 птиц', '1 per 50 birds'),
        ),
        TargetTile(
          icon: Icons.square_foot_rounded,
          tone: Tone.neutral,
          label: _t('Hozir kerakli joy', 'Площадь сейчас', 'Space needed now'),
          value: req.requiredBarnAreaCurrentSqM,
          format: (v) => '${Fmt.num(v, decimals: 0)} m²',
          caption: _fmt.day(farm.batchDay),
        ),
        TargetTile(
          icon: Icons.open_in_full_rounded,
          tone: Tone.primary,
          label: _t('42-kunda', 'К 42-му дню', 'By day 42'),
          value: req.requiredBarnAreaHarvestSqM,
          format: (v) => '${Fmt.num(v, decimals: 0)} m²',
          caption: _t("so'yishga", 'к убою', 'at harvest'),
        ),
      ],
    );
  }
}

/// Big round A / B / C grade.
class _GradeBadge extends StatelessWidget {
  final String grade;

  const _GradeBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    final color = switch (grade) {
      'A' => AppColors.primary,
      'B' => AppColors.info,
      _ => AppColors.gold,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: AppShadow.glow(color),
      ),
      child: Center(
        child: Text(
          grade,
          style: AppText.metric.copyWith(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}

/// Net profit on green (or red for a loss), counting up as prices change.
class _ProfitCard extends StatelessWidget {
  final String label;
  final double amount;
  final String Function(double) format;
  final String? afterLoanLabel;
  final double afterLoan;

  const _ProfitCard({
    required this.label,
    required this.amount,
    required this.format,
    required this.afterLoanLabel,
    required this.afterLoan,
  });

  @override
  Widget build(BuildContext context) {
    final loss = amount < 0;
    final color = loss ? AppColors.danger : AppColors.primary;
    return AnimatedContainer(
      duration: AppMotion.medium,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
        boxShadow: AppShadow.glow(color),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(56),
              shape: BoxShape.circle,
            ),
            child: Icon(
              loss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUpText(
                    value: amount,
                    format: format,
                    style: AppText.display.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                ),
                if (afterLoanLabel != null)
                  Text(
                    '$afterLoanLabel: ${format(afterLoan)}',
                    style: AppText.caption.copyWith(
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the money goes: costs as one stacked bar (scaled to revenue), with
/// a labelled legend row per part — colour is never the only cue.
/// Palette (sunDeep / info / primary) passes the dataviz validator.
class _CostBar extends StatelessWidget {
  final double revenue;
  final List<(String, double, Color)> parts;
  final String Function(double) format;
  final String costsLabel;

  const _CostBar({
    required this.revenue,
    required this.parts,
    required this.format,
    required this.costsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = parts.fold(0.0, (a, p) => a + p.$2);
    final scale = math.max(revenue, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(costsLabel, style: AppText.body)),
            Text(format(-total), style: AppText.body),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.surfaceMuted),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        AnimatedContainer(
                          duration: AppMotion.medium,
                          curve: AppMotion.curve,
                          width: scale > 0
                              ? box.maxWidth * parts[i].$2 / scale
                              : 0,
                          // 2 px surface gap between segments.
                          margin: EdgeInsets.only(
                            right: i < parts.length - 1 ? 2 : 0,
                          ),
                          color: parts[i].$3,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(p.$1, style: AppText.caption)),
                Text(
                  Fmt.grouped(p.$2),
                  style: AppText.caption.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
