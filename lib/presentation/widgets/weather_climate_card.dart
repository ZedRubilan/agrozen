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
import 'animated_entry.dart';

/// Restyled High-Craft Atmospheric Weather & Broiler Microclimate Card:
/// - Clear Dual-Climate Split Hero: separates actual **Outdoor Weather Temperature**
///   from **Ross-308 Indoor Barn Target Temperature** with a live Thermal Delta badge.
/// - Accurate 6-Day Forecast Timeline (`D-2` through `D+3`): shows real outdoor forecast
///   temperatures on the day badges alongside the flock cycle day.
/// - Searchable Uzbekistan Town & Region Picker (with instant search for **Chortoq / Chartak**,
///   live Open-Meteo geocoding, and native/browser GPS detection).
/// - Smooth Emil Kowalski animations (`160–220ms` `Curves.easeOutCubic`, tactile press,
///   ambient floating weather glyph).
class WeatherClimateCard extends StatefulWidget {
  final String district;
  final String? locality;
  final int batchDay;
  final double targetHouseTemp;
  final String language;
  final ValueChanged<String>? onDistrictChanged;

  const WeatherClimateCard({
    super.key,
    required this.district,
    this.locality,
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
  final LocationService _locationService = LocationService();
  final TtsService _ttsService = TtsService();

  late String _activeDistrict;
  String? _activeLocality;
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
    _activeLocality = widget.locality;
    _initLocationAndWeather();
    _loadCheckedTasks();
  }

  @override
  void didUpdateWidget(covariant WeatherClimateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.district != widget.district &&
            widget.district != _activeDistrict) ||
        (oldWidget.locality != widget.locality &&
            widget.locality != _activeLocality)) {
      _activeDistrict = widget.district;
      _activeLocality = widget.locality;
      _loadWeather();
      _loadCheckedTasks();
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _initLocationAndWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDistrict = prefs.getString('farmer_district');
      final savedLocality = prefs.getString('farmer_locality');
      if (savedDistrict == _activeDistrict &&
          savedLocality != null &&
          savedLocality.isNotEmpty) {
        _activeLocality = savedLocality;
      }
    } catch (_) {}
    await _loadWeather();
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
        if (data.locality != null && data.locality!.isNotEmpty) {
          _activeLocality = data.locality;
        }
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
    String searchQuery = '';
    List<UzbekistanLocality> searchResults =
        LocationService.uzbekistanLocalities;

    final selected = await showModalBottomSheet<({String district, String? locality})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.82,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isRu
                              ? 'Локация фермы и точная погода'
                              : (isEn
                                  ? 'Farm Location & Exact Weather'
                                  : 'Ferma joylashuvi va aniq ob-havo'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Instant Search Input for Towns / Districts (e.g. Chartak / Chortoq)
                  TextField(
                    onChanged: (val) async {
                      searchQuery = val;
                      final localFiltered = LocationService.uzbekistanLocalities
                          .where((loc) => loc.matchesQuery(val))
                          .toList();
                      setModalState(() => searchResults = localFiltered);
                      if (val.trim().length >= 2) {
                        final remote = await _locationService.searchLocations(
                          val,
                          lang: lang,
                        );
                        if (ctx.mounted && searchQuery == val) {
                          setModalState(() => searchResults = remote);
                        }
                      }
                    },
                    decoration: InputDecoration(
                      hintText: isRu
                          ? 'Поиск города или района (напр., Чартак, Наманган)...'
                          : (isEn
                              ? 'Search town or district (e.g., Chartak, Chortoq)...'
                              : 'Tuman yoki shaharni qidiring (masalan: Chortoq, Namangan)...'),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4F7F4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

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
                              final res =
                                  await _locationService.detectAndSaveLocation();
                              if (!ctx.mounted) return;
                              setModalState(() => isDetecting = false);
                              if (res.success) {
                                Navigator.pop(
                                  ctx,
                                  (
                                    district: res.district,
                                    locality: res.locality,
                                  ),
                                );
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            isDetecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isDetecting
                                    ? (isRu
                                        ? 'Определение точных координат GPS...'
                                        : (isEn
                                            ? 'Detecting exact GPS coordinates...'
                                            : 'Aniq GPS koordinatalar aniqlanmoqda...'))
                                    : (isRu
                                        ? 'Определить автоматически (GPS)'
                                        : (isEn
                                            ? 'Auto-Detect My Exact Location (GPS)'
                                            : 'Joylashuvni avtomatik aniqlash (GPS)')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
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
                  const SizedBox(height: 10),

                  // Quick-Pick Featured Town Chips (Chortoq / Chartak first!)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final quickLoc in [
                          LocationService.chartakLocality,
                          ...LocationService.uzbekistanLocalities
                              .where((l) => l.id != 'Chortoq')
                              .take(5),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(
                                Icons.place_rounded,
                                size: 15,
                                color: (_activeLocality == quickLoc.id ||
                                        (_activeLocality == null &&
                                            _activeDistrict == quickLoc.id))
                                    ? Colors.white
                                    : AppTheme.primaryGreen,
                              ),
                              backgroundColor: (_activeLocality == quickLoc.id ||
                                      (_activeLocality == null &&
                                          _activeDistrict == quickLoc.id))
                                  ? AppTheme.primaryGreen
                                  : const Color(0xFFF0FDF4),
                              side: BorderSide(
                                color: AppTheme.primaryGreen.withAlpha(60),
                              ),
                              label: Text(
                                quickLoc.fullDisplayLabel(lang),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: (_activeLocality == quickLoc.id ||
                                          (_activeLocality == null &&
                                              _activeDistrict == quickLoc.id))
                                      ? Colors.white
                                      : const Color(0xFF1B5E20),
                                ),
                              ),
                              onPressed: () async {
                                await LocationService.saveManualLocality(
                                  quickLoc,
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(
                                    ctx,
                                    (
                                      district: quickLoc.district,
                                      locality: quickLoc.id == quickLoc.district
                                          ? null
                                          : quickLoc.id,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List of Matching Towns & Regions
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: searchResults.isNotEmpty
                          ? searchResults.length
                          : AppConstants.districts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, idx) {
                        if (searchResults.isNotEmpty) {
                          final loc = searchResults[idx];
                          final isCurrent = (_activeLocality != null &&
                                  _activeLocality == loc.id) ||
                              (_activeLocality == null &&
                                  _activeDistrict == loc.id);
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
                              loc.fullDisplayLabel(lang),
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? const Color(0xFF1B5E20)
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${loc.lat.toStringAsFixed(2)}°N, ${loc.lon.toStringAsFixed(2)}°E',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
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
                              await LocationService.saveManualLocality(loc);
                              if (ctx.mounted) {
                                Navigator.pop(
                                  ctx,
                                  (
                                    district: loc.district,
                                    locality: loc.id == loc.district
                                        ? null
                                        : loc.id,
                                  ),
                                );
                              }
                            },
                          );
                        }

                        final d = AppConstants.districts[idx];
                        final isCurrent =
                            d == _activeDistrict && _activeLocality == null;
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
                            if (ctx.mounted) {
                              Navigator.pop(
                                ctx,
                                (district: d, locality: null),
                              );
                            }
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

    if (selected != null && mounted) {
      setState(() {
        _activeDistrict = selected.district;
        _activeLocality = selected.locality;
        _selectedDayOffset = 0;
      });
      await _loadWeather(forceRefresh: true);
      await _loadCheckedTasks();
      widget.onDistrictChanged?.call(selected.district);
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
          en: 'Clear Sky',
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
        return isSelected ? Icons.wb_sunny_rounded : Icons.wb_sunny_outlined;
    }
  }

  Color _accentForCondition(String condition) {
    switch (condition) {
      case 'rain':
        return const Color(0xFF38BDF8);
      case 'snow':
        return const Color(0xFFBAE6FD);
      case 'thunderstorm':
        return const Color(0xFFC084FC);
      case 'partly_cloudy':
      case 'cloudy':
        return const Color(0xFF94A3B8);
      case 'cold':
        return const Color(0xFF60A5FA);
      case 'hot':
      case 'clear':
      default:
        return const Color(0xFFFBBF24);
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

    final weather = _weather ??
        WeatherData.seasonalFallback(
          districtName: _activeDistrict,
          locality: _activeLocality,
        );
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

    final displayLocationTitle = LocationService.formatLocationLabel(
      district: weather.districtName,
      locality: _activeLocality ?? weather.locality,
      lang: lang,
    );

    final heatingDelta = (selectedTargetTemp - activeForecast.tempAvg).round();
    final String deltaText;
    final Color deltaColor;
    if (heatingDelta > 2) {
      deltaText = AppStrings.tr(
        lang: lang,
        uz: '+$heatingDelta°C isitish',
        ru: '+$heatingDelta°C обогрев',
        en: 'Heat +$heatingDelta°C',
      );
      deltaColor = const Color(0xFFFBBF24);
    } else if (heatingDelta < -2) {
      deltaText = AppStrings.tr(
        lang: lang,
        uz: '${heatingDelta.abs()}°C sovitish',
        ru: '${heatingDelta.abs()}°C охлаждение',
        en: 'Cool ${heatingDelta.abs()}°C',
      );
      deltaColor = const Color(0xFF38BDF8);
    } else {
      deltaText = AppStrings.tr(
        lang: lang,
        uz: 'Ideal muvozanat',
        ru: 'Баланс в норме',
        en: 'Balanced',
      );
      deltaColor = const Color(0xFF4ADE80);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
                      colors: [Color(0xFF0B2214), Color(0xFF1E3A2B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Deep Rich Obsidian-Emerald Multi-Stop Scrim for High Legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0B2214).withAlpha(195),
                      const Color(0xFF0F172A).withAlpha(155),
                      const Color(0xFF091A10).withAlpha(225),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Spacious, Structured Card Content
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SECTION 1: Spacious Location Pill & Audio/Refresh Controls
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TactileCard(
                          onTap: _openLocationPickerSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(28),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(48),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF22C55E).withAlpha(45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF4ADE80),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayLocationTitle,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.unfold_more_rounded,
                                            color: Colors.white70,
                                            size: 15,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const PulseBeacon(
                                            size: 5,
                                            color: Color(0xFF4ADE80),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              weather.isLive
                                                  ? AppStrings.tr(
                                                      lang: lang,
                                                      uz: 'GPS • Jonli ob-havo',
                                                      ru: 'GPS • Точная погода',
                                                      en: 'GPS • Live Weather',
                                                    )
                                                  : AppStrings.tr(
                                                      lang: lang,
                                                      uz: 'Hududni tanlash uchun bosing',
                                                      ru: 'Нажмите для выбора района',
                                                      en: 'Tap to change town/region',
                                                    ),
                                              style: TextStyle(
                                                color:
                                                    Colors.white.withAlpha(190),
                                                fontSize: 10.5,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                          color: Colors.white.withAlpha(32),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(55),
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
                              size: 17,
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
                  const SizedBox(height: 10),

                  // SECTION 2: Dual-Climate Split Hero (Outdoor Weather vs. Ross-308 Barn Norm)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Panel: Actual Outdoor Weather
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(24),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withAlpha(45),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        AppStrings.tr(
                                          lang: lang,
                                          uz: 'Tashqi ob-havo',
                                          ru: 'На улице',
                                          en: 'Outdoor Weather',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(200),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _AmbientWeatherGlyph(
                                      icon: _iconForCondition(
                                        activeForecast.condition,
                                        isSelected: true,
                                      ),
                                      color: _accentForCondition(
                                        activeForecast.condition,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
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
                                    '${activeForecast.tempAvg.toStringAsFixed(1)}°C',
                                    key: ValueKey<String>(
                                      'out_${_selectedDayOffset}_${activeForecast.tempAvg.toStringAsFixed(1)}',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(75),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$conditionLabel • ${activeForecast.humidity}%',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right Panel: Ross-308 Indoor Brooder Target
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF59E0B).withAlpha(48),
                                  const Color(0xFF15803D).withAlpha(42),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFFBBF24).withAlpha(90),
                                width: 1.1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFFF59E0B).withAlpha(65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppStrings.tr(
                                      lang: lang,
                                      uz: '$selectedBatchDay-kun • Ross-308',
                                      ru: '$selectedBatchDay-й день • Ross-308',
                                      en: 'Day $selectedBatchDay • Ross-308',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFFFEF08A),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        AppStrings.tr(
                                          lang: lang,
                                          uz: "Bino me'yori",
                                          ru: 'В птичнике',
                                          en: 'Barn Norm',
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(200),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(75),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.thermostat_rounded,
                                        size: 12,
                                        color: deltaColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          deltaText,
                                          style: TextStyle(
                                            color: deltaColor,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SECTION 3: 6-Day Outdoor Weather Timeline (D-2 through D+3)
                  // Shows actual outdoor forecast temperatures (NOT indoor brooder target!)
                  Row(
                    children: [
                      for (final offset in const [-2, -1, 0, 1, 2, 3]) ...[
                        if (offset > -2) const SizedBox(width: 6),
                        Expanded(
                          child: _buildForecastPill(
                            dayOffset: offset,
                            label: offset == 0
                                ? todayLabel
                                : (offset < 0 ? 'D$offset' : 'D+$offset'),
                            condition: weather.forecastForOffset(offset).condition,
                            outdoorTemp:
                                '${weather.forecastForOffset(offset).tempAvg.round()}°',
                            isSelected: _selectedDayOffset == offset,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),

                  // SECTION 4: Interactive Telemetry Metric Chips (Wind, Humidity, Outdoor Range)
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
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(125),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFBBF24).withAlpha(80),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 9),

                  // SECTION 5: Full-Width Microclimate Status & Checklist Toggle Bar
                  TactileCard(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withAlpha(55),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              advice.statusBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(70),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              AppStrings.tr(
                                lang: lang,
                                uz: 'Tavsiya ($doneCount/${checklist.length})',
                                ru: 'Задачи ($doneCount/${checklist.length})',
                                en: 'Checklist ($doneCount/${checklist.length})',
                              ),
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable Detailed Technical Advice + Interactive Check-off Tasks
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(115),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.white.withAlpha(45),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
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
                          const SizedBox(height: 4),
                          Text(
                            "${advice.ventilationAdvice} • ${advice.waterFeedAdvice}",
                            style: TextStyle(
                              color: Colors.white.withAlpha(210),
                              fontSize: 11,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          for (int i = 0; i < checklist.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: GestureDetector(
                                onTap: () => _toggleTaskCheck(i),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
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
                                        width: 17,
                                        height: 17,
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
                                                size: 11,
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
                                            fontSize: 11.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withAlpha(220)
              : Colors.white.withAlpha(28),
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
            Icon(icon, size: 13.5, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
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
    required String condition,
    required String outdoorTemp,
    required bool isSelected,
  }) {
    final bgColor = isSelected
        ? const Color(0xFFF59E0B)
        : Colors.white.withAlpha(26);
    final borderColor = isSelected
        ? const Color(0xFFFDE68A)
        : Colors.white.withAlpha(45);
    final iconColor =
        isSelected ? Colors.white : _accentForCondition(condition);

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
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withAlpha(110),
                      blurRadius: 10,
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
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white.withAlpha(210),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Icon(
                _iconForCondition(condition, isSelected: isSelected),
                size: 18,
                color: iconColor,
              ),
              const SizedBox(height: 5),
              Text(
                outdoorTemp,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen : Colors.white.withAlpha(32),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(55),
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

/// Ambient floating weather icon with GPU-accelerated scale & translate micro-motion.
/// Automatically settles in `flutter_test` environments and honors `prefers-reduced-motion`.
class _AmbientWeatherGlyph extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AmbientWeatherGlyph({
    required this.icon,
    required this.color,
  });

  @override
  State<_AmbientWeatherGlyph> createState() => _AmbientWeatherGlyphState();
}

class _AmbientWeatherGlyphState extends State<_AmbientWeatherGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return Icon(widget.icon, color: widget.color, size: 22);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dy = (_controller.value - 0.5) * 3.0;
          final scale = 0.96 + (_controller.value * 0.08);
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(38),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

