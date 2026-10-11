import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/weather_data.dart';
import '../../domain/climate/climate_advisor.dart';
import '../../services/location_service.dart';
import '../../services/tts_service.dart';
import '../../services/weather_service.dart';

/// Image-first atmospheric Weather & Climate Card with:
/// - Interactive 6-day forecast selector (`D-2` through `D+3`)
/// - Clickable telemetry metric pills (Wind, Humidity, Min/Max range)
/// - Interactive check-off microclimate checklist for daily barn tasks
/// - Tappable location badge with GPS auto-detect and region switcher
class WeatherClimateCard extends StatefulWidget {
  final String district;
  final int batchDay;
  final double targetHouseTemp;
  final String language;
  final ValueChanged<String>? onDistrictChanged;

  const WeatherClimateCard({
    super.key,
    required this.district,
    required this.batchDay,
    required this.targetHouseTemp,
    required this.language,
    this.onDistrictChanged,
  });

  @override
  State<WeatherClimateCard> createState() => _WeatherClimateCardState();
}

class _WeatherClimateCardState extends State<WeatherClimateCard> {
  final WeatherService _weatherService = WeatherService();
  final TtsService _ttsService = TtsService();

  late String _activeDistrict;
  WeatherData? _weather;
  bool _isSpeaking = false;
  bool _isExpanded = false;
  int _selectedDayOffset = 0; // -2, -1, 0 (Today), +1, +2, +3
  int? _selectedMetricIndex;
  int _refreshTurns = 0;
  Set<int> _checkedTasks = <int>{};

  @override
  void initState() {
    super.initState();
    _activeDistrict = widget.district;
    _loadWeather();
    _loadCheckedTasks();
  }

  @override
  void didUpdateWidget(covariant WeatherClimateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.district != widget.district &&
        widget.district != _activeDistrict) {
      _activeDistrict = widget.district;
      _loadWeather();
      _loadCheckedTasks();
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  String get _checklistPrefsKey {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    return 'weather_tasks_${_activeDistrict}_$dayKey';
  }

  Future<void> _loadCheckedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_checklistPrefsKey) ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _checkedTasks = saved.map(int.tryParse).whereType<int>().toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleTaskCheck(int index) async {
    setState(() {
      if (_checkedTasks.contains(index)) {
        _checkedTasks.remove(index);
      } else {
        _checkedTasks.add(index);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _checklistPrefsKey,
        _checkedTasks.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    if (forceRefresh && mounted) {
      setState(() => _refreshTurns += 1);
    }
    final data = await _weatherService.getWeatherForDistrict(
      _activeDistrict,
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      setState(() {
        _weather = data;
      });
    }
  }

  Future<void> _toggleTts(ClimateAdvice advice) async {
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      final spokenText =
          '${advice.title}. ${advice.summary}. ${advice.directive}';
      await _ttsService.speak(
        text: spokenText,
        lang: widget.language,
        onComplete: () {
          if (mounted) setState(() => _isSpeaking = false);
        },
      );
    }
  }

  Future<void> _openLocationPickerSheet() async {
    final lang = widget.language;
    final isRu = lang == 'ru';
    final isEn = lang == 'en';
    bool isDetecting = false;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRu
                        ? 'Локация фермы и погода'
                        : (isEn
                            ? 'Farm Location & Weather'
                            : 'Ferma joylashuvi va ob-havo'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // GPS Auto-Detect Button
                  Material(
                    color: const Color(0xFFEAF5ED),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isDetecting
                          ? null
                          : () async {
                              setModalState(() => isDetecting = true);
                              final res = await LocationService()
                                  .detectAndSaveLocation();
                              if (!ctx.mounted) return;
                              setModalState(() => isDetecting = false);
                              if (res.success) {
                                Navigator.pop(ctx, res.district);
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isDetecting
                                    ? (isRu
                                        ? 'Определение по GPS...'
                                        : (isEn
                                            ? 'Detecting via GPS...'
                                            : 'GPS orqali aniqlanmoqda...'))
                                    : (isRu
                                        ? 'Определить автоматически (GPS)'
                                        : (isEn
                                            ? 'Auto-Detect My Location (GPS)'
                                            : 'Joylashuvni avtomatik aniqlash (GPS)')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.gps_fixed_rounded,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: AppConstants.districts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, idx) {
                        final d = AppConstants.districts[idx];
                        final isCurrent = d == _activeDistrict;
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: isCurrent
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: isCurrent
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          title: Text(
                            d,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? const Color(0xFF1B5E20)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                )
                              : null,
                          onTap: () async {
                            await LocationService.saveManualDistrict(d);
                            if (ctx.mounted) Navigator.pop(ctx, d);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        _activeDistrict = selected;
        _selectedDayOffset = 0;
      });
      await _loadWeather(forceRefresh: true);
      await _loadCheckedTasks();
      widget.onDistrictChanged?.call(selected);
    }
  }

  String _localizedConditionText(String condition, String lang) {
    switch (condition) {
      case 'snow':
        return AppStrings.tr(lang: lang, uz: 'Qorli', ru: 'Снег', en: 'Snowy');
      case 'thunderstorm':
        return AppStrings.tr(
          lang: lang,
          uz: 'Momaqaldiroq',
          ru: 'Гроза',
          en: 'Thunderstorm',
        );
      case 'partly_cloudy':
        return AppStrings.tr(
          lang: lang,
          uz: 'Yarim bulutli',
          ru: 'Переменная облачность',
          en: 'Partly Cloudy',
        );
      case 'rain':
        return AppStrings.tr(
          lang: lang,
          uz: "Yomg'irli",
          ru: 'Дождь',
          en: 'Rainy',
        );
      case 'cloudy':
        return AppStrings.tr(
          lang: lang,
          uz: 'Bulutli',
          ru: 'Облачно',
          en: 'Cloudy',
        );
      case 'hot':
        return AppStrings.tr(
          lang: lang,
          uz: 'Issiq / Quyoshli',
          ru: 'Жарко / Солнечно',
          en: 'Hot / Sunny',
        );
      case 'cold':
        return AppStrings.tr(lang: lang, uz: 'Sovuq', ru: 'Холодно', en: 'Cold');
      case 'clear':
      default:
        return AppStrings.tr(
          lang: lang,
          uz: 'Ochiq havo',
          ru: 'Ясно',
          en: 'Clear',
        );
    }
  }

  IconData _iconForCondition(String condition, {required bool isSelected}) {
    switch (condition) {
      case 'rain':
        return Icons.water_drop_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'partly_cloudy':
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'hot':
        return Icons.wb_sunny_rounded;
      case 'cold':
        return Icons.thermostat_rounded;
      case 'clear':
      default:
        return isSelected ? Icons.wb_sunny_rounded : Icons.thermostat_rounded;
    }
  }

  int _targetTempForDayOffset(int dayOffset) {
    final targetDay = (widget.batchDay + dayOffset).clamp(1, 42);
    final actualDeltaDays = targetDay - widget.batchDay;
    return (widget.targetHouseTemp - actualDeltaDays * 0.38)
        .clamp(18.0, 34.0)
        .round();
  }

  List<String> _buildActionChecklist(
    ClimateAdvice advice,
    int targetTemp,
    WeatherForecastDay activeForecast,
    String lang,
  ) {
    final isRu = lang == 'ru';
    final isEn = lang == 'en';
    final wind = activeForecast.windSpeed.toStringAsFixed(0);
    final hum = activeForecast.humidity;

    if (isEn) {
      return [
        'Keep brooder house sensor at $targetTemp°C at chick height',
        'Verify ventilation dampers (outdoor wind: $wind km/h)',
        'Check drinker water temp (18–20°C) & litter dryness ($hum% RH)',
      ];
    } else if (isRu) {
      return [
        'Удерживать температуру в птичнике $targetTemp°C на уровне птиц',
        'Проверить клапаны вентиляции (ветер снаружи: $wind км/ч)',
        'Проверить воду в поилках (18–20°C) и сухость подстилки ($hum%)',
      ];
    }
    return [
      "Xona haroratini jo'ja sathida $targetTemp°C da ushlash",
      'Shamollatish klapanlarini tekshirish (shamol: $wind km/s)',
      "Suv harorati (18–20°C) va to'shama quruqligini ($hum%) nazorat qilish",
    ];
  }

  String _metricDetailTip(
    int metricIndex,
    WeatherForecastDay dayForecast,
    int targetTemp,
    String lang,
  ) {
    final isRu = lang == 'ru';
    final isEn = lang == 'en';
    final delta = (dayForecast.tempAvg - targetTemp).round();
    final deltaStr = delta >= 0 ? '+$delta°C' : '$delta°C';

    if (metricIndex == 0) {
      return isEn
          ? 'Wind is ${dayForecast.windSpeed.toStringAsFixed(1)} km/h. Avoid direct cold floor drafts on chicks.'
          : (isRu
              ? 'Ветер ${dayForecast.windSpeed.toStringAsFixed(1)} км/ч. Не допускайте сквозняков на уровне пола.'
              : "Shamol tezligi ${dayForecast.windSpeed.toStringAsFixed(1)} km/s. Jo'jalar ustiga sovuq yelvizak tushmasin.");
    } else if (metricIndex == 1) {
      return isEn
          ? 'Outdoor humidity is ${dayForecast.humidity}%. Target indoor barn RH is 55–65% to prevent ammonia.'
          : (isRu
              ? 'Влажность на улице ${dayForecast.humidity}%. В птичнике держите 55–65%, чтобы избежать аммиака.'
              : "Tashqi namlik ${dayForecast.humidity}%. Ammiak to'planmasligi uchun xonada 55–65% namlik saqlang.");
    }
    return isEn
        ? 'Outdoor range: ${dayForecast.tempMin.toStringAsFixed(0)}°..${dayForecast.tempMax.toStringAsFixed(0)}°C ($deltaStr vs house target $targetTemp°C).'
        : (isRu
            ? 'Диапазон на улице: ${dayForecast.tempMin.toStringAsFixed(0)}°..${dayForecast.tempMax.toStringAsFixed(0)}°C ($deltaStr к норме $targetTemp°C).'
            : "Tashqi harorat: ${dayForecast.tempMin.toStringAsFixed(0)}°..${dayForecast.tempMax.toStringAsFixed(0)}°C (me'yordan farqi: $deltaStr).");
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    final weather =
        _weather ?? WeatherData.seasonalFallback(districtName: _activeDistrict);
    final activeForecast = weather.forecastForOffset(_selectedDayOffset);
    final selectedBatchDay =
        (widget.batchDay + _selectedDayOffset).clamp(1, 42);
    final selectedTargetTemp = _targetTempForDayOffset(_selectedDayOffset);

    final advice = ClimateAdvisor.evaluate(
      flockAgeDays: selectedBatchDay,
      outsideTemp: activeForecast.tempAvg,
      outsideHumidity: activeForecast.humidity.toDouble(),
      targetHouseTemp: selectedTargetTemp.toDouble(),
      lang: lang,
    );

    final dMinus2 = _targetTempForDayOffset(-2);
    final dMinus1 = _targetTempForDayOffset(-1);
    final currentTempInt = _targetTempForDayOffset(0);
    final dPlus1 = _targetTempForDayOffset(1);
    final dPlus2 = _targetTempForDayOffset(2);
    final dPlus3 = _targetTempForDayOffset(3);

    final conditionLabel = _localizedConditionText(
      activeForecast.condition,
      lang,
    );
    final todayLabel = AppStrings.tr(
      lang: lang,
      uz: 'Bugun',
      ru: 'Сегодня',
      en: 'Today',
    );
    final checklist = _buildActionChecklist(
      advice,
      selectedTargetTemp,
      activeForecast,
      lang,
    );
    final doneCount = _checkedTasks.length.clamp(0, checklist.length);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Stack(
          children: [
            // 1. Cinematic Background Image (Sunset Agriculture Field)
            Positioned.fill(
              child: Image.asset(
                'assets/images/sunset_farm.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8D4F1E), Color(0xFF2C4425)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Translucent Frosted Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(145),
                      Colors.black.withAlpha(95),
                      Colors.black.withAlpha(190),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Card Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Tappable District Badge & Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _openLocationPickerSheet,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  weather.districtName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    "• $conditionLabel (${activeForecast.tempAvg.toStringAsFixed(0)}°C, ${activeForecast.humidity}%)",
                                    key: ValueKey<String>(
                                      '${_selectedDayOffset}_${activeForecast.condition}_${activeForecast.tempAvg.round()}',
                                    ),
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(215),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildGlassCircleButton(
                            icon: _isSpeaking
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            onTap: () => _toggleTts(advice),
                            tooltip: AppStrings.tr(
                              lang: lang,
                              uz: 'Ovozli eshitish',
                              ru: 'Озвучить',
                              en: 'Listen aloud',
                            ),
                            isActive: _isSpeaking,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: AnimatedRotation(
                                turns: _refreshTurns.toDouble(),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: AppStrings.tr(
                                lang: lang,
                                uz: 'Yangilash',
                                ru: 'Обновить',
                                en: 'Refresh',
                              ),
                              onPressed: () => _loadWeather(forceRefresh: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Interactive Multi-Day Ross-308 Target & Forecast Strip (clickable D-2 to D+3)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildForecastPill(
                          dayOffset: -2,
                          label: 'D-2',
                          icon: _iconForCondition(
                            weather.forecastForOffset(-2).condition,
                            isSelected: _selectedDayOffset == -2,
                          ),
                          temp: '$dMinus2°',
                          isSelected: _selectedDayOffset == -2,
                        ),
                        const SizedBox(width: 8),
                        _buildForecastPill(
                          dayOffset: -1,
                          label: 'D-1',
                          icon: _iconForCondition(
                            weather.forecastForOffset(-1).condition,
                            isSelected: _selectedDayOffset == -1,
                          ),
                          temp: '$dMinus1°',
                          isSelected: _selectedDayOffset == -1,
                        ),
                        const SizedBox(width: 8),
                        _buildForecastPill(
                          dayOffset: 0,
                          label: todayLabel,
                          icon: _iconForCondition(
                            weather.forecastForOffset(0).condition,
                            isSelected: _selectedDayOffset == 0,
                          ),
                          temp: '$currentTempInt°',
                          isSelected: _selectedDayOffset == 0,
                        ),
                        const SizedBox(width: 8),
                        _buildForecastPill(
                          dayOffset: 1,
                          label: 'D+1',
                          icon: _iconForCondition(
                            weather.forecastForOffset(1).condition,
                            isSelected: _selectedDayOffset == 1,
                          ),
                          temp: '$dPlus1°',
                          isSelected: _selectedDayOffset == 1,
                        ),
                        const SizedBox(width: 8),
                        _buildForecastPill(
                          dayOffset: 2,
                          label: 'D+2',
                          icon: _iconForCondition(
                            weather.forecastForOffset(2).condition,
                            isSelected: _selectedDayOffset == 2,
                          ),
                          temp: '$dPlus2°',
                          isSelected: _selectedDayOffset == 2,
                        ),
                        const SizedBox(width: 8),
                        _buildForecastPill(
                          dayOffset: 3,
                          label: 'D+3',
                          icon: _iconForCondition(
                            weather.forecastForOffset(3).condition,
                            isSelected: _selectedDayOffset == 3,
                          ),
                          temp: '$dPlus3°',
                          isSelected: _selectedDayOffset == 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Interactive Clickable Telemetry Metric Chips (Wind, Humidity, Min/Max)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTelemetryMetricChip(
                          index: 0,
                          icon: Icons.air_rounded,
                          label:
                              '${activeForecast.windSpeed.toStringAsFixed(0)} km/s',
                        ),
                        const SizedBox(width: 8),
                        _buildTelemetryMetricChip(
                          index: 1,
                          icon: Icons.water_drop_outlined,
                          label: '${activeForecast.humidity}% RH',
                        ),
                        const SizedBox(width: 8),
                        _buildTelemetryMetricChip(
                          index: 2,
                          icon: Icons.device_thermostat_rounded,
                          label:
                              '${activeForecast.tempMin.toStringAsFixed(0)}°..${activeForecast.tempMax.toStringAsFixed(0)}°C',
                        ),
                      ],
                    ),
                  ),

                  // Animated Metric Detail Tip when a telemetry chip is clicked
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: _selectedMetricIndex == null
                        ? const SizedBox.shrink()
                        : Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(110),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withAlpha(45),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 15,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _metricDetailTip(
                                      _selectedMetricIndex!,
                                      activeForecast,
                                      selectedTargetTemp,
                                      lang,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Area: Large Target Temperature + Outdoor Telemetry & Expandable Advisory Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tr(
                                lang: lang,
                                uz: "$selectedBatchDay-kun • Ross-308",
                                ru: "$selectedBatchDay-й день • Ross-308",
                                en: "Day $selectedBatchDay • Ross-308",
                              ),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.94,
                                        end: 1.0,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    '$selectedTargetTemp°C',
                                    key: ValueKey<int>(selectedTargetTemp),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${AppStrings.tr(lang: lang, uz: "Me'yor", ru: 'Норма', en: 'Target')} • ${AppStrings.tr(lang: lang, uz: "Tashqi", ru: 'Улица', en: 'Out')}: ${activeForecast.tempAvg.toStringAsFixed(0)}°C (${activeForecast.humidity}%)',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status & Checklist Expand Pill Badge
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color: Colors.white.withAlpha(70),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 125),
                                child: Text(
                                  advice.statusBadge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Expandable Detailed Technical Advice + Interactive Check-off Tasks
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(105),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.white.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  advice.directive,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: doneCount == checklist.length
                                      ? const Color(0xFF22C55E).withAlpha(60)
                                      : Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$doneCount/${checklist.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${advice.ventilationAdvice} • ${advice.waterFeedAdvice}",
                            style: TextStyle(
                              color: Colors.white.withAlpha(210),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (int i = 0; i < checklist.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: GestureDetector(
                                onTap: () => _toggleTaskCheck(i),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _checkedTasks.contains(i)
                                        ? const Color(0xFF22C55E).withAlpha(45)
                                        : Colors.white.withAlpha(18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _checkedTasks.contains(i)
                                          ? const Color(0xFF4ADE80)
                                          : Colors.white.withAlpha(35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: _checkedTasks.contains(i)
                                              ? const Color(0xFF22C55E)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _checkedTasks.contains(i)
                                                ? const Color(0xFF22C55E)
                                                : Colors.white.withAlpha(170),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _checkedTasks.contains(i)
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 12,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          checklist[i],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                _checkedTasks.contains(i)
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                            decorationColor: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryMetricChip({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMetricIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetricIndex = isSelected ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withAlpha(210)
              : Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFDE68A)
                : Colors.white.withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastPill({
    required int dayOffset,
    required String label,
    required IconData icon,
    required String temp,
    required bool isSelected,
  }) {
    final bgColor =
        isSelected ? const Color(0xFFF59E0B) : Colors.white.withAlpha(35);
    final borderColor =
        isSelected ? Colors.transparent : Colors.white.withAlpha(50);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayOffset = dayOffset;
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withAlpha(120),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white.withAlpha(200),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              Text(
                temp,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen : Colors.white.withAlpha(40),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(60),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}
