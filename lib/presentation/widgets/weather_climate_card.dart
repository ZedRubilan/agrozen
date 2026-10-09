import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/weather_data.dart';
import '../../domain/climate/climate_advisor.dart';
import '../../services/tts_service.dart';
import '../../services/weather_service.dart';

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
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
    final data = await _weatherService.getWeatherForDistrict(
      widget.district,
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      setState(() {
        _weather = data;
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = widget.language;

    if (_isLoading && _weather == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Ob-havo ma\'lumotlari yuklanmoqda...'),
              ],
            ),
          ),
        ),
      );
    }

    final weather = _weather ??
        WeatherData.seasonalFallback(districtName: widget.district);

    final advice = ClimateAdvisor.evaluate(
      flockAgeDays: widget.batchDay,
      outsideTemp: weather.temperature,
      outsideHumidity: weather.humidity.toDouble(),
      targetHouseTemp: widget.targetHouseTemp,
      lang: lang,
    );

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    switch (advice.riskLevel) {
      case ClimateRiskLevel.heatWarning:
        badgeColor = Colors.orange.shade900;
        badgeBg = Colors.orange.shade50;
        badgeIcon = Icons.whatshot_rounded;
        break;
      case ClimateRiskLevel.coldWarning:
        badgeColor = Colors.blue.shade900;
        badgeBg = Colors.blue.shade50;
        badgeIcon = Icons.ac_unit_rounded;
        break;
      case ClimateRiskLevel.highHumidityRisk:
        badgeColor = Colors.teal.shade900;
        badgeBg = Colors.teal.shade50;
        badgeIcon = Icons.water_drop_rounded;
        break;
      case ClimateRiskLevel.dryAirRisk:
        badgeColor = Colors.amber.shade900;
        badgeBg = Colors.amber.shade50;
        badgeIcon = Icons.grain_rounded;
        break;
      case ClimateRiskLevel.optimal:
        badgeColor = Colors.green.shade900;
        badgeBg = Colors.green.shade50;
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Region & Weather Summary + Refresh + TTS
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.cloud_outlined,
                      color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.districtName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${weather.conditionText} • ${weather.temperature.toStringAsFixed(1)}°C (RH ${weather.humidity.toStringAsFixed(0)}%)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ovozli eshitish',
                  icon: Icon(
                    _isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    color: _isSpeaking
                        ? theme.colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                  onPressed: () => _toggleTts(advice),
                ),
                IconButton(
                  tooltip: 'Yangilash',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => _loadWeather(forceRefresh: true),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comparison Metrics: Shed Target vs Ambient Weather
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      label: AppStrings.tr(
                        lang: lang,
                        uz: 'Bino me\'yori',
                        ru: 'Норма птичника',
                        en: 'House Target',
                      ),
                      value: '${widget.targetHouseTemp.toStringAsFixed(1)}°C',
                      icon: Icons.thermostat_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(height: 28, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricItem(
                      label: AppStrings.tr(
                        lang: lang,
                        uz: 'Tashqi harorat',
                        ru: 'На улице',
                        en: 'Outdoor Temp',
                      ),
                      value: '${weather.temperature.toStringAsFixed(1)}°C',
                      icon: Icons.wb_sunny_outlined,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Container(height: 28, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricItem(
                      label: AppStrings.tr(
                        lang: lang,
                        uz: 'Tashqi namlik',
                        ru: 'Влажность',
                        en: 'Outdoor RH',
                      ),
                      value: '${weather.humidity.toStringAsFixed(0)}%',
                      icon: Icons.water_drop_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Thermal Stress Badge & Direct Directive
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(badgeIcon, color: badgeColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          advice.statusBadge,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    advice.directive,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Expandable Detailed Technical Advice (Ventilation & Drinkers)
            if (_isExpanded) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                title: AppStrings.tr(
                  lang: lang,
                  uz: "Shamollatish ko'rsatmasi",
                  ru: 'Вентиляция',
                  en: 'Ventilation Directive',
                ),
                content: advice.ventilationAdvice,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 6),
              _buildDetailItem(
                title: AppStrings.tr(
                  lang: lang,
                  uz: 'Suv va ozuqa rejimi',
                  ru: 'Вода и корм',
                  en: 'Water & Feeding',
                ),
                content: advice.waterFeedAdvice,
                color: Colors.teal,
              ),
            ],

            // Expand/Collapse toggle button
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? AppStrings.tr(
                              lang: lang,
                              uz: 'Kamroq ko\'rsatish',
                              ru: 'Свернуть',
                              en: 'Show less',
                            )
                          : AppStrings.tr(
                              lang: lang,
                              uz: 'Batafsil tavsiyalar',
                              ru: 'Подробные рекомендации',
                              en: 'Detailed recommendations',
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required String title,
    required String content,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.shade50.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
