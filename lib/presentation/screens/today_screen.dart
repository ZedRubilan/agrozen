import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/daily_plan.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../domain/alerts/alert_models.dart';
import '../../services/external_actions.dart';
import '../../services/farm_store.dart';
import '../../services/location_service.dart';
import '../ui/broiler_photos.dart';
import '../ui/components.dart';
import '../ui/format.dart';
import '../widgets/agro_icons.dart';
import '../widgets/alert_card.dart';
import '../widgets/task_checklist_card.dart';
import '../widgets/weather_summary_card.dart';

/// "Today" tab: what the farmer needs to know and do today, in order —
/// a photo hero with the batch day, flock status, warnings, today's targets,
/// quick logging and the task list.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  FarmSnapshot? _farm;
  List<AlertResult> _alerts = const [];
  Map<String, dynamic>? _vet;
  List<String> _tasks = const [];
  bool _locating = false;
  bool _hideLocationPrompt = false;

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
    DailyPlan? plan;
    try {
      plan = await KnowledgeRepository().getDailyPlan(farm.batchDay);
    } catch (_) {
      plan = null;
    }
    if (!mounted) return;
    setState(() {
      _farm = farm;
      _alerts = alerts;
      _vet = vet;
      _tasks = plan?.taskList(farm.lang) ?? const [];
    });
  }

  Future<void> _enableLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await LocationService().detectAndSaveLocation();
    if (!result.success) await LocationService.markLocationPromptResolved();
    if (!mounted) return;
    setState(() => _locating = false);
    FarmStore.notifyChanged();
  }

  Future<void> _dismissLocation() async {
    setState(() => _hideLocationPrompt = true);
    await LocationService.markLocationPromptResolved();
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    if (farm == null) return const LoadingView();

    final vetPhone = _vet?['phone']?.toString();
    final vetName = _vet?['name']?.toString();

    var section = 0;
    Widget reveal(Widget child) => Reveal(index: section++, child: child);

    final content = <Widget>[
      if (farm.batchFinished) ...[
        reveal(
          NoticeBanner(
            tone: Tone.info,
            icon: Icons.flag_rounded,
            title: _t(
              '42 kunlik sikl tugadi',
              '42-дневный цикл завершён',
              'The 42-day cycle is complete',
            ),
            message: _t(
              "Yangi jo'jalar kelganda yangi partiyani boshlang.",
              'Когда привезёте новых цыплят, начните новую партию.',
              'When new chicks arrive, start a new batch.',
            ),
            actions: [
              FilledButton(
                onPressed: () => _open('/settings'),
                child: Text(_t('Yangi partiya', 'Новая партия', 'New batch')),
              ),
            ],
          ),
        ),
        const Gap(),
      ],
      if (!farm.locationPromptResolved && !_hideLocationPrompt) ...[
        reveal(
          NoticeBanner(
            tone: Tone.info,
            icon: Icons.my_location_rounded,
            title: _t(
              'Joylashuvni aniqlaymizmi?',
              'Определить местоположение?',
              'Use your location?',
            ),
            message: _t(
              "Ob-havo maslahatlari sizning hududingiz uchun aniq bo'ladi.",
              'Советы по погоде будут точными для вашего района.',
              'Weather advice will match your exact area.',
            ),
            onClose: _dismissLocation,
            actions: [
              FilledButton.icon(
                onPressed: _locating ? null : _enableLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(_t('Aniqlash', 'Определить', 'Detect')),
              ),
            ],
          ),
        ),
        const Gap(),
      ],
      for (final alert in _alerts) ...[
        reveal(
          AlertCard.fromAlertResult(
            alert: alert,
            locale: _lang,
            vetPhone: vetPhone,
            vetName: vetName,
          ),
        ),
        const Gap(),
      ],
      reveal(
        SectionHeader(
          title: _t("Bugungi me'yorlar", 'Нормы на сегодня', "Today's targets"),
          actionLabel: _t('Batafsil', 'Подробнее', 'Details'),
          onAction: () => _open('/daily-plan'),
        ),
      ),
      reveal(_buildTargets(farm)),
      const Gap(AppSpace.xl),
      reveal(
        SectionHeader(
          title: _t(
            'Bugun yozib qoling',
            'Записать за сегодня',
            'Record today',
          ),
        ),
      ),
      reveal(_buildQuickLog(farm)),
      if (_tasks.isNotEmpty) ...[
        const Gap(AppSpace.xl),
        reveal(
          SectionHeader(
            title: _t(
              'Bugungi vazifalar',
              'Задачи на сегодня',
              "Today's tasks",
            ),
            actionLabel: _t('42 kunlik reja', 'План на 42 дня', '42-day plan'),
            onAction: () => _open('/daily-plan'),
          ),
        ),
        reveal(TaskChecklistCard(day: farm.batchDay, tasks: _tasks)),
      ],
      const Gap(AppSpace.xl),
      reveal(SectionHeader(title: _t('Ob-havo', 'Погода', 'Weather'))),
      reveal(
        WeatherSummaryCard(
          district: farm.district,
          locationLabel: farm.locationLabel,
          batchDay: farm.batchDay,
          targetHouseTemp: farm.spec.targetTempC,
          language: _lang,
        ),
      ),
      const Gap(AppSpace.xl),
      reveal(SectionHeader(title: _t('Foydali', 'Полезное', 'Useful'))),
      reveal(
        _PhotoLinkCard(
          image: 'assets/images/feed_grain.jpg',
          icon: Icons.calculate_rounded,
          title: _t('Hisob-kitoblar', 'Калькуляторы', 'Calculators'),
          subtitle: _t(
            'FCR, samaradorlik va kutilayotgan foyda',
            'FCR, эффективность и ожидаемая прибыль',
            'FCR, efficiency and expected profit',
          ),
          onTap: () => _open('/tools'),
        ),
      ),
      if (vetPhone != null) ...[
        const Gap(),
        reveal(
          _VetCard(
            title: _t('Tuman veterinari', 'Районный ветеринар', 'District vet'),
            subtitle: '${vetName ?? ''} · $vetPhone',
            callLabel: _t("Qo'ng'iroq", 'Позвонить', 'Call'),
            onCall: () => const ExternalActions().callPhone(context, vetPhone),
          ),
        ),
      ],
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        onRefresh: _load,
        edgeOffset: MediaQuery.paddingOf(context).top,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpace.xxl),
          children: [
            _buildHeroWithFlock(farm),
            const Gap(AppSpace.lg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.screen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo of the flock with the greeting and the batch-day ring, and the
  /// flock card floating over its bottom edge.
  Widget _buildHeroWithFlock(FarmSnapshot farm) {
    const overlap = 48.0;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: overlap),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.hero),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: _HeroPhoto(day: farm.batchDay)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    top + AppSpace.md,
                    AppSpace.screen,
                    AppSpace.xl + overlap + 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AgroChickIcon(size: 44),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t(
                                    'Assalomu alaykum, ${farm.farmerName}!',
                                    'Здравствуйте, ${farm.farmerName}!',
                                    'Hello, ${farm.farmerName}!',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.section.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 15,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        farm.locationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.caption.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          GlassPill(
                            tooltip: _t('Sozlamalar', 'Настройки', 'Settings'),
                            padding: const EdgeInsets.all(10),
                            onTap: () => _open('/settings'),
                            child: const Icon(Icons.settings_rounded, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Row(
                        children: [
                          ProgressRing(
                            value: farm.cycleProgress,
                            size: 104,
                            stroke: 9,
                            color: Colors.white,
                            trackColor: Colors.white.withAlpha(56),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CountUpText(
                                  value: farm.batchDay.toDouble(),
                                  format: (v) => '${v.round()}',
                                  style: AppText.display.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '/ 42',
                                  style: AppText.caption.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GlassPill(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.eco_rounded, size: 15),
                                      const SizedBox(width: 5),
                                      Text(farm.phaseName()),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                  _fmt.dayOf(farm.batchDay, 42),
                                  style: AppText.screenTitle.copyWith(
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpace.screen,
          right: AppSpace.screen,
          bottom: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _buildFlockCard(farm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlockCard(FarmSnapshot farm) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.raised,
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.lg,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _miniStat(
                icon: Icons.favorite_rounded,
                tone: Tone.primary,
                value: farm.currentCount.toDouble(),
                format: Fmt.grouped,
                label: _t('tirik', 'живых', 'alive'),
              ),
              const VerticalDivider(width: AppSpace.lg),
              _miniStat(
                icon: Icons.heart_broken_rounded,
                tone: Tone.danger,
                value: farm.totalDeaths.toDouble(),
                format: (v) => '${v.round()}',
                label: _t('nobud', 'падёж', 'lost'),
                caption: '${Fmt.num(farm.cumulativeMortalityPct)}%',
              ),
              const VerticalDivider(width: AppSpace.lg),
              _miniStat(
                icon: Icons.flag_rounded,
                tone: Tone.info,
                value: farm.daysLeft.toDouble(),
                format: (v) => '${v.round()}',
                label: _t('kun qoldi', 'дн. осталось', 'days left'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required Tone tone,
    required double value,
    required String Function(double) format,
    required String label,
    String? caption,
  }) {
    return Expanded(
      child: Row(
        children: [
          IconBadge(icon: icon, tone: tone, size: 32),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        style: AppText.metric.copyWith(fontSize: 20),
                      ),
                      if (caption != null) ...[
                        const SizedBox(width: 3),
                        Text(caption, style: AppText.caption),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTargets(FarmSnapshot farm) {
    final spec = farm.spec;
    final req = farm.requirements;
    final fedToday = farm.todayFeedKg;
    void details() => _open('/daily-plan');
    return MetricGrid(
      children: [
        TargetTile(
          hero: true,
          icon: Icons.thermostat_rounded,
          tone: Tone.warning,
          label: _t('Bino harorati', 'Темп. в птичнике', 'House temperature'),
          value: spec.targetTempC,
          format: _fmt.celsius,
          caption: _t("Jo'jalar sathida", 'На уровне птицы', 'At bird level'),
          onTap: details,
        ),
        TargetTile(
          icon: Icons.grain_rounded,
          tone: Tone.warning,
          label: _t('Yem', 'Корм', 'Feed'),
          value: req.totalDailyFeedKg,
          format: _fmt.kg,
          caption: fedToday > 0
              ? _t(
                  'Berildi: ${_fmt.kg(fedToday)}',
                  'Дано: ${_fmt.kg(fedToday)}',
                  'Given: ${_fmt.kg(fedToday)}',
                )
              : _fmt.perBird(_fmt.grams(spec.dailyFeedPerBirdG)),
          onTap: details,
        ),
        TargetTile(
          icon: Icons.water_drop_rounded,
          tone: Tone.info,
          label: _t('Suv', 'Вода', 'Water'),
          value: req.totalDailyWaterLiters,
          format: _fmt.liters,
          caption: _fmt.perBird(_fmt.ml(spec.dailyWaterPerBirdMl)),
          onTap: details,
        ),
        TargetTile(
          icon: Icons.scale_rounded,
          tone: Tone.primary,
          label: _t('Vazn me\'yori', 'Норма веса', 'Target weight'),
          value: spec.targetWeightG,
          format: _fmt.grams,
          caption: farm.hasWeight
              ? _t(
                  'Oxirgi: ${_fmt.grams(farm.lastWeightG)}',
                  'Последний: ${_fmt.grams(farm.lastWeightG)}',
                  'Last: ${_fmt.grams(farm.lastWeightG)}',
                )
              : _t('Hali tortilmagan', 'Ещё не взвешивали', 'Not weighed yet'),
          onTap: details,
        ),
      ],
    );
  }

  Widget _buildQuickLog(FarmSnapshot farm) {
    return Row(
      children: [
        Expanded(
          child: _LogButton(
            icon: Icons.heart_broken_rounded,
            tone: Tone.danger,
            label: _t("O'lim", 'Падёж', 'Deaths'),
            value: '${farm.todayDeaths}',
            onTap: () => _open('/diary/mortality'),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _LogButton(
            icon: Icons.grain_rounded,
            tone: Tone.warning,
            label: _t('Yem', 'Корм', 'Feed'),
            value: farm.todayFeedKg > 0 ? _fmt.kg(farm.todayFeedKg) : '—',
            onTap: () => _open('/diary/feed'),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _LogButton(
            icon: Icons.scale_rounded,
            tone: Tone.info,
            label: _t('Vazn', 'Вес', 'Weight'),
            value: farm.todayRecord?.weightG != null
                ? _fmt.grams(farm.todayRecord!.weightG!)
                : '—',
            onTap: () => _open('/diary/weight'),
          ),
        ),
      ],
    );
  }
}

/// Photo of a broiler house at the flock's age (chicks, growers or finished
/// birds) behind the Today header, with a gentle one-time zoom-out and a
/// deep green shade so white text stays readable in bright sunlight.
class _HeroPhoto extends StatelessWidget {
  final int day;

  const _HeroPhoto({required this.day});

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.primaryDark),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: still ? 1 : 1.12, end: 1),
          duration: still ? Duration.zero : const Duration(milliseconds: 1600),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Image.asset(
            BroilerPhotos.forDay(day),
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.2),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.heroShade.withAlpha(170),
                AppColors.heroShade.withAlpha(60),
                AppColors.heroShade.withAlpha(215),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Big round "record" button: coloured disc, label, today's value.
class _LogButton extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LogButton({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.md,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tone.solid,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.glow(tone.solid),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.card,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: tone.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

/// Link card with a photo thumbnail on the right.
class _PhotoLinkCard extends StatelessWidget {
  final String image;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoLinkCard({
    required this.image,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: icon, tone: Tone.warning, size: 34),
                const SizedBox(height: AppSpace.sm),
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset(
              image,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox.square(dimension: 96),
            ),
          ),
        ],
      ),
    );
  }
}

/// District vet with one big call button.
class _VetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String callLabel;
  final VoidCallback onCall;

  const _VetCard({
    required this.title,
    required this.subtitle,
    required this.callLabel,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onCall,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.local_hospital_rounded,
            tone: Tone.danger,
            size: 48,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Tooltip(
            message: callLabel,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadow.glow(AppColors.primary),
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
