import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../domain/broiler/broiler_grower_library.dart';

/// Interactive Ross-308 Broiler Grower Toolkit & Library Card.
/// Provides:
/// 1. 42-Day Interactive Precision Matrix (Weight, Feed kg, Water L, Light/Dark, Density).
/// 2. Live FCR, EPEF Efficiency Index, Nipple/Feeder & Barn Area Calculator.
/// 3. Built-in Broiler Grower Reference Library with Prompt Enhancer integration.
class BroilerGrowerToolkitCard extends StatefulWidget {
  final int batchDay;
  final int initialCount;
  final int currentCount;
  final String language;
  final ValueChanged<String>? onAskEnhancedPrompt;

  const BroilerGrowerToolkitCard({
    super.key,
    required this.batchDay,
    required this.initialCount,
    required this.currentCount,
    required this.language,
    this.onAskEnhancedPrompt,
  });

  @override
  State<BroilerGrowerToolkitCard> createState() =>
      _BroilerGrowerToolkitCardState();
}

class _BroilerGrowerToolkitCardState extends State<BroilerGrowerToolkitCard> {
  int _activeTab = 0; // 0: Daily Specs, 1: FCR & Equipment Calc, 2: Grower Guides
  late int _selectedDay;
  late double _simulatedWeightG;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.batchDay.clamp(1, 42);
    _simulatedWeightG =
        BroilerGrowerLibrary.specForDay(_selectedDay).targetWeightG;
  }

  @override
  void didUpdateWidget(covariant BroilerGrowerToolkitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batchDay != widget.batchDay) {
      _selectedDay = widget.batchDay.clamp(1, 42);
      _simulatedWeightG =
          BroilerGrowerLibrary.specForDay(_selectedDay).targetWeightG;
    }
  }

  void _selectDay(int day) {
    final clamped = day.clamp(1, 42);
    setState(() {
      _selectedDay = clamped;
      _simulatedWeightG =
          BroilerGrowerLibrary.specForDay(clamped).targetWeightG;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final req = BroilerGrowerLibrary.calculateFlockRequirements(
      day: _selectedDay,
      birdCount: widget.currentCount,
    );
    final spec = req.spec;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Banner (Deep Forest Emerald)
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2E1C), Color(0xFF1B4D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4ADE80).withAlpha(90),
                        ),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Color(0xFF4ADE80),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr(
                              lang: lang,
                              uz: 'Ross-308 Broyler O\'stirish Markazi',
                              ru: 'Центр Выращивания Бройлеров Ross-308',
                              en: 'Ross-308 Broiler Grower Hub',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.tr(
                              lang: lang,
                              uz: '${widget.currentCount} bosh • ${spec.phaseTitle(lang)}',
                              ru: '${widget.currentCount} голов • ${spec.phaseTitle(lang)}',
                              en: '${widget.currentCount} birds • ${spec.phaseTitle(lang)}',
                            ),
                            style: TextStyle(
                              color: const Color(0xFFA7F3D0).withAlpha(230),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Smart Prompt Enhancer Badge
                    if (widget.onAskEnhancedPrompt != null)
                      InkWell(
                        onTap: () {
                          final enhanced =
                              FarmerPromptEnhancer.enhanceFarmerPrompt(
                            rawInput: '',
                            lang: lang,
                            batchDay: _selectedDay,
                            birdCount: widget.currentCount,
                          );
                          widget.onAskEnhancedPrompt!(enhanced);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.tr(
                                  lang: lang,
                                  uz: 'AI Prompt',
                                  ru: 'AI Промпт',
                                  en: 'AI Prompt',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // 3-Tab Segmented Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        index: 0,
                        icon: Icons.tune_rounded,
                        label: AppStrings.tr(
                          lang: lang,
                          uz: 'Me\'yorlar',
                          ru: 'Нормы дня',
                          en: 'Daily Specs',
                        ),
                      ),
                      _buildTabButton(
                        index: 1,
                        icon: Icons.calculate_rounded,
                        label: AppStrings.tr(
                          lang: lang,
                          uz: 'FCR & Joy',
                          ru: 'FCR & Площадь',
                          en: 'FCR & Calc',
                        ),
                      ),
                      _buildTabButton(
                        index: 2,
                        icon: Icons.menu_book_rounded,
                        label: AppStrings.tr(
                          lang: lang,
                          uz: 'Qo\'llanma',
                          ru: 'Справочник',
                          en: 'Library',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _activeTab == 0
                ? _buildDailySpecsTab(lang, req, spec)
                : (_activeTab == 1
                    ? _buildFcrCalculatorTab(lang, req, spec)
                    : _buildGrowerLibraryTab(context, lang, req, spec)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TAB 0: Interactive 42-Day Broiler Specs Matrix
  Widget _buildDailySpecsTab(
    String lang,
    FlockDailyRequirements req,
    BroilerDaySpec spec,
  ) {
    const milestoneDays = [1, 3, 7, 10, 14, 21, 28, 35, 42];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Milestone Day Selector Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tr(
                lang: lang,
                uz: 'Kunni tanlang (1–42 kun):',
                ru: 'Выберите день цикла (1–42):',
                en: 'Select cycle day (1–42):',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              AppStrings.tr(
                lang: lang,
                uz: '${spec.day}-kun • FCR ${spec.targetFcr}',
                ru: 'День ${spec.day} • FCR ${spec.targetFcr}',
                en: 'Day ${spec.day} • FCR ${spec.targetFcr}',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: milestoneDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final d = milestoneDays[idx];
              final isSelected = _selectedDay == d;
              return GestureDetector(
                onTap: () => _selectDay(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF14532D)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.tr(
                        lang: lang,
                        uz: '$d-kun',
                        ru: '$d дн.',
                        en: 'Day $d',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Precision Metrics for the Flock
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.monitor_weight_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFF0FDF4),
                label: AppStrings.tr(
                  lang: lang,
                  uz: 'Etalon Vazn',
                  ru: 'Эталон веса',
                  en: 'Target Weight',
                ),
                value: '${spec.targetWeightG.toStringAsFixed(0)} g',
                sub: AppStrings.tr(
                  lang: lang,
                  uz: '+${spec.dailyGainG.toStringAsFixed(0)} g/kun o\'sish',
                  ru: '+${spec.dailyGainG.toStringAsFixed(0)} г/сутки привес',
                  en: '+${spec.dailyGainG.toStringAsFixed(0)} g/day gain',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.grain_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                label: AppStrings.tr(
                  lang: lang,
                  uz: 'Kunlik Yem (${widget.currentCount} bosh)',
                  ru: 'Корм в сутки (${widget.currentCount} гол.)',
                  en: 'Daily Feed (${widget.currentCount} birds)',
                ),
                value: '${req.totalDailyFeedKg.toStringAsFixed(1)} kg',
                sub: '${spec.dailyFeedPerBirdG.toStringAsFixed(0)} g/bosh • ${spec.crudeProteinPct}% CP',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                label: AppStrings.tr(
                  lang: lang,
                  uz: 'Kunlik Suv & Nippel',
                  ru: 'Вода в сутки и ниппели',
                  en: 'Daily Water & Nipples',
                ),
                value: '${req.totalDailyWaterLiters.toStringAsFixed(1)} L',
                sub: AppStrings.tr(
                  lang: lang,
                  uz: '${spec.dailyWaterPerBirdMl.toStringAsFixed(0)} ml/bosh • ${req.recommendedNipples} nippel',
                  ru: '${spec.dailyWaterPerBirdMl.toStringAsFixed(0)} мл/гол • ${req.recommendedNipples} ниппелей',
                  en: '${spec.dailyWaterPerBirdMl.toStringAsFixed(0)} mL/bird • ${req.recommendedNipples} nipples',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.wb_incandescent_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                label: AppStrings.tr(
                  lang: lang,
                  uz: 'Yorug\'lik & Zichlik',
                  ru: 'Свет и Плотность',
                  en: 'Light & Density',
                ),
                value: '${spec.lightHours}s / ${spec.darkHours}s',
                sub: AppStrings.tr(
                  lang: lang,
                  uz: '${spec.lightIntensityLux} lyuks • max ${spec.maxBirdsPerSqMeter} bosh/m²',
                  ru: '${spec.lightIntensityLux} люкс • до ${spec.maxBirdsPerSqMeter} гол/м²',
                  en: '${spec.lightIntensityLux} lux • max ${spec.maxBirdsPerSqMeter}/m²',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ration & Agronomist Daily Focus Tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      spec.feedFormDescription(lang),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                spec.dailyFocusTip(lang),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TAB 1: Interactive FCR, EPEF & Barn Equipment Calculator
  Widget _buildFcrCalculatorTab(
    String lang,
    FlockDailyRequirements req,
    BroilerDaySpec spec,
  ) {
    final report = BroilerGrowerLibrary.evaluateEfficiency(
      batchDay: _selectedDay,
      initialCount: widget.initialCount,
      currentCount: widget.currentCount,
      actualAverageWeightG: _simulatedWeightG,
    );

    final Color gradeColor = report.grade == 'A+'
        ? const Color(0xFF16A34A)
        : (report.grade == 'B'
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weight Slider to test live FCR & EPEF
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tr(
                lang: lang,
                uz: "O'rtacha jo'ja vazni ($_selectedDay-kun):",
                ru: 'Средний вес птицы ($_selectedDay-й день):',
                en: 'Average bird weight (Day $_selectedDay):',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${_simulatedWeightG.toStringAsFixed(0)} g '
              '(${report.weightDeltaPct >= 0 ? '+' : ''}${report.weightDeltaPct.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: gradeColor,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF16A34A),
            inactiveTrackColor: const Color(0xFFDCFCE7),
            thumbColor: const Color(0xFF14532D),
            overlayColor: const Color(0xFF16A34A).withAlpha(30),
          ),
          child: Slider(
            min: (spec.targetWeightG * 0.6).clamp(30.0, 2500.0),
            max: (spec.targetWeightG * 1.35).clamp(80.0, 4200.0),
            value: _simulatedWeightG.clamp(
              (spec.targetWeightG * 0.6).clamp(30.0, 2500.0),
              (spec.targetWeightG * 1.35).clamp(80.0, 4200.0),
            ),
            onChanged: (v) => setState(() => _simulatedWeightG = v),
          ),
        ),

        // Efficiency & Barn Space Metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.analytics_rounded,
                iconColor: gradeColor,
                bgColor: gradeColor.withAlpha(18),
                label: AppStrings.tr(
                  lang: lang,
                  uz: 'EPEF & FCR Indeksi',
                  ru: 'Индекс EPEF и FCR',
                  en: 'EPEF & FCR Index',
                ),
                value: 'EPEF ${report.epefScore} (${report.grade})',
                sub: 'FCR: ${report.actualFcr.toStringAsFixed(2)} (Me\'yor ${report.targetFcr})',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.square_foot_rounded,
                iconColor: const Color(0xFF0F766E),
                bgColor: const Color(0xFFF0FDFA),
                label: AppStrings.tr(
                  lang: lang,
                  uz: 'Kerakli Xona Maydoni',
                  ru: 'Нужная площадь пола',
                  en: 'Required Barn Area',
                ),
                value: '${req.requiredBarnAreaCurrentSqM.toStringAsFixed(1)} m²',
                sub: AppStrings.tr(
                  lang: lang,
                  uz: '42-kunga: ${req.requiredBarnAreaHarvestSqM.toStringAsFixed(0)} m² (${req.recommendedFeederPans} yemdon)',
                  ru: 'К 42 дню: ${req.requiredBarnAreaHarvestSqM.toStringAsFixed(0)} м² (${req.recommendedFeederPans} кормушек)',
                  en: 'At Day 42: ${req.requiredBarnAreaHarvestSqM.toStringAsFixed(0)} m² (${req.recommendedFeederPans} pans)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gradeColor.withAlpha(80)),
          ),
          child: Text(
            report.gradeSummary(lang),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// TAB 2: Built-in Broiler Grower Library & Enhanced Prompt Triggers
  Widget _buildGrowerLibraryTab(
    BuildContext context,
    String lang,
    FlockDailyRequirements req,
    BroilerDaySpec spec,
  ) {
    final guides = [
      {
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFD97706),
        'title': AppStrings.tr(
          lang: lang,
          uz: 'Yorug\'lik va Zichlik (1–42 kun)',
          ru: 'Свет и Плотность посадки (1–42)',
          en: 'Lighting & Stocking Density (1–42)',
        ),
        'sub': AppStrings.tr(
          lang: lang,
          uz: '${spec.lightHours}s yorug\' / ${spec.darkHours}s qorong\'u • ${spec.maxBirdsPerSqMeter} bosh/m²',
          ru: '${spec.lightHours}ч света / ${spec.darkHours}ч темноты • ${spec.maxBirdsPerSqMeter} гол/м²',
          en: '${spec.lightHours}h light / ${spec.darkHours}h dark • ${spec.maxBirdsPerSqMeter} birds/m²',
        ),
        'rawPrompt': 'yorug\'lik va zichlik',
      },
      {
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF16A34A),
        'title': AppStrings.tr(
          lang: lang,
          uz: 'Tez O\'sish, FCR va Vazn Nazorati',
          ru: 'Быстрый Рост, FCR и Контроль Веса',
          en: 'Rapid Growth, FCR & Weight Control',
        ),
        'sub': AppStrings.tr(
          lang: lang,
          uz: 'Etalon ${spec.targetWeightG.toStringAsFixed(0)} g • FCR ${spec.targetFcr}',
          ru: 'Эталон ${spec.targetWeightG.toStringAsFixed(0)} г • FCR ${spec.targetFcr}',
          en: 'Target ${spec.targetWeightG.toStringAsFixed(0)}g • FCR ${spec.targetFcr}',
        ),
        'rawPrompt': 'broyler vazn va fcr',
      },
      {
        'icon': Icons.grain_rounded,
        'color': const Color(0xFFEA580C),
        'title': AppStrings.tr(
          lang: lang,
          uz: 'Yemlash Fazalari va Oqsil (% CP)',
          ru: 'Фазы Кормления и Протеин (% CP)',
          en: 'Feeding Phases & Protein (% CP)',
        ),
        'sub': spec.feedFormDescription(lang),
        'rawPrompt': 'yemlash fazalari va granula',
      },
      {
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF0284C7),
        'title': AppStrings.tr(
          lang: lang,
          uz: 'Suv Me\'yori va Nippel Sozlash',
          ru: 'Норма Воды и Настройка Ниппелей',
          en: 'Water Intake & Nipple Setup',
        ),
        'sub': AppStrings.tr(
          lang: lang,
          uz: 'Kuniga ${req.totalDailyWaterLiters.toStringAsFixed(1)} L • ${req.recommendedNipples} nippel',
          ru: '${req.totalDailyWaterLiters.toStringAsFixed(1)} л/сут • ${req.recommendedNipples} ниппелей',
          en: '${req.totalDailyWaterLiters.toStringAsFixed(1)} L/day • ${req.recommendedNipples} nipples',
        ),
        'rawPrompt': 'suv va nippel sozlash',
      },
    ];

    return Column(
      children: guides.map((g) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              final enhanced = FarmerPromptEnhancer.enhanceFarmerPrompt(
                rawInput: g['rawPrompt'] as String,
                lang: lang,
                batchDay: _selectedDay,
                birdCount: widget.currentCount,
              );
              if (widget.onAskEnhancedPrompt != null) {
                widget.onAskEnhancedPrompt!(enhanced);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (g['color'] as Color).withAlpha(24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      g['icon'] as IconData,
                      color: g['color'] as Color,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['title'] as String,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g['sub'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
