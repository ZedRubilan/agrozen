import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/weather_data.dart';
import '../../domain/climate/climate_advisor.dart';
import '../../services/weather_service.dart';
import '../ui/components.dart';
import 'weather_scene.dart';

/// Outdoor weather compared with the barn target, plus what to do about it.
/// An animated scene shows the real sky (from the WMO code, day or night);
/// below it: outside vs barn, humidity / wind / rain, and the advice. Tap to
/// see ventilation, water and the next days' forecast.
class WeatherSummaryCard extends StatefulWidget {
  final String district;
  final String locationLabel;
  final int batchDay;
  final double targetHouseTemp;
  final String language;

  /// Injected in tests to avoid network access.
  final Future<WeatherData> Function(String district)? loader;

  const WeatherSummaryCard({
    super.key,
    required this.district,
    required this.locationLabel,
    required this.batchDay,
    required this.targetHouseTemp,
    required this.language,
    this.loader,
  });

  @override
  State<WeatherSummaryCard> createState() => _WeatherSummaryCardState();
}

class _WeatherSummaryCardState extends State<WeatherSummaryCard> {
  WeatherData? _weather;
  bool _expanded = false;

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: widget.language, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeatherSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.district != widget.district ||
        oldWidget.locationLabel != widget.locationLabel) {
      _load();
    }
  }

  Future<void> _load() async {
    WeatherData data;
    try {
      final load = widget.loader ?? WeatherService().getDistrictWeather;
      data = await load(widget.district);
    } catch (_) {
      data = WeatherData.fallback(widget.district);
    }
    if (!mounted) return;
    setState(() => _weather = data);
  }

  static (IconData, Color) _iconFor(WeatherSky sky, {bool isDay = true}) {
    switch (sky) {
      case WeatherSky.clear:
        return isDay
            ? (Icons.wb_sunny_rounded, AppColors.gold)
            : (Icons.nightlight_round, AppColors.info);
      case WeatherSky.partlyCloudy:
        return (Icons.wb_cloudy_rounded, AppColors.gold);
      case WeatherSky.overcast:
        return (Icons.cloud_rounded, AppColors.inkSecondary);
      case WeatherSky.fog:
        return (Icons.foggy, AppColors.inkSecondary);
      case WeatherSky.rain:
        return (Icons.water_drop_rounded, AppColors.info);
      case WeatherSky.snow:
        return (Icons.ac_unit_rounded, AppColors.info);
      case WeatherSky.storm:
        return (Icons.thunderstorm_rounded, AppColors.warning);
    }
  }

  static Tone _toneFor(ClimateRiskLevel level) {
    switch (level) {
      case ClimateRiskLevel.optimal:
        return Tone.primary;
      case ClimateRiskLevel.heatWarning:
        return Tone.danger;
      case ClimateRiskLevel.coldWarning:
        return Tone.info;
      case ClimateRiskLevel.highHumidityRisk:
      case ClimateRiskLevel.dryAirRisk:
        return Tone.warning;
    }
  }

  String _dayLabel(int offset) {
    if (offset == 1) return _t('Ertaga', 'Завтра', 'Tomorrow');
    final date = DateTime.now().add(Duration(days: offset));
    const uz = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final i = date.weekday - 1;
    return _t(uz[i], ru[i], en[i]);
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      child: weather == null ? _buildLoading() : _buildCard(weather),
    );
  }

  Widget _buildLoading() {
    return AppCard(
      key: const ValueKey('loading'),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: _sceneHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: weatherSkyColors(WeatherSky.partlyCloudy, true, 20),
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _sceneHeight = 184;

  Widget _buildCard(WeatherData weather) {
    final advice = ClimateAdvisor.evaluate(
      flockAgeDays: widget.batchDay,
      outsideTemp: weather.temperature,
      outsideHumidity: weather.humidity.toDouble(),
      targetHouseTemp: widget.targetHouseTemp,
      lang: widget.language,
    );
    final tone = _toneFor(advice.riskLevel);
    final isDay = weather.isDayAt(DateTime.now());
    final today = weather.forecastForOffset(0);
    final shadow = [Shadow(color: Colors.black.withAlpha(70), blurRadius: 12)];
    final feels = weather.feelsLike;

    return AppCard(
      key: const ValueKey('weather'),
      padding: EdgeInsets.zero,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height:
                _sceneHeight * MediaQuery.textScalerOf(context).scale(14) / 14,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WeatherScene(
                  sky: weather.sky,
                  isDay: isDay,
                  temperature: weather.temperature,
                ),
                // Keeps white text readable on pale skies (fog, snow).
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black.withAlpha(56), Colors.transparent],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          GlassPill(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: Text(
                                    widget.locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!weather.isLive)
                            GlassPill(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_rounded, size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    _t('Taxminiy', 'Оценка', 'Estimate'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      CountUpText(
                        value: weather.temperature,
                        format: (v) => '${v.round()}°',
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                          shadows: shadow,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          weather.getConditionText(widget.language),
                          if (feels != null)
                            _t(
                              'his qilinadi ${feels.round()}°',
                              'ощущается ${feels.round()}°',
                              'feels ${feels.round()}°',
                            ),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label.copyWith(
                          color: Colors.white,
                          shadows: shadow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompare(weather),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    _chip(
                      Icons.water_drop_rounded,
                      AppColors.info,
                      '${weather.humidity}%',
                      _t('namlik', 'влажн.', 'humidity'),
                    ),
                    _chip(
                      Icons.air_rounded,
                      AppColors.inkSecondary,
                      '${weather.windSpeed.round()} ${_t('km/soat', 'км/ч', 'km/h')}',
                      _t('shamol', 'ветер', 'wind'),
                    ),
                    if (today.precipChance != null)
                      _chip(
                        Icons.umbrella_rounded,
                        AppColors.info,
                        '${today.precipChance}%',
                        _t("bugun yog'in", 'осадки сегодня', 'rain today'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          label: advice.statusBadge,
                          tone: tone,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppMotion.medium,
                      curve: AppMotion.curve,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  advice.directive,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: AppText.bodyMuted.copyWith(color: AppColors.ink),
                ),
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? _buildDetails(weather, advice)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Outside now → what the barn should be at bird level.
  Widget _buildCompare(WeatherData weather) {
    Widget side(IconData icon, Color color, String text) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(text, maxLines: 1, style: AppText.label),
              ),
            ),
          ],
        ),
      ),
    );
    final (icon, color) = _iconFor(
      weather.sky,
      isDay: weather.isDayAt(DateTime.now()),
    );
    final target = widget.targetHouseTemp;
    final targetText = target == target.roundToDouble()
        ? '${target.round()}'
        : '$target';
    return Row(
      children: [
        side(
          icon,
          color,
          _t(
            'Tashqarida ${weather.temperature.round()}°C',
            'На улице ${weather.temperature.round()}°C',
            'Outside ${weather.temperature.round()}°C',
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppColors.inkMuted,
          ),
        ),
        side(
          Icons.home_work_rounded,
          AppColors.sun,
          _t(
            'Binoda $targetText°C',
            'В птичнике $targetText°C',
            'Barn $targetText°C',
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$value ', style: AppText.label),
                  TextSpan(text: label, style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(WeatherData weather, ClimateAdvice advice) {
    Widget block(IconData icon, Tone tone, String title, String text) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, tone: tone, size: 34),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(text, style: AppText.bodyMuted),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.sm),
        block(
          Icons.air_rounded,
          Tone.info,
          _t('Shamollatish', 'Вентиляция', 'Ventilation'),
          advice.ventilationAdvice,
        ),
        block(
          Icons.water_drop_rounded,
          Tone.primary,
          _t('Suv va yem', 'Вода и корм', 'Water & feed'),
          advice.waterFeedAdvice,
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            for (final offset in const [1, 2, 3]) ...[
              if (offset > 1) const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Reveal(
                  index: offset,
                  child: _forecastTile(weather.forecastForOffset(offset)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// One forecast day on a pale version of that day's sky.
  Widget _forecastTile(WeatherForecastDay day) {
    final (icon, color) = _iconFor(day.sky);
    final sky = weatherSkyColors(day.sky, true, day.tempMax);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(sky.first, Colors.white, 0.82)!,
            Color.lerp(sky.last, Colors.white, 0.6)!,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(_dayLabel(day.dayOffset), style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          Icon(icon, size: 28, color: color),
          const SizedBox(height: AppSpace.xs),
          Text(
            '${day.tempMax.round()}° / ${day.tempMin.round()}°',
            style: AppText.label,
          ),
          if (day.precipChance != null && day.precipChance! > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.umbrella_rounded,
                  size: 12,
                  color: AppColors.info,
                ),
                const SizedBox(width: 2),
                Text('${day.precipChance}%', style: AppText.caption),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
