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
              reveal(ListGroup(children: _buildToday(farm))),
              const Gap(AppSpace.lg),
              reveal(_buildGrowth(farm)),
              const Gap(AppSpace.lg),
              reveal(
                DetailSection(
                  title: _t('Partiya bo\'yicha', 'За всю партию', 'This batch'),
                  subtitle: _t(
                    '${Fmt.grouped(farm.currentCount.toDouble())} ta tirik · ${farm.totalDeaths} ta nobud',
                    '${Fmt.grouped(farm.currentCount.toDouble())} живых · ${farm.totalDeaths} падёж',
                    '${Fmt.grouped(farm.currentCount.toDouble())} alive · ${farm.totalDeaths} lost',
                  ),
                  icon: Icons.pie_chart_outline_rounded,
                  children: [_buildBatchSummary(farm)],
                ),
              ),
              const Gap(),
              reveal(
                DetailSection(
                  title: _t("Kunlar bo'yicha", 'По дням', 'Day by day'),
                  subtitle: _t(
                    'Oldingi yozuvlarni ochish',
                    'Открыть предыдущие записи',
                    'View previous records',
                  ),
                  icon: Icons.history_rounded,
                  children: [_buildHistory(farm)],
                ),
              ),
            ],
          );

    if (widget.isEmbeddedInPageView) return body;
    return Scaffold(appBar: AppBar(), body: body);
  }

  Widget _buildGrowth(FarmSnapshot farm) {
    final weighings = _weighings(farm);
    if (weighings.isNotEmpty) {
      return DetailSection(
        title: _t("O'sish grafigi", 'График роста', 'Growth chart'),
        subtitle: _t(
          'Vaznni me’yor bilan solishtirish',
          'Сравнить вес с нормой',
          'Compare weight with the target',
        ),
        icon: Icons.show_chart_rounded,
        children: [
          GrowthChartCard(
            weighings: weighings,
            batchDay: farm.batchDay,
            lang: _lang,
          ),
        ],
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(
              'Vaznni kuzatishni boshlang',
              'Начните следить за весом',
              'Start your growth record',
            ),
            style: AppText.section,
          ),
          const Gap(AppSpace.sm),
          Text(
            _t(
              'Vaznni yozing va me’yor bilan solishtiring.',
              'Запишите вес, чтобы сравнить его с нормой.',
              'Add a sample weight to compare with the target.',
            ),
            style: AppText.bodyMuted,
          ),
          const Gap(AppSpace.md),
          PrimaryButton(
            label: _t('Vaznni yozish', 'Записать вес', 'Record weight'),
            icon: Icons.scale_rounded,
            onPressed: () => _open('/diary/weight'),
          ),
        ],
      ),
    );
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
      _RecordCard(
        icon: Icons.scale_rounded,
        tone: Tone.primary,
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

  /// Details use readable rows rather than squeezing values into a ring.
  Widget _buildBatchSummary(FarmSnapshot farm) {
    final stats = <(IconData, Tone, String, String)>[
      (
        Icons.favorite_outline_rounded,
        Tone.primary,
        _t('Tirik', 'Живых', 'Alive'),
        Fmt.grouped(farm.currentCount.toDouble()),
      ),
      (
        Icons.shield_outlined,
        Tone.primary,
        _t('Saqlanish', 'Сохранность', 'Survival'),
        '${Fmt.num(farm.survivalPct)}%',
      ),
      (
        Icons.heart_broken_outlined,
        farm.cumulativeMortalityPct > 4 ? Tone.danger : Tone.neutral,
        _t('Jami nobud', 'Всего падёж', 'Total lost'),
        '${farm.totalDeaths}',
      ),
      (
        Icons.grain_rounded,
        Tone.warning,
        _t('Jami yem', 'Всего корма', 'Total feed'),
        _fmt.kg(farm.totalFeedLoggedKg),
      ),
      (
        Icons.event_available_outlined,
        Tone.neutral,
        _t('Yozilgan kunlar', 'Дней с записями', 'Days recorded'),
        '${farm.history.length}/${farm.batchDay}',
      ),
    ];
    return Column(
      children: [
        for (final stat in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Row(
              children: [
                IconBadge(icon: stat.$1, tone: stat.$2),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.$3, style: AppText.caption),
                      Text(stat.$4, style: AppText.metric),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.cardTitle),
        const Gap(AppSpace.xs),
        Text(subtitle, style: AppText.caption),
        if (progress != null) ...[
          const Gap(AppSpace.sm),
          AppProgressBar(value: progress!, color: AppColors.primary),
        ],
      ],
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            // The stepper sits beside the text unless a narrow screen or large
            // text needs the room.
            final trailingBelow =
                trailing != null &&
                (box.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(14) > 19);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconBadge(icon: icon, tone: tone),
                    const SizedBox(width: AppSpace.md),
                    Expanded(child: content),
                    const SizedBox(width: AppSpace.sm),
                    if (trailing == null)
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                      )
                    else if (!trailingBelow)
                      trailing!,
                  ],
                ),
                if (trailingBelow)
                  Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            );
          },
        ),
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
      width: 48,
      height: 48,
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
