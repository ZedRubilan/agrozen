import 'package:flutter/material.dart';
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
import '../widgets/alert_card.dart';
import '../widgets/task_checklist_card.dart';
import '../widgets/weather_summary_card.dart';

/// "Today" tab: what the farmer needs to know and do today, in order —
/// warnings, the batch day and flock, quick logging, today's targets and the
/// task list.
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
      reveal(
        PageHeader(
          title: _t(
            'Assalomu alaykum, ${farm.farmerName}!',
            'Здравствуйте, ${farm.farmerName}!',
            'Hello, ${farm.farmerName}!',
          ),
          subtitle: farm.locationLabel,
          trailing: IconButton(
            tooltip: _t('Sozlamalar', 'Настройки', 'Settings'),
            onPressed: () => _open('/settings'),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
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
      reveal(
        SummaryCard(
          image: BroilerPhotos.forDay(farm.batchDay),
          title: _fmt.dayOf(farm.batchDay, 42),
          subtitle:
              '${farm.phaseName()} · ${_t('${Fmt.grouped(farm.currentCount.toDouble())} ta tirik', '${Fmt.grouped(farm.currentCount.toDouble())} живых', '${Fmt.grouped(farm.currentCount.toDouble())} alive')}',
          progress: farm.batchDay / 42,
        ),
      ),
      const Gap(AppSpace.lg),
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
      const Gap(AppSpace.lg),
      reveal(
        SectionHeader(
          title: _t("Bugungi me'yorlar", 'Нормы на сегодня', "Today's targets"),
          actionLabel: _t('Batafsil', 'Подробнее', 'Details'),
          onAction: () => _open('/daily-plan'),
        ),
      ),
      reveal(_buildTargets(farm)),
      if (_tasks.isNotEmpty) ...[
        const Gap(AppSpace.lg),
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
      const Gap(AppSpace.lg),
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
      const Gap(AppSpace.lg),
      reveal(
        DetailSection(
          title: _t(
            'Asboblar va hisobotlar',
            'Инструменты и отчёты',
            'Tools & reports',
          ),
          subtitle: _t(
            'Hisob-kitoblar, aqlli ferma, bank hisoboti',
            'Калькуляторы, датчики, отчёт для банка',
            'Calculators, smart barn, bank report',
          ),
          icon: Icons.grid_view_rounded,
          children: [
            ListRow(
              icon: Icons.calculate_outlined,
              title: _t('Hisob-kitoblar', 'Калькуляторы', 'Calculators'),
              onTap: () => _open('/tools'),
            ),
            ListRow(
              icon: Icons.sensors_rounded,
              title: _t('Aqlli ferma', 'Ферма онлайн', 'Smart barn'),
              onTap: () => _open('/monitor'),
            ),
            ListRow(
              icon: Icons.account_balance_outlined,
              title: _t('Bank uchun hisobot', 'Отчёт для банка', 'Bank report'),
              onTap: () => _open('/bank-report'),
            ),
          ],
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

    return PageBody(onRefresh: _load, children: content);
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
    final add = _t("+ qo'shish", '+ добавить', '+ add');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _LogButton(
              icon: Icons.heart_broken_rounded,
              tone: Tone.danger,
              label: _t("O'lim", 'Падёж', 'Deaths'),
              value: farm.todayDeaths > 0 ? '${farm.todayDeaths}' : add,
              onTap: () => _open('/diary/mortality'),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _LogButton(
              icon: Icons.grain_rounded,
              tone: Tone.warning,
              label: _t('Yem', 'Корм', 'Feed'),
              value: farm.todayFeedKg > 0 ? _fmt.kg(farm.todayFeedKg) : add,
              onTap: () => _open('/diary/feed'),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _LogButton(
              icon: Icons.scale_rounded,
              tone: Tone.primary,
              label: _t('Vazn', 'Вес', 'Weight'),
              value: farm.todayRecord?.weightG != null
                  ? _fmt.grams(farm.todayRecord!.weightG!)
                  : add,
              onTap: () => _open('/diary/weight'),
            ),
          ),
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpace.md),
    child: Column(
      children: [
        IconBadge(icon: icon, tone: tone),
        const Gap(AppSpace.sm),
        Text(label, textAlign: TextAlign.center, style: AppText.cardTitle),
        const Gap(2),
        Text(value, textAlign: TextAlign.center, style: AppText.caption),
      ],
    ),
  );
}

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
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
