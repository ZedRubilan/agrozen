import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/weather_data.dart';
import '../../domain/climate/climate_advisor.dart';
import '../../services/tts_service.dart';
import '../../services/weather_service.dart';

/// Image-first atmospheric Weather & Climate Card
/// Inspired by the cinematic sunset wheat field card in the reference designs.
class WeatherClimateCard extends StatefulWidget {
  final String district;
  final int batchDay;
  final double targetHouseTemp;
  final String language;

  const WeatherClimateCard({
    super.key,
    required this.district,
    required this.batchDay,
    required this.targetHouseTemp,
    required this.language,
  });

  @override
  State<WeatherClimateCard> createState() => _WeatherClimateCardState();
}

class _WeatherClimateCardState extends State<WeatherClimateCard> {
  final WeatherService _weatherService = WeatherService();
  final TtsService _ttsService = TtsService();

  WeatherData? _weather;
  bool _isSpeaking = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant WeatherClimateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.district != widget.district) {
      _loadWeather();
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    final data = await _weatherService.getWeatherForDistrict(
      widget.district,
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

  String _localizedConditionText(String condition, String lang) {
    switch (condition) {
      case 'snow':
        return AppStrings.tr(lang: lang, uz: 'Qorli', ru: 'Снег', en: 'Snowy');
      case 'thunderstorm':
        return AppStrings.tr(lang: lang, uz: 'Momaqaldiroq', ru: 'Гроза', en: 'Thunderstorm');
      case 'partly_cloudy':
        return AppStrings.tr(lang: lang, uz: 'Yarim bulutli', ru: 'Переменная облачность', en: 'Partly Cloudy');
      case 'rain':
        return AppStrings.tr(lang: lang, uz: "Yomg'irli", ru: 'Дождь', en: 'Rainy');
      case 'cloudy':
        return AppStrings.tr(lang: lang, uz: 'Bulutli', ru: 'Облачно', en: 'Cloudy');
      case 'hot':
        return AppStrings.tr(lang: lang, uz: 'Issiq / Quyoshli', ru: 'Жарко / Солнечно', en: 'Hot / Sunny');
      case 'cold':
        return AppStrings.tr(lang: lang, uz: 'Sovuq', ru: 'Холодно', en: 'Cold');
      case 'clear':
      default:
        return AppStrings.tr(lang: lang, uz: 'Ochiq havo', ru: 'Ясно', en: 'Clear');
    }
  }

  int _targetTempForDayOffset(int dayOffset) {
    final targetDay = (widget.batchDay + dayOffset).clamp(1, 42);
    final actualDeltaDays = targetDay - widget.batchDay;
    return (widget.targetHouseTemp - actualDeltaDays * 0.38).clamp(18.0, 34.0).round();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    final weather = _weather ??
        WeatherData.seasonalFallback(districtName: widget.district);

    final advice = ClimateAdvisor.evaluate(
      flockAgeDays: widget.batchDay,
      outsideTemp: weather.temperature,
      outsideHumidity: weather.humidity.toDouble(),
      targetHouseTemp: widget.targetHouseTemp,
      lang: lang,
    );

    final dMinus2 = _targetTempForDayOffset(-2);
    final dMinus1 = _targetTempForDayOffset(-1);
    final currentTempInt = _targetTempForDayOffset(0);
    final dPlus1 = _targetTempForDayOffset(1);
    final dPlus2 = _targetTempForDayOffset(2);
    final dPlus3 = _targetTempForDayOffset(3);

    final conditionLabel = _localizedConditionText(weather.condition, lang);
    final todayLabel = AppStrings.tr(lang: lang, uz: 'Bugun', ru: 'Сегодня', en: 'Today');

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
                      Colors.black.withAlpha(140),
                      Colors.black.withAlpha(90),
                      Colors.black.withAlpha(180),
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
                  // Top Row: District & Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
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
                              child: Text(
                                "• $conditionLabel (${weather.temperature.toStringAsFixed(0)}°C, ${weather.humidity}%)",
                                style: TextStyle(
                                  color: Colors.white.withAlpha(215),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                          _buildGlassCircleButton(
                            icon: Icons.refresh_rounded,
                            onTap: () => _loadWeather(forceRefresh: true),
                            tooltip: AppStrings.tr(
                              lang: lang,
                              uz: 'Yangilash',
                              ru: 'Обновить',
                              en: 'Refresh',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Multi-Day Ross-308 Target Temperature Strip (decreasing as chicks grow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildForecastPill(label: 'D-2', icon: Icons.thermostat_rounded, temp: '$dMinus2°', isSelected: false),
                        const SizedBox(width: 8),
                        _buildForecastPill(label: 'D-1', icon: Icons.thermostat_rounded, temp: '$dMinus1°', isSelected: false),
                        const SizedBox(width: 8),
                        // Current Active Day in Radiant Amber
                        _buildForecastPill(label: todayLabel, icon: Icons.wb_sunny_rounded, temp: '$currentTempInt°', isSelected: true),
                        const SizedBox(width: 8),
                        _buildForecastPill(label: 'D+1', icon: Icons.thermostat_rounded, temp: '$dPlus1°', isSelected: false),
                        const SizedBox(width: 8),
                        _buildForecastPill(label: 'D+2', icon: Icons.thermostat_rounded, temp: '$dPlus2°', isSelected: false),
                        const SizedBox(width: 8),
                        _buildForecastPill(label: 'D+3', icon: Icons.thermostat_rounded, temp: '$dPlus3°', isSelected: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Area: Large Target Temperature + Outdoor Telemetry & Suitable Growth Pill Badge
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
                                uz: "${widget.batchDay}-kun • Ross-308",
                                ru: "${widget.batchDay}-й день • Ross-308",
                                en: "Day ${widget.batchDay} • Ross-308",
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
                                Text(
                                  '${widget.targetHouseTemp.toStringAsFixed(0)}°C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${AppStrings.tr(lang: lang, uz: "Me'yor", ru: 'Норма', en: 'Target')} • ${AppStrings.tr(lang: lang, uz: "Tashqi", ru: 'Улица', en: 'Out')}: ${weather.temperature.toStringAsFixed(0)}°C (${weather.humidity}%)',
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

                      // "Suitable for growth" pill badge with leaf icon (matching Image 3)
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
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
                                constraints: const BoxConstraints(maxWidth: 125),
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

                  // Expandable Detailed Technical Advice (Ventilation & Feeding)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(90),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.white.withAlpha(35),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            advice.directive,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${advice.ventilationAdvice} • ${advice.waterFeedAdvice}",
                            style: TextStyle(
                              color: Colors.white.withAlpha(210),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
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

  Widget _buildForecastPill({
    required String label,
    required IconData icon,
    required String temp,
    required bool isSelected,
  }) {
    final bgColor = isSelected ? const Color(0xFFF59E0B) : Colors.white.withAlpha(35);
    final borderColor = isSelected ? Colors.transparent : Colors.white.withAlpha(50);

    return Container(
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
