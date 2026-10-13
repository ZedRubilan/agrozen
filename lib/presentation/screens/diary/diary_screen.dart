import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../domain/alerts/alert_models.dart';
import '../../../domain/broiler/broiler_grower_library.dart';
import '../../../services/farm_store.dart';
import '../../ui/components.dart';
import '../../ui/format.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/growth_chart_card.dart';

/// Diary tab: record today's numbers, see how the batch is doing, the growth
/// curve against the target, and every previous day of the batch.
class DiaryScreen extends StatefulWidget {
  final bool isEmbeddedInPageView;

  const DiaryScreen({super.key, this.isEmbeddedInPageView = false});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  FarmSnapshot? _farm;
  List<AlertResult> _alerts = const [];
  Map<String, dynamic>? _vet;

  String get _lang => _farm?.lang ?? 'uz';
  Fmt get _fmt => Fmt(_lang);
  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    FarmStore.changes.addListener(_load);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First load needs the app locale, which is only readable from here.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    FarmStore.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load(
      localeFallback: Localizations.maybeLocaleOf(context)?.languageCode,
    );
    final alerts = await FarmStore.evaluateAlerts(farm);
    final vet = await FarmStore.vetFor(farm.district);
    if (!mounted) return;
    setState(() {
      _farm = farm;
      _alerts = alerts;
      _vet = vet;
    });
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) _load();
  }

  Future<void> _changeIsolated(int delta) async {
    final farm = _farm;
    if (farm == null) return;
    final next = (farm.isolatedCount + delta).clamp(0, farm.currentCount);
    await FarmStore.setIsolated(next);
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    var section = 0;
    Widget reveal(Widget child) => Reveal(index: section++, child: child);

    final body = farm == null
        ? const LoadingView()
        : PageBody(
            onRefresh: _load,
            children: [
              reveal(
                PageHeader(
                  title: _t(
                    'Partiya kundaligi',
                    'Дневник партии',
                    'Flock diary',
                  ),
                  subtitle: _t(
                    "Har kuni yozing — muammolar erta ko'rinadi",
                    'Записывайте каждый день — проблемы видны раньше',
                    'Log every day — problems show up early',
                  ),
                ),
              ),
              for (final alert in _alerts) ...[
                reveal(
                  AlertCard.fromAlertResult(
                    alert: alert,
                    locale: _lang,
                    vetPhone: _vet?['phone']?.toString(),
                    vetName: _vet?['name']?.toString(),
                  ),
                ),
                const Gap(),
              ],
              reveal(SectionHeader(title: _t('Bugun', 'Сегодня', 'Today'))),
              ..._buildToday(farm).map(reveal),
              const Gap(AppSpace.xl),
              reveal(
                SectionHeader(
                  title: _t('Partiya bo\'yicha', 'За всю партию', 'This batch'),
                ),
              ),
              reveal(_buildBatchSummary(farm)),
              const Gap(AppSpace.xl),
              reveal(SectionHeader(title: _t("O'sish", 'Рост', 'Growth'))),
              reveal(
                GrowthChartCard(
                  weighings: _weighings(farm),
                  batchDay: farm.batchDay,
                  lang: _lang,
                ),
              ),
              const Gap(AppSpace.xl),
              reveal(
                SectionHeader(
                  title: _t("Kunlar bo'yicha", 'По дням', 'Day by day'),
                ),
              ),
              reveal(_buildHistory(farm)),
            ],
          );

    if (widget.isEmbeddedInPageView) return body;
    return Scaffold(appBar: AppBar(), body: body);
  }

  /// Batch day → sample weight, from the history plus the latest weighing.
  Map<int, double> _weighings(FarmSnapshot farm) {
    final out = <int, double>{
      for (final r in farm.history)
        if (r.weightG != null) r.day: r.weightG!,
    };
    final lastDay = farm.lastWeightDay;
    if (farm.hasWeight && lastDay != null) {
      out.putIfAbsent(lastDay, () => farm.lastWeightG);
    }
    return out;
  }

  List<Widget> _buildToday(FarmSnapshot farm) {
    final req = farm.requirements;
    return [
      _RecordCard(
        icon: Icons.heart_broken_rounded,
        tone: Tone.danger,
        title: _t('Nobodlik yozish', 'Записать падёж', 'Record deaths'),
        subtitle: _t(
          'Bugun: ${farm.todayDeaths} bosh',
          'Сегодня: ${farm.todayDeaths} гол.',
          'Today: ${farm.todayDeaths} birds',
        ),
        onTap: () => _open('/diary/mortality'),
      ),
      const Gap(),
      _RecordCard(
        icon: Icons.grain_rounded,
        tone: Tone.warning,
        title: _t('Yem sarfini yozish', 'Записать корм', 'Record feed'),
        subtitle: _t(
          "Bugun: ${_fmt.kg(farm.todayFeedKg)} · me'yor ${_fmt.kg(req.totalDailyFeedKg)}",
          'Сегодня: ${_fmt.kg(farm.todayFeedKg)} · норма ${_fmt.kg(req.totalDailyFeedKg)}',
          'Today: ${_fmt.kg(farm.todayFeedKg)} · target ${_fmt.kg(req.totalDailyFeedKg)}',
        ),
        progress: req.totalDailyFeedKg > 0
            ? farm.todayFeedKg / req.totalDailyFeedKg
            : null,
        onTap: () => _open('/diary/feed'),
      ),
      const Gap(),
      _RecordCard(
        icon: Icons.scale_rounded,
        tone: Tone.info,
        title: _t('Nazorat vaznini yozish', 'Записать вес', 'Record weight'),
        subtitle: farm.hasWeight
            ? _t(
                "Oxirgi: ${_fmt.grams(farm.lastWeightG)} · me'yor ${_fmt.grams(farm.targetForLastWeight)}",
                'Последний: ${_fmt.grams(farm.lastWeightG)} · норма ${_fmt.grams(farm.targetForLastWeight)}',
                'Last: ${_fmt.grams(farm.lastWeightG)} · target ${_fmt.grams(farm.targetForLastWeight)}',
              )
            : _t(
                "Me'yor: ${_fmt.grams(farm.spec.targetWeightG)}",
                'Норма: ${_fmt.grams(farm.spec.targetWeightG)}',
                'Target: ${_fmt.grams(farm.spec.targetWeightG)}',
              ),
        onTap: () => _open('/diary/weight'),
      ),
      const Gap(),
      _RecordCard(
        icon: Icons.visibility_rounded,
        tone: Tone.neutral,
        title: _t('Kuzatuvda', 'Под наблюдением', 'Under watch'),
        subtitle: _t(
          "Kuchsiz yoki kasal, alohida saqlanayotgan jo'jalar",
          'Слабые или больные, содержатся отдельно',
          'Weak or sick birds kept apart',
        ),
        trailing: _Stepper(
          value: farm.isolatedCount,
          onMinus: farm.isolatedCount > 0 ? () => _changeIsolated(-1) : null,
          onPlus: farm.isolatedCount < farm.currentCount
              ? () => _changeIsolated(1)
              : null,
        ),
      ),
    ];
  }

  /// Survival ring + alive count, then lost / feed / days recorded.
  Widget _buildBatchSummary(FarmSnapshot farm) {
    final loggedDays = farm.history.length;
    final lostHigh = farm.cumulativeMortalityPct > 4;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                value: farm.survivalPct / 100,
                size: 96,
                stroke: 10,
                color: lostHigh ? AppColors.danger : AppColors.primary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountUpText(
                      value: farm.survivalPct,
                      format: (v) => '${Fmt.num(v)}%',
                      style: AppText.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _t('saqlanish', 'сохранность', 'survival'),
                      style: AppText.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _t('Tirik', 'Живых', 'Alive'),
                          style: AppText.caption,
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CountUpText(
                        value: farm.currentCount.toDouble(),
                        format: Fmt.grouped,
                        style: AppText.display,
                      ),
                    ),
                    Text(
                      _t(
                        '${Fmt.grouped(farm.initialCount.toDouble())} tadan',
                        'из ${Fmt.grouped(farm.initialCount.toDouble())}',
                        'of ${Fmt.grouped(farm.initialCount.toDouble())}',
                      ),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpace.md),
          IntrinsicHeight(
            child: Row(
              children: [
                _SummaryStat(
                  icon: Icons.heart_broken_rounded,
                  tone: lostHigh ? Tone.danger : Tone.neutral,
                  label: _t('Jami nobud', 'Всего падёж', 'Total lost'),
                  value: farm.totalDeaths.toDouble(),
                  format: (v) => '${v.round()}',
                  caption: '${Fmt.num(farm.cumulativeMortalityPct)}%',
                ),
                const VerticalDivider(width: AppSpace.lg),
                _SummaryStat(
                  icon: Icons.grain_rounded,
                  tone: Tone.warning,
                  label: _t('Jami yem', 'Всего корма', 'Total feed'),
                  value: farm.totalFeedLoggedKg,
                  format: _fmt.kg,
                ),
                const VerticalDivider(width: AppSpace.lg),
                _SummaryStat(
                  icon: Icons.event_available_rounded,
                  tone: Tone.info,
                  label: _t(
                    'Yozilgan kunlar',
                    'Дней с записями',
                    'Days recorded',
                  ),
                  value: loggedDays.toDouble(),
                  format: (v) => '${v.round()}/${farm.batchDay}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(FarmSnapshot farm) {
    if (farm.history.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const IconBadge(icon: Icons.history_rounded, tone: Tone.neutral),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                _t(
                  "Hali yozuv yo'q. Bugungi o'lim, yem yoki vaznni yozing — shu yerda kunma-kun ko'rinadi.",
                  'Записей пока нет. Запишите падёж, корм или вес — они появятся здесь по дням.',
                  'Nothing recorded yet. Log deaths, feed or weight and they will appear here day by day.',
                ),
                style: AppText.bodyMuted,
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (final record in farm.history) {
      rows.add(_HistoryRow(record: record, farm: farm, fmt: _fmt));
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// One "record" action: solid disc, what it is, today's value, big plus.
class _RecordCard extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String title;
  final String subtitle;
  final double? progress;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _RecordCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    this.progress,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone.solid;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: AppShadow.glow(color),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption),
                if (progress != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  AppProgressBar(
                    value: progress!,
                    color: progress! >= 1 ? AppColors.primary : color,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          trailing ??
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String label;
  final double value;
  final String Function(double) format;
  final String? caption;

  const _SummaryStat({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    required this.format,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, tone: tone, size: 30),
          const SizedBox(height: AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                CountUpText(
                  value: value,
                  format: format,
                  style: AppText.metric.copyWith(fontSize: 19),
                ),
                if (caption != null) ...[
                  const SizedBox(width: 3),
                  Text(caption!, style: AppText.caption),
                ],
              ],
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _Stepper({required this.value, this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap) => SizedBox(
      width: 36,
      height: 36,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove_rounded, onMinus),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppText.cardTitle,
          ),
        ),
        button(Icons.add_rounded, onPlus),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final DayRecord record;
  final FarmSnapshot farm;
  final Fmt fmt;

  const _HistoryRow({
    required this.record,
    required this.farm,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final spec = BroilerGrowerLibrary.specForDay(record.day);
    final targetFeedKg = spec.dailyFeedPerBirdG * farm.currentCount / 1000;
    final date = DateTime.tryParse(record.date);

    final deathsHigh =
        record.deaths > 0 &&
        record.deaths * 100 / (farm.currentCount + record.deaths) > 1;
    final feedLow = record.feedKg > 0 && record.feedKg < targetFeedKg * 0.8;
    final weightLow =
        record.weightG != null && record.weightG! < spec.targetWeightG * 0.85;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmt.day(record.day), style: AppText.label),
                if (date != null)
                  Text(
                    DateFormat('dd.MM').format(date),
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
          Expanded(
            child: _HistoryValue(
              icon: Icons.heart_broken_outlined,
              text: record.deaths > 0 ? '${record.deaths}' : '—',
              tone: deathsHigh ? Tone.danger : Tone.neutral,
            ),
          ),
          Expanded(
            child: _HistoryValue(
              icon: Icons.grain_rounded,
              text: record.feedKg > 0 ? fmt.kg(record.feedKg) : '—',
              tone: feedLow ? Tone.warning : Tone.neutral,
            ),
          ),
          Expanded(
            child: _HistoryValue(
              icon: Icons.scale_rounded,
              text: record.weightG != null ? fmt.grams(record.weightG!) : '—',
              tone: weightLow ? Tone.warning : Tone.neutral,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryValue extends StatelessWidget {
  final IconData icon;
  final String text;
  final Tone tone;

  const _HistoryValue({
    required this.icon,
    required this.text,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone == Tone.neutral
        ? AppColors.inkSecondary
        : tone.foreground;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label.copyWith(
              color: tone == Tone.neutral ? AppColors.ink : tone.foreground,
            ),
          ),
        ),
      ],
    );
  }
}
