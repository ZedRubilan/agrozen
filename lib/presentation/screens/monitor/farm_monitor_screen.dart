import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../domain/alerts/alert_models.dart';
import '../../../domain/monitoring/barn_monitor.dart';
import '../../../services/farm_store.dart';
import '../../../services/monitoring/barn_data_source.dart';
import '../../ui/broiler_photos.dart';
import '../../ui/components.dart';
import '../../ui/format.dart';
import '../../widgets/alert_card.dart';

/// "Smart barn": live sensor readings, the edge-AI camera and automatic
/// ventilation, all checked against the day's Ross-308 / Cobb-500 norms.
///
/// Until the pilot hardware is installed the readings come from
/// [SimulatedBarnSource], and the screen says so at the top.
class FarmMonitorScreen extends StatefulWidget {
  final DemoScenario initialScenario;

  const FarmMonitorScreen({
    super.key,
    this.initialScenario = DemoScenario.normal,
  });

  @override
  State<FarmMonitorScreen> createState() => _FarmMonitorScreenState();
}

class _FarmMonitorScreenState extends State<FarmMonitorScreen> {
  static const _historyLength = 24;

  FarmSnapshot? _farm;
  Map<String, dynamic>? _vet;
  late DemoScenario _scenario = widget.initialScenario;
  BarnDataSource? _source;
  StreamSubscription<BarnFrame>? _sub;
  BarnStatus? _status;
  final Map<BarnSensor, List<double>> _history = {};
  bool _autoVentilation = true;

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
    _stop();
    super.dispose();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    final vet = await FarmStore.vetFor(farm.district);
    if (!mounted) return;
    setState(() {
      _farm = farm;
      _vet = vet;
    });
    _start();
  }

  void _start() {
    final farm = _farm;
    if (farm == null) return;
    _stop();
    _history.clear();
    final source = SimulatedBarnSource(
      scenario: _scenario,
      day: farm.batchDay,
      birdCount: farm.currentCount,
    );
    _source = source;
    _sub = source.frames().listen((frame) {
      if (!mounted) return;
      setState(() {
        _status = BarnMonitor.evaluate(
          frame: frame,
          day: farm.batchDay,
          birdCount: farm.currentCount,
        );
        frame.values.forEach((sensor, value) {
          final list = _history.putIfAbsent(sensor, () => []);
          list.add(value);
          if (list.length > _historyLength) list.removeAt(0);
        });
      });
    });
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _source?.dispose();
    _source = null;
  }

  void _pickScenario(DemoScenario scenario) {
    if (scenario == _scenario) return;
    setState(() {
      _scenario = scenario;
      _status = null;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    final status = _status;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Aqlli ferma', 'Ферма онлайн', 'Smart barn')),
        actions: [
          IconButton(
            tooltip: _t(
              "Qurilma qo'shish",
              'Добавить устройство',
              'Add a device',
            ),
            icon: const Icon(Icons.add_link_rounded),
            onPressed: _showAddDevice,
          ),
        ],
      ),
      body: farm == null || status == null
          ? const LoadingView()
          : _buildBody(farm, status),
    );
  }

  Widget _buildBody(FarmSnapshot farm, BarnStatus status) {
    var section = 0;
    Widget reveal(Widget child) => Reveal(index: section++, child: child);

    return PageBody(
      children: [
        reveal(_demoBar()),
        const Gap(),
        reveal(_statusCard(farm, status)),
        if (status.needsVet) ...[
          const Gap(),
          AlertCard(
            message: _cameraVetMessage(status),
            severity: AlertSeverity.critical,
            vetPhone: _vet?['phone']?.toString(),
            vetName: _vet?['name']?.toString(),
            locale: _lang,
          ),
        ],
        const Gap(AppSpace.xl),
        reveal(SectionHeader(title: _t('Sensorlar', 'Датчики', 'Sensors'))),
        reveal(_sensorGrid(status)),
        const Gap(AppSpace.xl),
        reveal(
          SectionHeader(title: _t('Shamollatish', 'Вентиляция', 'Ventilation')),
        ),
        reveal(_ventilationCard(status)),
        const Gap(AppSpace.xl),
        reveal(SectionHeader(title: _t('AI-kamera', 'AI-камера', 'AI camera'))),
        reveal(_cameraCard(status)),
        const Gap(AppSpace.xl),
        reveal(
          SectionHeader(
            title: _t('Qurilmalar', 'Устройства', 'Devices'),
            actionLabel: _t("Qo'shish", 'Добавить', 'Add'),
            onAction: _showAddDevice,
          ),
        ),
        reveal(_devices()),
        const Gap(AppSpace.lg),
        Text(
          _t(
            "Tekshiruv — ${farm.batchDay}-kun uchun Ross-308 / Cobb-500 me'yorlari bo'yicha oddiy kod, neyrotarmoq emas. Ilova tashxis qo'ymaydi va dori tavsiya qilmaydi.",
            'Проверка — обычный код по нормам Ross-308 / Cobb-500 на день ${farm.batchDay}, не нейросеть. Приложение не ставит диагнозов и не советует лекарства.',
            'Checks are plain code against the Ross-308 / Cobb-500 norms for day ${farm.batchDay}, not AI. The app never diagnoses or suggests medicines.',
          ),
          style: AppText.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --- Demo scenarios -------------------------------------------------------

  Widget _demoBar() {
    String label(DemoScenario s) => switch (s) {
      DemoScenario.normal => _t('Me\'yor', 'Норма', 'Normal'),
      DemoScenario.ammonia => _t('Ammiak', 'Аммиак', 'Ammonia'),
      DemoScenario.cold => _t('Sovuq', 'Холод', 'Cold'),
      DemoScenario.heat => _t('Issiq', 'Жара', 'Heat'),
      DemoScenario.mortality => _t('Nobudlik', 'Падёж', 'Losses'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(
          label: _t(
            "Demo rejim · sensorlar modellashtirilgan",
            'Демо-режим · датчики смоделированы',
            'Demo mode · sensors are simulated',
          ),
          tone: Tone.info,
          icon: Icons.science_rounded,
        ),
        const SizedBox(height: AppSpace.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in DemoScenario.values) ...[
                ChoiceChip(
                  label: Text(label(s)),
                  selected: s == _scenario,
                  onSelected: (_) => _pickScenario(s),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: AppText.label.copyWith(
                    color: s == _scenario ? Colors.white : AppColors.ink,
                  ),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: const StadiumBorder(),
                ),
                const SizedBox(width: AppSpace.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Overall status -------------------------------------------------------

  Tone _tone(ReadingStatus s) => switch (s) {
    ReadingStatus.ok => Tone.primary,
    ReadingStatus.watch => Tone.warning,
    ReadingStatus.alarm => Tone.danger,
  };

  Widget _statusCard(FarmSnapshot farm, BarnStatus status) {
    final overall = status.overall;
    final tone = _tone(overall);
    final title = switch (overall) {
      ReadingStatus.ok => _t(
        "Hammasi me'yorida",
        'Всё в норме',
        'All within norms',
      ),
      ReadingStatus.watch => _t(
        "E'tibor bering",
        'Нужно внимание',
        'Needs attention',
      ),
      ReadingStatus.alarm => _t('Xavf!', 'Тревога!', 'Alarm!'),
    };
    final messages = [
      for (final c in status.problems) _problemText(c),
      ..._cameraMessages(status),
    ];
    final time = DateFormat('HH:mm:ss').format(status.frame.at);

    return AppCard(
      color: overall == ReadingStatus.ok ? null : tone.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tone.solid,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.glow(tone.solid),
                ),
                child: Icon(
                  overall == ReadingStatus.ok
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.section.copyWith(color: tone.foreground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        '1-parrandaxona · ${_fmt.day(farm.batchDay)} · $time',
                        'Птичник 1 · ${_fmt.day(farm.batchDay)} · $time',
                        'House 1 · ${_fmt.day(farm.batchDay)} · $time',
                      ),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (messages.isEmpty)
            Text(
              _t(
                "Harorat, havo, suv va vazn — barchasi bugungi me'yorda. Kamera parrandalarning bir tekis tarqalganini ko'rmoqda.",
                'Температура, воздух, вода и вес — всё в норме на сегодня. Камера видит, что птица распределена равномерно.',
                "Temperature, air, water and weight are all on today's norm. The camera sees the birds evenly spread.",
              ),
              style: AppText.body,
            )
          else
            for (final m in messages)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: tone.foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(m, style: AppText.body)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _problemText(SensorCheck c) {
    final v = c.value;
    switch (c.sensor) {
      case BarnSensor.temperature:
        final target = _fmt.celsius(c.target ?? 0);
        return c.isLow
            ? _t(
                "Sovuq: ${_fmt.celsius(v)}, me'yor $target. Isitishni tekshiring.",
                'Холодно: ${_fmt.celsius(v)} при норме $target. Проверьте обогрев.',
                'Too cold: ${_fmt.celsius(v)} vs $target. Check the heating.',
              )
            : _t(
                "Issiq: ${_fmt.celsius(v)}, me'yor $target. Shamollatishni kuchaytiring, suvni tekshiring.",
                'Жарко: ${_fmt.celsius(v)} при норме $target. Усильте вентиляцию, проверьте поилки.',
                'Too hot: ${_fmt.celsius(v)} vs $target. Ventilate more and check the drinkers.',
              );
      case BarnSensor.humidity:
        return c.isHigh
            ? _t(
                "Namlik ${Fmt.num(v, decimals: 0)}% — to'shama nam, ammiak ko'payadi.",
                'Влажность ${Fmt.num(v, decimals: 0)}% — подстилка мокнет, растёт аммиак.',
                'Humidity ${Fmt.num(v, decimals: 0)}% — litter gets wet and ammonia rises.',
              )
            : _t(
                "Namlik ${Fmt.num(v, decimals: 0)}% — havo quruq, chang ko'payadi.",
                'Влажность ${Fmt.num(v, decimals: 0)}% — сухо, больше пыли.',
                'Humidity ${Fmt.num(v, decimals: 0)}% — dry air, more dust.',
              );
      case BarnSensor.ammonia:
        return _t(
          "Ammiak ${Fmt.num(v)} ppm — me'yor 10 ppm gacha. To'shamani tekshiring, shamollatishni kuchaytiring.",
          'Аммиак ${Fmt.num(v)} ppm — норма до 10 ppm. Проверьте подстилку и усильте вентиляцию.',
          'Ammonia ${Fmt.num(v)} ppm — norm is up to 10 ppm. Check the litter and ventilate more.',
        );
      case BarnSensor.co2:
        return _t(
          "CO2 ${Fmt.grouped(v)} ppm — toza havo kam. Minimal shamollatishni oshiring.",
          'CO2 ${Fmt.grouped(v)} ppm — мало свежего воздуха. Увеличьте минимальную вентиляцию.',
          'CO2 ${Fmt.grouped(v)} ppm — not enough fresh air. Raise minimum ventilation.',
        );
      case BarnSensor.water:
        final pct = c.target != null && c.target! > 0
            ? ((v / c.target! - 1) * 100).round()
            : 0;
        return c.isLow
            ? _t(
                "Parranda me'yordan ${-pct}% kam suv ichmoqda — bu kasallikning erta belgisi. Parrandani ko'zdan kechiring.",
                'Птица пьёт на ${-pct}% меньше нормы — это ранний признак болезни. Осмотрите птицу.',
                'Birds drink ${-pct}% less than normal — an early sign of illness. Check the flock.',
              )
            : _t(
                "Suv me'yordan +$pct% ko'p — issiqlik yoki suv oqishi.",
                'Воды уходит на $pct% больше нормы — жара или течь поилок.',
                'Water use is $pct% above normal — heat or a leaking drinker.',
              );
      case BarnSensor.weight:
        final pct = c.target != null && c.target! > 0
            ? ((1 - v / c.target!) * 100).round()
            : 0;
        return _t(
          "O'rtacha vazn me'yordan $pct% past. Oziqlantirishni tekshiring.",
          'Средний вес ниже нормы на $pct%. Проверьте кормление.',
          'Average weight is $pct% below target. Check the feeding.',
        );
    }
  }

  List<String> _cameraMessages(BarnStatus status) {
    final frame = status.frame;
    return [
      if (frame.inactiveBirds > 0)
        _t(
          'Kamera: ${frame.inactiveBirds} ta harakatsiz parranda.',
          'Камера: неподвижных птиц — ${frame.inactiveBirds}.',
          'Camera: ${frame.inactiveBirds} birds not moving.',
        ),
      if (frame.has(CameraFinding.huddling))
        _t(
          "Kamera: parrandalar bir joyga to'planmoqda — ularga sovuq.",
          'Камера: птицы сбиваются в кучу — им холодно.',
          'Camera: birds are huddling — they are cold.',
        ),
      if (frame.has(CameraFinding.heatStress))
        _t(
          'Kamera: parrandalar devor yonida qanot yoyib turibdi — ularga issiq.',
          'Камера: птицы у стен с раскрытыми крыльями — им жарко.',
          'Camera: birds at the walls with wings out — they are hot.',
        ),
    ];
  }

  String _cameraVetMessage(BarnStatus status) => _t(
    "Kamera ${status.frame.inactiveBirds} ta harakatsiz parrandani topdi. O'lganlarini olib chiqing va tuman veterinariga qo'ng'iroq qiling.",
    'Камера нашла неподвижных птиц: ${status.frame.inactiveBirds}. Уберите павших и позвоните районному ветеринару.',
    'The camera found ${status.frame.inactiveBirds} birds not moving. Remove any dead birds and call the district vet.',
  );

  // --- Sensors --------------------------------------------------------------

  Widget _sensorGrid(BarnStatus status) {
    return MetricGrid(
      children: [
        for (final c in status.checks)
          _SensorTile(
            icon: _sensorIcon(c.sensor),
            label: _sensorLabel(c.sensor),
            value: _sensorValue(c),
            norm: _sensorNorm(c),
            statusLabel: switch (c.status) {
              ReadingStatus.ok => _t("Me'yor", 'Норма', 'OK'),
              ReadingStatus.watch => _t("E'tibor", 'Внимание', 'Watch'),
              ReadingStatus.alarm => _t('Xavf', 'Тревога', 'Alarm'),
            },
            tone: _tone(c.status),
            history: _history[c.sensor] ?? const [],
          ),
      ],
    );
  }

  IconData _sensorIcon(BarnSensor s) => switch (s) {
    BarnSensor.temperature => Icons.thermostat_rounded,
    BarnSensor.humidity => Icons.water_drop_outlined,
    BarnSensor.ammonia => Icons.science_rounded,
    BarnSensor.co2 => Icons.co2_rounded,
    BarnSensor.water => Icons.water_rounded,
    BarnSensor.weight => Icons.monitor_weight_rounded,
  };

  String _sensorLabel(BarnSensor s) => switch (s) {
    BarnSensor.temperature => _t('Harorat', 'Температура', 'Temperature'),
    BarnSensor.humidity => _t('Namlik', 'Влажность', 'Humidity'),
    BarnSensor.ammonia => _t('Ammiak NH3', 'Аммиак NH3', 'Ammonia NH3'),
    BarnSensor.co2 => _t(
      'Karbonat angidrid',
      'Углекислый газ',
      'Carbon dioxide',
    ),
    BarnSensor.water => _t('Suv, sutkada', 'Вода за сутки', 'Water per day'),
    BarnSensor.weight => _t('Tarozi', 'Весы', 'Scale'),
  };

  String _sensorValue(SensorCheck c) => switch (c.sensor) {
    BarnSensor.temperature => _fmt.celsius(c.value),
    BarnSensor.humidity => '${Fmt.num(c.value, decimals: 0)}%',
    BarnSensor.ammonia => '${Fmt.num(c.value)} ppm',
    BarnSensor.co2 => '${Fmt.grouped(c.value)} ppm',
    BarnSensor.water => _fmt.liters(c.value),
    BarnSensor.weight => _fmt.grams(c.value),
  };

  String _sensorNorm(SensorCheck c) {
    final norm = _t("Me'yor", 'Норма', 'Norm');
    final upTo = _t('gacha', 'до', 'up to');
    return switch (c.sensor) {
      BarnSensor.temperature =>
        '$norm ${Fmt.num(c.normMin!)}–${_fmt.celsius(c.normMax!)}',
      BarnSensor.humidity =>
        '$norm ${Fmt.num(c.normMin!, decimals: 0)}–${Fmt.num(c.normMax!, decimals: 0)}%',
      BarnSensor.ammonia || BarnSensor.co2 =>
        _lang == 'uz'
            ? '$norm ${Fmt.grouped(c.normMax!)} ppm $upTo'
            : '$norm $upTo ${Fmt.grouped(c.normMax!)} ppm',
      BarnSensor.water => '$norm ~${_fmt.liters(c.target!)}',
      BarnSensor.weight => '$norm ${_fmt.grams(c.target!)}',
    };
  }

  // --- Ventilation ----------------------------------------------------------

  Widget _ventilationCard(BarnStatus status) {
    final needed = status.ventilationOn;
    final running = _autoVentilation && needed;
    final reasons = status.ventilationReasons.map(
      (s) => switch (s) {
        BarnSensor.ammonia => 'NH3',
        BarnSensor.co2 => 'CO2',
        _ => _t('harorat', 'температура', 'temperature'),
      },
    );
    final tone = running ? Tone.info : (needed ? Tone.warning : Tone.neutral);

    final String detail;
    if (running) {
      detail = _t(
        "Ventilyatorlar avtomatik yoqildi: ${reasons.join(', ')} me'yordan yuqori.",
        'Вентиляторы включены автоматически: ${reasons.join(', ')} выше нормы.',
        'Fans switched on automatically: ${reasons.join(', ')} above norm.',
      );
    } else if (needed) {
      detail = _t(
        "Avto rejim o'chiq. ${reasons.join(', ')} me'yordan yuqori — ventilyatorni qo'lda yoqing.",
        'Авторежим выключен. ${reasons.join(', ')} выше нормы — включите вентиляторы вручную.',
        'Auto mode is off. ${reasons.join(', ')} above norm — switch the fans on by hand.',
      );
    } else {
      detail = _t(
        "Havo me'yorida — ventilyatorlar minimal rejimda.",
        'Воздух в норме — вентиляция на минимальном режиме.',
        'Air is on norm — fans on minimum ventilation.',
      );
    }

    Widget relay(String name, bool on) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: on ? AppColors.infoSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Icon(
              on ? Icons.cyclone_rounded : Icons.mode_fan_off_rounded,
              color: on ? AppColors.info : AppColors.inkMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(name, style: AppText.caption, textAlign: TextAlign.center),
            Text(
              on ? _t('YONIQ', 'ВКЛ', 'ON') : _t("O'CHIQ", 'ВЫКЛ', 'OFF'),
              style: AppText.label.copyWith(
                color: on ? AppColors.info : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.air_rounded, tone: tone, size: 44),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Avtomatik rejim', 'Авторежим', 'Automatic mode'),
                      style: AppText.cardTitle,
                    ),
                    Text(
                      _t(
                        "NH3, CO2 yoki issiq bo'lsa yoqiladi",
                        'Включает при NH3, CO2 или жаре',
                        'Runs on NH3, CO2 or heat',
                      ),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoVentilation,
                onChanged: (v) => setState(() => _autoVentilation = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(detail, style: AppText.body),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              relay(
                _t('1-rele · tortish', 'Реле 1 · вытяжка', 'Relay 1 · exhaust'),
                running,
              ),
              const SizedBox(width: AppSpace.sm),
              relay(
                _t('2-rele · tortish', 'Реле 2 · вытяжка', 'Relay 2 · exhaust'),
                running,
              ),
              const SizedBox(width: AppSpace.sm),
              relay(
                _t('3-rele · kirish', 'Реле 3 · приток', 'Relay 3 · inlet'),
                running,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Camera ---------------------------------------------------------------

  Widget _cameraCard(BarnStatus status) {
    final frame = status.frame;
    String boxLabel(CameraDetection d) {
      final name = switch (d.finding) {
        CameraFinding.inactiveBird => _t('harakatsiz', 'неподвижна', 'still'),
        CameraFinding.huddling => _t("to'planish", 'скучивание', 'huddling'),
        CameraFinding.heatStress => _t('issiqlik', 'жара', 'heat'),
      };
      return '$name ${(d.confidence * 100).round()}%';
    }

    Color boxColor(CameraFinding f) => switch (f) {
      CameraFinding.inactiveBird => AppColors.danger,
      CameraFinding.huddling => AppColors.info,
      CameraFinding.heatStress => AppColors.sun,
    };

    final findings = <Widget>[
      if (frame.inactiveBirds > 0)
        StatusPill(
          label: _t(
            'Harakatsiz: ${frame.inactiveBirds}',
            'Неподвижные: ${frame.inactiveBirds}',
            'Not moving: ${frame.inactiveBirds}',
          ),
          tone: Tone.danger,
          icon: Icons.do_not_disturb_on_rounded,
        ),
      if (frame.has(CameraFinding.huddling))
        StatusPill(
          label: _t("To'planish", 'Скучивание', 'Huddling'),
          tone: Tone.info,
          icon: Icons.ac_unit_rounded,
        ),
      if (frame.has(CameraFinding.heatStress))
        StatusPill(
          label: _t('Issiqlik stressi', 'Тепловой стресс', 'Heat stress'),
          tone: Tone.warning,
          icon: Icons.local_fire_department_rounded,
        ),
      if (frame.detections.isEmpty)
        StatusPill(
          label: _t(
            'Bir tekis tarqalgan',
            'Распределены равномерно',
            'Evenly spread',
          ),
          tone: Tone.primary,
          icon: Icons.check_circle_rounded,
        ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: AspectRatio(
              aspectRatio: 1200 / 850,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        BroilerPhotos.finisher,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: AppColors.primaryDark),
                      ),
                    ),
                    for (final (i, d) in frame.detections.indexed)
                      Positioned(
                        left: d.left * box.maxWidth,
                        top: d.top * box.maxHeight,
                        width: d.width * box.maxWidth,
                        height: d.height * box.maxHeight,
                        child: _DetectionBox(
                          color: boxColor(d.finding),
                          // Boxes of one kind sit close together: name the
                          // first, show only the confidence on the rest.
                          label:
                              frame.detections.indexWhere(
                                    (e) => e.finding == d.finding,
                                  ) ==
                                  i
                              ? boxLabel(d)
                              : '${(d.confidence * 100).round()}%',
                        ),
                      ),
                    Positioned(
                      left: AppSpace.sm,
                      top: AppSpace.sm,
                      child: GlassPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _t('1-kamera', 'Камера 1', 'Camera 1'),
                              style: AppText.label.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: findings,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  _t(
                    "Model parrandaxonadagi Jetson qurilmasida ishlaydi: video internetga yuborilmaydi, faqat natija keladi.",
                    'Модель работает на устройстве Jetson в птичнике: видео не уходит в интернет, приходит только результат.',
                    'The model runs on the Jetson box in the barn: video never leaves the farm, only the result does.',
                  ),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Devices --------------------------------------------------------------

  Widget _devices() {
    final online = StatusPill(
      label: _t('Ulangan', 'На связи', 'Online'),
      tone: Tone.primary,
    );
    return ListGroup(
      children: [
        ListRow(
          icon: Icons.memory_rounded,
          tone: Tone.primary,
          title: _t(
            'ESP32 sensor tuguni',
            'Узел датчиков ESP32',
            'ESP32 sensor node',
          ),
          subtitle: 'SHT31 · ZE03-NH3 · MH-Z19C',
          trailing: online,
        ),
        ListRow(
          icon: Icons.developer_board_rounded,
          tone: Tone.info,
          title: 'Jetson Orin Nano',
          subtitle: _t(
            '2 ta IP-kamera · edge-AI',
            '2 IP-камеры · edge-AI',
            '2 IP cameras · edge AI',
          ),
          trailing: online,
        ),
        ListRow(
          icon: Icons.scale_rounded,
          tone: Tone.warning,
          title: _t(
            'Tortish platformasi',
            'Весовая платформа',
            'Weighing platform',
          ),
          subtitle: 'HX711 · 50 kg',
          trailing: online,
        ),
        ListRow(
          icon: Icons.water_rounded,
          tone: Tone.info,
          title: _t('Suv hisoblagichi', 'Счётчик воды', 'Water meter'),
          subtitle: _t(
            'Impulsli, 1–30 l/min',
            'Импульсный, 1–30 л/мин',
            'Pulse, 1–30 L/min',
          ),
          trailing: online,
        ),
        ListRow(
          icon: Icons.toggle_on_rounded,
          tone: Tone.neutral,
          title: _t('Ventilyatsiya relesi', 'Реле вентиляции', 'Fan relay'),
          subtitle: _t('4 kanal', '4 канала', '4 channels'),
          trailing: online,
        ),
      ],
    );
  }

  void _showAddDevice() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t("Qurilma qo'shish", 'Добавить устройство', 'Add a device'),
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              _t(
                "Qurilma qutisidagi QR-kodni skanerlang yoki ID raqamini kiriting. Qurilma Wi-Fi yoki 4G orqali ulanadi.",
                'Отсканируйте QR-код на коробке устройства или введите его ID. Устройство подключается по Wi-Fi или 4G.',
                "Scan the QR code on the device's box or type its ID. The device connects over Wi-Fi or 4G.",
              ),
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: AppSpace.lg),
            TextField(
              decoration: InputDecoration(
                labelText: _t('Qurilma ID', 'ID устройства', 'Device ID'),
                hintText: 'AZ-ESP32-0001',
                prefixIcon: const Icon(Icons.qr_code_2_rounded),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            PrimaryButton(
              label: _t(
                'QR-kodni skanerlash',
                'Сканировать QR-код',
                'Scan QR code',
              ),
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _t(
                        "Demo rejimda qurilmalar allaqachon ulangan.",
                        'В демо-режиме устройства уже подключены.',
                        'In demo mode the devices are already connected.',
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One sensor: value, its norm, a status pill and the recent trend.
class _SensorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String norm;
  final String statusLabel;
  final Tone tone;
  final List<double> history;

  const _SensorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.norm,
    required this.statusLabel,
    required this.tone,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final alarm = tone == Tone.danger;
    return AppCard(
      color: alarm ? AppColors.dangerSoft : null,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, tone: tone, size: 32),
              const Spacer(),
              StatusPill(label: statusLabel, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: AppColors.inkSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.metric.copyWith(
                color: tone == Tone.primary ? AppColors.ink : tone.foreground,
              ),
            ),
          ),
          Text(
            norm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(history, tone.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(List<double> values, this.color) : values = List.of(values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.first;
    var hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = (hi - lo).abs() < 1e-6 ? 1.0 : hi - lo;
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - 2 - (values[i] - lo) / span * (size.height - 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withAlpha(28));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color ||
      old.values.length != values.length ||
      (values.isNotEmpty && old.values.last != values.last);
}

/// A detection box with its label, as the edge model draws it on the frame.
class _DetectionBox extends StatelessWidget {
  final Color color;
  final String label;

  const _DetectionBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          left: -1,
          top: -18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: AppText.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
