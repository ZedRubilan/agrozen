import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/daily_plan.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../domain/broiler/broiler_grower_library.dart';
import '../../services/external_actions.dart';
import '../../services/farm_store.dart';
import '../ui/components.dart';
import '../ui/format.dart';
import '../widgets/task_checklist_card.dart';

/// The whole 42-day cycle, one day at a time: targets for the farmer's own
/// flock size, the day's tasks and one practical tip.
class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  static const double _chipWidth = 52;
  static const double _chipGap = 8;

  final ScrollController _dayScroll = ScrollController();
  FarmSnapshot? _farm;
  List<DailyPlan> _plans = const [];
  int _selectedDay = 1;

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
    _dayScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    List<DailyPlan> plans;
    try {
      plans = await KnowledgeRepository().getAllDailyPlans();
    } catch (_) {
      plans = const [];
    }
    if (!mounted) return;
    setState(() {
      _farm = farm;
      _plans = plans;
      _selectedDay = farm.batchDay;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollTo(_selectedDay),
    );
  }

  void _scrollTo(int day) {
    if (!_dayScroll.hasClients) return;
    final viewport = _dayScroll.position.viewportDimension;
    final target =
        (day - 1) * (_chipWidth + _chipGap) -
        viewport / 2 +
        _chipWidth / 2 +
        AppSpace.screen;
    _dayScroll.animateTo(
      target.clamp(0.0, _dayScroll.position.maxScrollExtent),
      duration: AppMotion.medium,
      curve: AppMotion.curve,
    );
  }

  void _select(int day) {
    final d = day.clamp(1, 42);
    if (d == _selectedDay) return;
    setState(() => _selectedDay = d);
    _scrollTo(d);
  }

  /// Colour of the growth phase a day belongs to.
  static Color _phaseColor(int day) {
    switch (BroilerGrowerLibrary.specForDay(day).phaseKey) {
      case 'pre_starter':
      case 'starter':
        return AppColors.gold;
      case 'grower':
        return AppColors.primary;
      default:
        return AppColors.sunDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('42 kunlik reja', 'План на 42 дня', '42-day plan')),
      ),
      body: farm == null
          ? const LoadingView()
          : Column(
              children: [
                _buildDayStrip(farm),
                Expanded(
                  // Swipe left / right for the next / previous day.
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v < -250) _select(_selectedDay + 1);
                      if (v > 250) _select(_selectedDay - 1);
                    },
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.curve,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _buildDay(farm),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayStrip(FarmSnapshot farm) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        controller: _dayScroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.screen,
          vertical: AppSpace.sm,
        ),
        itemCount: 42,
        separatorBuilder: (_, __) => const SizedBox(width: _chipGap),
        itemBuilder: (context, i) {
          final day = i + 1;
          final selected = day == _selectedDay;
          final isToday = day == farm.batchDay;
          final past = day < farm.batchDay;
          final phase = _phaseColor(day);
          return Semantics(
            selected: selected,
            button: true,
            label: _fmt.day(day),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.curve,
              width: _chipWidth,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : phase.withAlpha(past ? 22 : 40),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: isToday && !selected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: selected ? AppShadow.glow(AppColors.primary) : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => _select(day),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _t('kun', 'день', 'day'),
                        style: AppText.caption.copyWith(
                          fontSize: 11,
                          color: selected ? Colors.white70 : AppColors.inkMuted,
                        ),
                      ),
                      Text(
                        '$day',
                        style: AppText.section.copyWith(
                          color: selected
                              ? Colors.white
                              : (past ? AppColors.inkSecondary : AppColors.ink),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? (selected ? Colors.white : AppColors.primary)
                              : (selected ? Colors.white54 : phase),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDay(FarmSnapshot farm) {
    final day = _selectedDay;
    final spec = BroilerGrowerLibrary.specForDay(day);
    final req = BroilerGrowerLibrary.calculateFlockRequirements(
      day: day,
      birdCount: farm.currentCount,
    );
    final plan = _plans.where((p) => p.day == day).firstOrNull;
    final tasks = plan?.taskList(_lang) ?? const <String>[];
    final isToday = day == farm.batchDay;
    final phase = _phaseColor(day);

    return PageBody(
      key: ValueKey(day),
      children: [
        // Day card with the cycle ring in the phase colour.
        AppCard(
          child: Row(
            children: [
              ProgressRing(
                value: day / 42,
                size: 72,
                stroke: 7,
                color: phase,
                trackColor: AppColors.surfaceMuted,
                child: Text(
                  '${(day / 42 * 100).round()}%',
                  style: AppText.label,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmt.day(day)} · ${FarmSnapshot.phaseNameFor(day, _lang)}',
                      style: AppText.metric,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      _t(
                        "${_fmt.birds(farm.currentCount)} uchun hisoblangan",
                        'Рассчитано на ${_fmt.birds(farm.currentCount)}',
                        'Calculated for ${_fmt.birds(farm.currentCount)}',
                      ),
                      style: AppText.bodyMuted,
                    ),
                    if (isToday) ...[
                      const SizedBox(height: AppSpace.sm),
                      StatusPill(
                        label: _t('Bugun', 'Сегодня', 'Today'),
                        tone: Tone.primary,
                        icon: Icons.today_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpace.lg),
        MetricGrid(
          children: [
            TargetTile(
              hero: true,
              icon: Icons.thermostat_rounded,
              tone: Tone.warning,
              label: _t(
                'Bino harorati',
                'Темп. в птичнике',
                'House temperature',
              ),
              value: spec.targetTempC,
              format: _fmt.celsius,
              caption: _t(
                'Namlik ${spec.humidityMinPct}–${spec.humidityMaxPct}%',
                'Влажность ${spec.humidityMinPct}–${spec.humidityMaxPct}%',
                'Humidity ${spec.humidityMinPct}–${spec.humidityMaxPct}%',
              ),
            ),
            TargetTile(
              icon: Icons.scale_rounded,
              tone: Tone.primary,
              label: _t("Vazn me'yori", 'Норма веса', 'Target weight'),
              value: spec.targetWeightG,
              format: _fmt.grams,
              caption: _t(
                "+${_fmt.grams(spec.dailyGainG)} kuniga",
                '+${_fmt.grams(spec.dailyGainG)} в день',
                '+${_fmt.grams(spec.dailyGainG)} per day',
              ),
            ),
            TargetTile(
              icon: Icons.grain_rounded,
              tone: Tone.warning,
              label: _t('Yem', 'Корм', 'Feed'),
              value: req.totalDailyFeedKg,
              format: _fmt.kg,
              caption: _fmt.perBird(_fmt.grams(spec.dailyFeedPerBirdG)),
            ),
            TargetTile(
              icon: Icons.water_drop_rounded,
              tone: Tone.info,
              label: _t('Suv', 'Вода', 'Water'),
              value: req.totalDailyWaterLiters,
              format: _fmt.liters,
              caption: _fmt.perBird(_fmt.ml(spec.dailyWaterPerBirdMl)),
            ),
            TargetTile(
              icon: Icons.lightbulb_rounded,
              tone: Tone.warning,
              label: _t("Yorug'lik", 'Свет', 'Light'),
              value: spec.lightHours.toDouble(),
              format: (v) =>
                  _t('${v.round()} soat', '${v.round()} ч', '${v.round()} h'),
              caption: _t(
                "${spec.darkHours} soat qorong'i · ${spec.lightIntensityLux} lyuks",
                '${spec.darkHours} ч темноты · ${spec.lightIntensityLux} лк',
                '${spec.darkHours} h dark · ${spec.lightIntensityLux} lux',
              ),
            ),
            TargetTile(
              icon: Icons.square_foot_rounded,
              tone: Tone.neutral,
              label: _t('Joy', 'Площадь', 'Space'),
              value: req.requiredBarnAreaCurrentSqM,
              format: (v) => '${Fmt.num(v, decimals: 0)} m²',
              caption: _t(
                "1 m² ga ${spec.maxBirdsPerSqMeter} boshgacha",
                'до ${spec.maxBirdsPerSqMeter} гол. на 1 м²',
                'up to ${spec.maxBirdsPerSqMeter} birds per m²',
              ),
            ),
          ],
        ),
        const Gap(),
        AppCard(
          child: Row(
            children: [
              const IconBadge(
                icon: Icons.inventory_2_rounded,
                tone: Tone.warning,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Yem turi', 'Вид корма', 'Feed type'),
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.feedFormDescription(_lang),
                      style: AppText.cardTitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (tasks.isNotEmpty) ...[
          const Gap(AppSpace.xl),
          SectionHeader(title: _t('Vazifalar', 'Задачи', 'Tasks')),
          TaskChecklistCard(day: day, tasks: tasks),
        ],
        const Gap(AppSpace.xl),
        _TipCard(
          title: _t('Kun maslahati', 'Совет дня', 'Tip of the day'),
          message: spec.dailyFocusTip(_lang),
        ),
        if (plan?.videoUrl != null && plan!.videoUrl!.isNotEmpty) ...[
          const Gap(),
          OutlinedButton.icon(
            onPressed: () =>
                const ExternalActions().openVideo(context, plan.videoUrl!),
            icon: const Icon(Icons.play_circle_rounded),
            label: Text(_t("Videoni ko'rish", 'Смотреть видео', 'Watch video')),
          ),
        ],
        const Gap(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: day > 1 ? () => _select(day - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(_fmt.day(day - 1 < 1 ? 1 : day - 1)),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: day < 42 ? () => _select(day + 1) : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(_fmt.day(day + 1 > 42 ? 42 : day + 1)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tip of the day on a soft green banner.
class _TipCard extends StatelessWidget {
  final String title;
  final String message;

  const _TipCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => NoticeBanner(
    tone: Tone.primary,
    icon: Icons.tips_and_updates_rounded,
    title: title,
    message: message,
  );
}
