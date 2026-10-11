import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../domain/scheduler/day_calculator.dart';
import '../../domain/alerts/alert_engine.dart';
import '../../domain/alerts/alert_models.dart';
import '../widgets/alert_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/weather_climate_card.dart';
import '../widgets/flock_pathway_card.dart';
import '../widgets/loan_profit_tracker_card.dart';
import '../widgets/broiler_grower_toolkit_card.dart';
import '../widgets/simple_chicken_tracker_card.dart';
import '../widgets/animated_entry.dart';
import 'diary/diary_screen.dart';
import 'ask/ask_screen.dart';
import 'course/course_list_screen.dart';
import 'settings_screen.dart';
import '../../services/daily_counters.dart';
import '../../services/location_service.dart';
import '../../core/localization/app_strings.dart';

/// Redesigned HomeScreen:
/// - Photographic-first, ultra-rounded organic layout built for farmers.
/// - Progressive disclosure: only essential daily tracking appears up front;
///   advanced FCR/EPEF, 42-day pathway, and financial tools expand on demand.
/// - Swipeable PageView: seamless glide between Home, Diary, Voice AI, Courses, Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  int _currentNavIndex = 0;

  String _farmerName = 'Fermer';
  String _district = 'Toshkent';
  String _lang = 'uz';
  int _initialCount = 500;
  int _currentCount = 495;
  int _isolatedCount = 0;
  int _todayMortality = 0;
  double _todayFeed = 0.0;
  double _lastWeight = 0.0;
  bool _showAdvancedTools = false;
  DateTime _arrivalDate = DateTime.now();
  int _batchDay = 1;
  NormsData? _norms;
  Map<String, dynamic>? _vet;
  List<AlertResult> _alerts = [];
  bool _isLoading = true;
  bool _locationPromptResolved = true;
  bool _isDetectingHomeLocation = false;
  Locale? _observedLocale;
  String? _queuedEnhancedPrompt;

  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.maybeLocaleOf(context);
    if (_observedLocale != null &&
        currentLocale != null &&
        currentLocale != _observedLocale) {
      _observedLocale = currentLocale;
      _loadData(localeOverride: currentLocale.languageCode);
    } else {
      _observedLocale = currentLocale;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? localeOverride}) async {
    setState(() => _isLoading = true);
    final prefs = await DailyCounters.rolled();

    _farmerName = prefs.getString('farmer_name') ?? 'Fermer';
    _district = prefs.getString('farmer_district') ?? 'Toshkent';
    _lang = prefs.getString('app_language') ?? localeOverride ?? 'uz';
    _initialCount = prefs.getInt('initial_count') ?? 500;
    _currentCount = prefs.getInt('current_count') ?? _initialCount;
    _isolatedCount = DailyCounters.getIsolatedCount(prefs).clamp(0, _currentCount);
    _todayMortality = DailyCounters.getMortality(prefs);
    _todayFeed = DailyCounters.getFeed(prefs);
    _lastWeight = prefs.getDouble('last_weight') ?? 0.0;
    _locationPromptResolved = prefs.getBool('location_prompt_resolved') ?? false;

    final arrivalStr = prefs.getString('arrival_date');
    if (arrivalStr != null) {
      _arrivalDate = DateTime.parse(arrivalStr);
    }
    _batchDay = DayCalculator.calculateBatchDay(_arrivalDate).clamp(1, 42);

    _norms = await _knowledgeRepo.getParsedNorms();
    final vets = await _knowledgeRepo.getVetByDistrict(_district);
    _vet = vets.isNotEmpty ? vets.first : null;

    final evaluatedAlerts = <AlertResult>[];

    if (_norms != null) {
      final engine = AlertEngine(_norms!);
      if (_todayMortality > 0) {
        final mAlert = engine.checkMortality(
          deaths: _todayMortality,
          currentCount: _currentCount + _todayMortality,
        );
        if (mAlert != null) {
          evaluatedAlerts.add(mAlert);
        }
      }
      if (_lastWeight > 0) {
        final wAlert = engine.checkWeight(
          weightGrams: _lastWeight,
          batchDay: _batchDay,
        );
        if (wAlert != null) {
          evaluatedAlerts.add(wAlert);
        }
      }
    }
    _alerts = evaluatedAlerts;

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _updateIsolatedCount(int newCount) async {
    final prefs = await DailyCounters.rolled();
    final clamped = newCount.clamp(0, _currentCount);
    await DailyCounters.setIsolatedCount(
      prefs,
      clamped,
      maxCount: _currentCount,
    );
    if (!mounted) return;
    setState(() => _isolatedCount = clamped);
  }

  Future<void> _quickAddOneMortality() async {
    if (_currentCount <= 0) return;
    final prefs = await DailyCounters.rolled();
    await DailyCounters.addMortality(prefs, 1);
    final updatedCurrent = (_currentCount - 1).clamp(0, _initialCount);
    await prefs.setInt('current_count', updatedCurrent);
    if (_isolatedCount > updatedCurrent) {
      await DailyCounters.setIsolatedCount(
        prefs,
        updatedCurrent,
        maxCount: updatedCurrent,
      );
    }
    await _loadData();
  }

  Future<void> _enableHomeGeolocation() async {
    if (_isDetectingHomeLocation) return;
    setState(() => _isDetectingHomeLocation = true);
    final result = await _locationService.detectAndSaveLocation();
    if (!mounted) return;
    setState(() {
      _isDetectingHomeLocation = false;
      _locationPromptResolved = true;
    });
    if (result.success) {
      await _loadData();
    } else {
      await LocationService.markLocationPromptResolved();
    }
  }

  Future<void> _dismissLocationPrompt() async {
    await LocationService.markLocationPromptResolved();
    if (!mounted) return;
    setState(() => _locationPromptResolved = true);
  }

  int _getTemperatureForDay(int day) {
    final target = _norms?.temperatureTargetForDay(day);
    if (target != null) return target.round();
    return _fallbackTemperatureForDay(day);
  }

  static int _fallbackTemperatureForDay(int day) {
    if (day <= 2) return 34;
    if (day <= 4) return 33;
    if (day <= 7) return 32;
    if (day <= 14) return 29;
    if (day <= 21) return 27;
    if (day <= 28) return 24;
    if (day <= 35) return 22;
    return 20;
  }

  void _navigateToPage(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 0) {
      _loadData();
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetTemp = _getTemperatureForDay(_batchDay);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      bottomNavigationBar: _buildFloatingIslandNavBar(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            )
          : SafeArea(
              bottom: false,
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _currentNavIndex = idx);
                  if (idx == 0) {
                    _loadData();
                  }
                },
                children: [
                  // PAGE 0: Asosiy (Clean, Photographic Overview)
                  _buildHomeOverview(context, targetTemp),

                  // PAGE 1: Kundalik (Diary)
                  DiaryScreen(isEmbeddedInPageView: true),

                  // PAGE 2: Ovozli AI (Field Voice & Vision Assistant)
                  AskScreen(
                    startInFieldMode: true,
                    isEmbeddedInPageView: true,
                    initialPrompt: _queuedEnhancedPrompt,
                  ),

                  // PAGE 3: Kurs (Farmer Academy)
                  CourseListScreen(isEmbeddedInPageView: true),

                  // PAGE 4: Profil (Settings & Language)
                  SettingsScreen(isEmbeddedInPageView: true),
                ],
              ),
            ),
    );
  }

  /// PAGE 0: Ultra-Modern, Photographic, High-Craft Overview
  Widget _buildHomeOverview(BuildContext context, int targetTemp) {
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 18.0,
                  right: 18.0,
                  top: 10.0,
                  bottom: 110.0, // Floating Island Nav space
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Greeting Bar with Live Pulse Beacon & Avatar
                    StaggeredSlideFade(
                      index: 0,
                      child: _buildTopHeaderBar(context),
                    ),
                    const SizedBox(height: 12),

                    // 1a. Geolocation Prompt Banner on App Entry (if not yet resolved)
                    if (!_locationPromptResolved) ...[
                      _buildLocationPromptBanner(),
                      const SizedBox(height: 12),
                    ],

                    // 1b. 3 Quick Telemetry Status Pills (Barn Temp, Survival, Daily Care)
                    StaggeredSlideFade(
                      index: 1,
                      child: _buildTopTelemetryPills(context, targetTemp),
                    ),
                    const SizedBox(height: 14),

                    // Active Alert Banner(s) if any threshold is breached
                    for (final alert in _alerts)
                      AlertCard.fromAlertResult(
                        alert: alert,
                        locale: _lang,
                        vetPhone: _vet?['phone']?.toString(),
                        vetName: _vet?['name']?.toString(),
                      ),

                    // 2. Hero Panoramic Flock Sanctuary Card
                    StaggeredSlideFade(
                      index: 2,
                      child: _buildHeroFlockSanctuaryCard(context, targetTemp),
                    ),
                    const SizedBox(height: 14),

                    // 3. Simple 1-Tap Chicken Tracker & Categorizer (Healthy / Watchlist / Lost Today + Feed & Weight)
                    StaggeredSlideFade(
                      index: 3,
                      child: SimpleChickenTrackerCard(
                        batchDay: _batchDay,
                        initialCount: _initialCount,
                        currentCount: _currentCount,
                        isolatedCount: _isolatedCount,
                        todayMortality: _todayMortality,
                        todayFeedKg: _todayFeed,
                        lastWeightG: _lastWeight,
                        language: _lang,
                        onUpdateIsolatedCount: _updateIsolatedCount,
                        onQuickAddMortality: _quickAddOneMortality,
                        onOpenLogMortality: () async {
                          await context.push('/diary/mortality');
                          await _loadData();
                        },
                        onOpenLogFeed: () async {
                          await context.push('/diary/feed');
                          await _loadData();
                        },
                        onOpenLogWeight: () async {
                          await context.push('/diary/weight');
                          await _loadData();
                        },
                        onScanChickenPhoto: () => _navigateToPage(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Photographic Farmer Action Hub (4 Direct Workflows)
                    StaggeredSlideFade(
                      index: 4,
                      child: _buildPhotographicActionHub(context),
                    ),
                    const SizedBox(height: 16),

                    // 5. Atmospheric Weather & Microclimate Advisory Card
                    StaggeredSlideFade(
                      index: 5,
                      child: WeatherClimateCard(
                        district: _district,
                        batchDay: _batchDay,
                        targetHouseTemp: targetTemp.toDouble(),
                        language: _lang,
                        onDistrictChanged: (_) => _loadData(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Progressive Disclosure Section: Advanced Calculations & 42-Day Analytics (Collapsed by default)
                    StaggeredSlideFade(
                      index: 6,
                      child: _buildProgressiveDisclosureSection(
                        context,
                        targetTemp,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 7. Gentle Swipe Guidance Pill
                    StaggeredSlideFade(
                      index: 7,
                      child: _buildSwipeHintPill(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Progressive Disclosure Drawer: keeps the Home screen calm and uncluttered,
  /// revealing FCR/EPEF calculators, 42-day pathway, and financial tools only when needed.
  Widget _buildProgressiveDisclosureSection(
    BuildContext context,
    int targetTemp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showAdvancedTools = !_showAdvancedTools),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: _showAdvancedTools
                    ? const Color(0xFF86EFAC)
                    : AppTheme.cardBorder,
                width: 1.2,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFF15803D),
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
                          lang: _lang,
                          uz: "Qo'shimcha hisob-kitoblar va 42-kunlik tahlil",
                          ru: 'Доп. расчёты и аналитика (42 дня)',
                          en: 'More Tools & 42-Day Analytics',
                        ),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: _showAdvancedTools
                              ? 'Yopish uchun bosing'
                              : 'FCR kalkulyatori, 42-kun jadvali va daromad hisobi (kerak bo\'lganda oching)',
                          ru: _showAdvancedTools
                              ? 'Нажмите, чтобы свернуть'
                              : 'Калькулятор FCR, график 42 дней и расчёт прибыли (откройте при необходимости)',
                          en: _showAdvancedTools
                              ? 'Tap to hide advanced tools'
                              : 'FCR calculator, 42-day pathway & profit tracker (open when needed)',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showAdvancedTools
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF15803D),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_showAdvancedTools) ...[
          const SizedBox(height: 16),
          BroilerGrowerToolkitCard(
            batchDay: _batchDay,
            initialCount: _initialCount,
            currentCount: _currentCount,
            language: _lang,
            onAskEnhancedPrompt: (enhancedPrompt) {
              setState(() => _queuedEnhancedPrompt = enhancedPrompt);
              _navigateToPage(2);
            },
          ),
          const SizedBox(height: 16),
          FlockPathwayCard(
            batchDay: _batchDay,
            language: _lang,
            onOpenPlan: () => context.push('/daily-plan'),
          ),
          const SizedBox(height: 16),
          LoanProfitTrackerCard(
            initialCount: _initialCount,
            currentCount: _currentCount,
            batchDay: _batchDay,
            language: _lang,
          ),
          const SizedBox(height: 16),
          _buildTelemetryStatsRow(context, targetTemp),
          const SizedBox(height: 16),
          _buildChooseYourFarmSection(context),
        ],
      ],
    );
  }

  // --- SUB-WIDGETS ---

  /// Geolocation Prompt Banner shown on app entry until resolved
  Widget _buildLocationPromptBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F291A), Color(0xFF1A3D29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF34D399).withAlpha(110),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: _isDetectingHomeLocation
                ? const Padding(
                    padding: EdgeInsets.all(9.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6EE7B7),
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF6EE7B7),
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
                    lang: _lang,
                    uz: 'Geolokatsiyani yoqasizmi?',
                    ru: 'Включить геолокацию фермы?',
                    en: 'Turn on farm geolocation?',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.tr(
                    lang: _lang,
                    uz: "Hududingiz va aniq ob-havo avtomatik aniqlanadi (Sozlamalarda o'zgartirish mumkin)",
                    ru: 'Автовыбор региона и точной погоды (можно изменить в Настройках)',
                    en: 'Auto-picks your region for real weather (changeable in Settings)',
                  ),
                  style: TextStyle(
                    color: const Color(0xFFA7F3D0).withAlpha(220),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _enableHomeGeolocation,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.tr(lang: _lang, uz: 'Yoqish', ru: 'Вкл.', en: 'Turn On'),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _dismissLocationPrompt,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.white.withAlpha(170),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Greeting Bar with Live Status Beacon & Avatar
  Widget _buildTopHeaderBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'Assalomu alaykum, $_farmerName!',
                        ru: 'Здравствуйте, $_farmerName!',
                        en: 'Hello, $_farmerName!',
                      ),
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const PulseBeacon(size: 7, color: Color(0xFF22C55E)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: '$_district viloyati • Ross-308',
                  ru: '$_district обл. • Ross-308',
                  en: '$_district region • Ross-308',
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Rounded Farmer Profile Photo
        TactileCard(
          onTap: () => _navigateToPage(4),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: Image.asset(
                'assets/images/farmer_avatar.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.primaryGreen,
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3 Quick Telemetry Status Pills (Barn Temp, Flock Survival, Daily Care)
  Widget _buildTopTelemetryPills(BuildContext context, int targetTemp) {
    final survivalPct = _initialCount > 0
        ? ((_currentCount * 100.0) / _initialCount).clamp(0.0, 100.0)
        : 100.0;
    final stageName = _batchDay <= 10
        ? AppStrings.tr(lang: _lang, uz: 'Start faza', ru: 'Фаза Старт', en: 'Starter')
        : (_batchDay <= 24
            ? AppStrings.tr(lang: _lang, uz: "O'sish fazasi", ru: 'Фаза Рост', en: 'Grower')
            : AppStrings.tr(lang: _lang, uz: 'Finish faza', ru: 'Фаза Финиш', en: 'Finisher'));

    return Row(
      children: [
        // Pill 1: Target Barn Temp
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFEF08A), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.thermostat_rounded, size: 18, color: Color(0xFFD97706)),
                    Text(
                      '$targetTemp °C',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF854D0E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Bino harorati', ru: 'Темп. птичника', en: 'Barn Temp'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF713F12), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.tr(lang: _lang, uz: "Me'yor • Ross-308", ru: 'Норма • Ross-308', en: 'Norm • Ross-308'),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF713F12), fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Pill 2: Flock Survival & Health
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 17, color: Color(0xFF16A34A)),
                    Text(
                      '${survivalPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Poda saqlanishi', ru: 'Сохранность стада', en: 'Flock Survival'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4B6354), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$_currentCount / $_initialCount',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF14532D), fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Pill 3: Daily Care & Feed Phase
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF2563EB)),
                    Text(
                      AppStrings.tr(lang: _lang, uz: '$_batchDay-kun', ru: 'День $_batchDay', en: 'Day $_batchDay'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Kunlik parvarish', ru: 'Суточный уход', en: 'Daily Care'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4B6354), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  stageName,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF14532D), fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Ross-308 Poultry Management Horizontal Photographic Cards
  Widget _buildChooseYourFarmSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: 'Parrandachilik Boshqaruvi',
                  ru: 'Управление Птичником',
                  en: 'Flock Management',
                ),
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.tr(
                lang: _lang,
                uz: 'Barchasi (3)',
                ru: 'Все (3)',
                en: 'See All (3)',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreenDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 154,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildFarmCarouselCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: 'Kunlik Parvarish (1–42)',
                  ru: 'Суточный План (1–42)',
                  en: 'Daily Care Plan (1–42)',
                ),
                sub: AppStrings.tr(
                  lang: _lang,
                  uz: 'Harorat va vazifalar',
                  ru: 'Температура и задачи',
                  en: 'Temp & daily tasks',
                ),
                points: AppStrings.tr(
                  lang: _lang,
                  uz: '1–42 kun',
                  ru: '1–42 дн.',
                  en: 'Days 1–42',
                ),
                imagePath: 'assets/images/broiler_flock.jpg',
                onTap: () => context.push('/daily-plan'),
              ),
              const SizedBox(width: 12),
              _buildFarmCarouselCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: 'Vazn & Yem Nazorati',
                  ru: 'Контроль Веса и Корма',
                  en: 'Weight & Feed Control',
                ),
                sub: AppStrings.tr(
                  lang: _lang,
                  uz: 'Ross-308 kundaligi',
                  ru: 'Дневник Ross-308',
                  en: 'Ross-308 flock diary',
                ),
                points: 'Ross-308',
                imagePath: 'assets/images/feed_grain.jpg',
                onTap: () => _navigateToPage(1),
              ),
              const SizedBox(width: 12),
              _buildFarmCarouselCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: 'Kredit Kursi & Sertifikat',
                  ru: 'Курс и Сертификат',
                  en: 'Course & Certificate',
                ),
                sub: AppStrings.tr(
                  lang: _lang,
                  uz: '5 modul • Imtiyozli kredit',
                  ru: '5 модулей • Льготный кредит',
                  en: '5 modules • Loan readiness',
                ),
                points: AppStrings.tr(
                  lang: _lang,
                  uz: '5 modul',
                  ru: '5 мод.',
                  en: '5 mods',
                ),
                imagePath: 'assets/images/chick_starter.jpg',
                onTap: () => _navigateToPage(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmCarouselCard({
    required String title,
    required String sub,
    required String points,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return TactileCard(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset(
                    imagePath,
                    width: 180,
                    height: 94,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 180,
                      height: 94,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(235),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      points,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D2616),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hero Panoramic Flock Sanctuary Card
  Widget _buildHeroFlockSanctuaryCard(BuildContext context, int targetTemp) {
    final progressPercent = (_batchDay / 42.0).clamp(0.0, 1.0);
    final hasRedAlert = _alerts.any((a) => a.severity == AlertSeverity.critical);
    final hasYellowAlert = _alerts.any((a) => a.severity == AlertSeverity.warning);

    final String healthBadgeText;
    final Color healthIconColor;
    final IconData healthIcon;
    if (hasRedAlert) {
      healthBadgeText = AppStrings.tr(
        lang: _lang,
        uz: '⚠️ Xavf aniqlandi',
        ru: '⚠️ Опасность',
        en: '⚠️ Critical Alert',
      );
      healthIconColor = const Color(0xFFEF4444);
      healthIcon = Icons.warning_amber_rounded;
    } else if (hasYellowAlert) {
      healthBadgeText = AppStrings.tr(
        lang: _lang,
        uz: '⚡ E\'tibor bering',
        ru: '⚡ Внимание',
        en: '⚡ Needs Attention',
      );
      healthIconColor = const Color(0xFFF59E0B);
      healthIcon = Icons.info_outline_rounded;
    } else {
      healthBadgeText = AppStrings.tr(
        lang: _lang,
        uz: '★ 4.9 Salomatlik',
        ru: '★ 4.9 Здоровье',
        en: '★ 4.9 Health',
      );
      healthIconColor = const Color(0xFFFBBF24);
      healthIcon = Icons.star_rounded;
    }

    return TactileCard(
      onTap: () => context.push('/daily-plan'),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Stack(
            children: [
              // Photographic Backdrop
              Positioned.fill(
                child: Image.asset(
                  'assets/images/field_aerial.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/broiler_flock.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Vignette Scrim Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha(140),
                        Colors.black.withAlpha(50),
                        Colors.black.withAlpha(210),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top-Left Pill: Dynamic Rating & Health Status
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(130),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: Colors.white.withAlpha(55), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(healthIcon, color: healthIconColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        healthBadgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-Right Live Dot
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withAlpha(190),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: Colors.white.withAlpha(70), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseBeacon(size: 6, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: 'JONLI',
                          ru: 'ОНЛАЙН',
                          en: 'LIVE',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Details: Flock Title, Day, Animated Progress Bar
              Positioned(
                bottom: 16,
                left: 18,
                right: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: '📍 $_district • Ross-308 Partiya #1',
                        ru: '📍 $_district • Ross-308 Партия #1',
                        en: '📍 $_district • Ross-308 Batch #1',
                      ),
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'Ross-308 Asosiy Poda ($_currentCount bosh)',
                        ru: 'Основное стадо Ross-308 ($_currentCount гол.)',
                        en: 'Ross-308 Main Flock ($_currentCount birds)',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          AppStrings.tr(
                            lang: _lang,
                            uz: '$_batchDay-kun (42 kundan)',
                            ru: '$_batchDay-й день из 42',
                            en: 'Day $_batchDay of 42',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: '•  ${(progressPercent * 100).toInt()}% yakunlandi',
                              ru: '•  ${(progressPercent * 100).toInt()}% пройдено',
                              en: '•  ${(progressPercent * 100).toInt()}% completed',
                            ),
                            style: TextStyle(
                              color: Colors.white.withAlpha(210),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 5,
                        color: Colors.white.withAlpha(45),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressPercent,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFFF59E0B)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Right: Circular White Button with Diagonal Arrow
              Positioned(
                bottom: 16,
                right: 16,
                child: TactileCard(
                  onTap: () => _navigateToPage(1),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        color: AppTheme.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Glanceable Telemetry Stats (Me'yor Harorat & Parrandalar)
  Widget _buildTelemetryStatsRow(BuildContext context, int targetTemp) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.thermostat_outlined,
            title: AppStrings.tr(
              lang: _lang,
              uz: "Me'yor harorat",
              ru: 'Норма тепла',
              en: 'Target Temp',
            ),
            value: '$targetTemp°C',
            subtitle: AppStrings.tr(
              lang: _lang,
              uz: 'Xonada',
              ru: 'В птичнике',
              en: 'In house',
            ),
            iconColor: const Color(0xFFEA580C),
            onTap: () => context.push('/daily-plan'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.pets_outlined,
            title: AppStrings.tr(
              lang: _lang,
              uz: 'Parrandalar',
              ru: 'Поголовье',
              en: 'Flock Size',
            ),
            value: '$_currentCount',
            subtitle: AppStrings.tr(
              lang: _lang,
              uz: '$_initialCount tadan',
              ru: 'из $_initialCount',
              en: 'of $_initialCount',
            ),
            iconColor: const Color(0xFF2563EB),
            onTap: () => _navigateToPage(1),
          ),
        ),
      ],
    );
  }

  /// Photographic Farmer Action Hub (4 Direct Ergonomic Pathways)
  Widget _buildPhotographicActionHub(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tr(
                lang: _lang,
                uz: "Tezkor Amallar",
                ru: "Быстрые действия",
                en: "Quick Actions",
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              AppStrings.tr(
                lang: _lang,
                uz: "1-bosish bilan",
                ru: "В один клик",
                en: "1-Tap",
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Rich Photographic Action Cards
        Row(
          children: [
            // Action 1: Daily Plan
            Expanded(
              child: _buildPhotographicActionCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: "Kunlik Reja",
                  ru: "План Дня",
                  en: "Daily Plan",
                ),
                subtitle: AppStrings.tr(
                  lang: _lang,
                  uz: "$_batchDay-kun vazifalari",
                  ru: "Задачи $_batchDay дня",
                  en: "Day $_batchDay Tasks",
                ),
                imagePath: 'assets/images/chick_starter.jpg',
                icon: Icons.assignment_turned_in_rounded,
                accentColor: const Color(0xFFF59E0B),
                onTap: () => context.push('/daily-plan'),
              ),
            ),
            const SizedBox(width: 12),

            // Action 2: Field Voice & Vision Assistant
            Expanded(
              child: _buildPhotographicActionCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: "Ovozli AI & Ko'z",
                  ru: "Голос & Камера",
                  en: "Voice & Vision",
                ),
                subtitle: AppStrings.tr(
                  lang: _lang,
                  uz: "Dala yordamchisi",
                  ru: "Полевой помощник",
                  en: "Field Assistant",
                ),
                imagePath: 'assets/images/broiler_flock.jpg',
                icon: Icons.mic_rounded,
                accentColor: const Color(0xFF22C55E),
                onTap: () => _navigateToPage(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Action 3: Flock Diary Logging
            Expanded(
              child: _buildPhotographicActionCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: "Dala Kundaligi",
                  ru: "Дневник Птицы",
                  en: "Flock Diary",
                ),
                subtitle: AppStrings.tr(
                  lang: _lang,
                  uz: "Yem, o'lim, vazn",
                  ru: "Корм, падеж, вес",
                  en: "Feed, loss, weight",
                ),
                imagePath: 'assets/images/feed_grain.jpg',
                icon: Icons.menu_book_rounded,
                accentColor: const Color(0xFF3B82F6),
                onTap: () => _navigateToPage(1),
              ),
            ),
            const SizedBox(width: 12),

            // Action 4: Farmer Academy & Certificate
            Expanded(
              child: _buildPhotographicActionCard(
                title: AppStrings.tr(
                  lang: _lang,
                  uz: "Akademiya",
                  ru: "Академия",
                  en: "Academy",
                ),
                subtitle: AppStrings.tr(
                  lang: _lang,
                  uz: "5 dars & Sertifikat",
                  ru: "5 уроков & диплом",
                  en: "5 Lessons & Cert",
                ),
                imagePath: 'assets/images/tractor_hero.jpg',
                icon: Icons.school_rounded,
                accentColor: const Color(0xFFEC4899),
                onTap: () => _navigateToPage(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single Photographic Action Card with Dark Vignette Scrim
  Widget _buildPhotographicActionCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return TactileCard(
      onTap: onTap,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            children: [
              // Photo Asset
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryGreenDark),
                ),
              ),

              // Gradient Scrim
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha(90),
                        Colors.black.withAlpha(190),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(220),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withAlpha(70), width: 1),
                          ),
                          child: Icon(icon, color: Colors.white, size: 17),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  /// Gentle Swipe Guidance Pill
  Widget _buildSwipeHintPill() {
    return TactileCard(
      onTap: () => _navigateToPage(1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swipe_left_rounded, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: "Kundalik va qaydlarga o'tish uchun suring →",
                  ru: "Смахните влево для перехода в дневник →",
                  en: "Swipe left to open flock diary →",
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreenDark,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Island Capsule Bottom Navigation Bar
  Widget _buildFloatingIslandNavBar(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 28, right: 28, bottom: 20),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xE6132417), // Deep translucent dark forest capsule
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: Colors.white.withAlpha(35), width: 1.2),
          boxShadow: AppTheme.floatingPillShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Home (Grid)
            _buildNavTabButton(
              index: 0,
              icon: Icons.grid_view_rounded,
              label: AppStrings.tr(lang: _lang, uz: 'Asosiy', ru: 'Главная', en: 'Home'),
            ),

            // Tab 1: Diary (Book)
            _buildNavTabButton(
              index: 1,
              icon: Icons.menu_book_rounded,
              label: AppStrings.tr(lang: _lang, uz: 'Kundalik', ru: 'Дневник', en: 'Diary'),
            ),

            // Tab 2: Mic (Voice AI)
            _buildNavTabButton(
              index: 2,
              icon: Icons.mic_rounded,
              label: AppStrings.tr(lang: _lang, uz: 'Ovozli AI', ru: 'Голос ИИ', en: 'Voice AI'),
            ),

            // Tab 3: Course (Graduation Cap)
            _buildNavTabButton(
              index: 3,
              icon: Icons.school_rounded,
              label: AppStrings.tr(lang: _lang, uz: 'Kurs', ru: 'Курс', en: 'Course'),
            ),

            // Tab 4: Settings (Person)
            _buildNavTabButton(
              index: 4,
              icon: Icons.person_rounded,
              label: AppStrings.tr(lang: _lang, uz: 'Profil', ru: 'Профиль', en: 'Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: label,
        child: TactileCard(
          onTap: () => _navigateToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: isSelected ? 48 : 38,
            height: isSelected ? 44 : 38,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withAlpha(140),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: isSelected ? 22 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
