import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../domain/scheduler/day_calculator.dart';
import '../../domain/alerts/alert_models.dart';
import '../widgets/stat_card.dart';
import '../widgets/weather_climate_card.dart';
import '../widgets/flock_pathway_card.dart';
import '../widgets/loan_profit_tracker_card.dart';
import '../widgets/animated_entry.dart';
import 'diary/diary_screen.dart';
import 'ask/ask_screen.dart';
import 'course/course_list_screen.dart';
import 'settings_screen.dart';
import '../../services/daily_counters.dart';
import '../../core/localization/app_strings.dart';

/// Redesigned HomeScreen:
/// - Photographic-first, ultra-rounded organic layout built for farmers.
/// - Emil Kowalski animation principles: staggered cascades, tactile responses, zero lag.
/// - Swipeable PageView: seamless glide between Home, Diary, Voice AI, Courses, Settings.
/// - Floating translucent capsule bottom navigation bar.
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
  DateTime _arrivalDate = DateTime.now();
  int _batchDay = 1;
  NormsData? _norms;
  bool _isLoading = true;

  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await DailyCounters.rolled();

    _farmerName = prefs.getString('farmer_name') ?? 'Fermer';
    _district = prefs.getString('farmer_district') ?? 'Toshkent';
    _lang = prefs.getString('app_language') ?? 'uz';
    _initialCount = prefs.getInt('initial_count') ?? 500;
    _currentCount = prefs.getInt('current_count') ?? _initialCount;

    final arrivalStr = prefs.getString('arrival_date');
    if (arrivalStr != null) {
      _arrivalDate = DateTime.parse(arrivalStr);
    }
    _batchDay = DayCalculator.calculateBatchDay(_arrivalDate).clamp(1, 42);

    _norms = await _knowledgeRepo.getParsedNorms();

    if (!mounted) return;
    setState(() => _isLoading = false);
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
                },
                children: [
                  // PAGE 0: Asosiy (Clean, Photographic Overview)
                  _buildHomeOverview(context, targetTemp),

                  // PAGE 1: Kundalik (Diary)
                  const DiaryScreen(isEmbeddedInPageView: true),

                  // PAGE 2: Ovozli AI (Field Voice & Vision Assistant)
                  const AskScreen(startInFieldMode: true, isEmbeddedInPageView: true),

                  // PAGE 3: Kurs (Farmer Academy)
                  const CourseListScreen(isEmbeddedInPageView: true),

                  // PAGE 4: Profil (Settings & Language)
                  const SettingsScreen(isEmbeddedInPageView: true),
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

                    // 1b. 3 Quick Telemetry Status Pills (Soil, Weather, Air)
                    StaggeredSlideFade(
                      index: 1,
                      child: _buildTopTelemetryPills(context),
                    ),
                    const SizedBox(height: 14),

                    // 2. Hero Panoramic Flock Sanctuary Card
                    StaggeredSlideFade(
                      index: 2,
                      child: _buildHeroFlockSanctuaryCard(context, targetTemp),
                    ),
                    const SizedBox(height: 16),

                    // 2b. Choose Your Farm & Flock Cards
                    StaggeredSlideFade(
                      index: 3,
                      child: _buildChooseYourFarmSection(context),
                    ),
                    const SizedBox(height: 16),

                    // 3. Glanceable Telemetry Stats (Me'yor Harorat & Parrandalar)
                    StaggeredSlideFade(
                      index: 2,
                      child: _buildTelemetryStatsRow(context, targetTemp),
                    ),
                    const SizedBox(height: 18),

                    // 4. Photographic Farmer Action Hub (4 Direct Workflows)
                    StaggeredSlideFade(
                      index: 3,
                      child: _buildPhotographicActionHub(context),
                    ),
                    const SizedBox(height: 20),

                    // 5. Atmospheric Weather & Microclimate Advisory Card
                    StaggeredSlideFade(
                      index: 4,
                      child: WeatherClimateCard(
                        district: _district,
                        batchDay: _batchDay,
                        targetHouseTemp: targetTemp.toDouble(),
                        language: _lang,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 6. 42-Day Growth Pathway
                    StaggeredSlideFade(
                      index: 5,
                      child: FlockPathwayCard(
                        batchDay: _batchDay,
                        language: _lang,
                        onOpenPlan: () => context.push('/daily-plan'),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 7. Financial & Loan Profit Tracker
                    StaggeredSlideFade(
                      index: 6,
                      child: LoanProfitTrackerCard(
                        initialCount: _initialCount,
                        currentCount: _currentCount,
                        batchDay: _batchDay,
                        language: _lang,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 8. Gentle Swipe Guidance Pill
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

  // --- SUB-WIDGETS ---

  /// Top Greeting Bar with Live Status Beacon & Avatar
  Widget _buildTopHeaderBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
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
                ),
                const SizedBox(width: 6),
                const PulseBeacon(size: 7, color: Color(0xFF22C55E)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "$_district viloyati • Ross-308",
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

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

  /// 3 Quick Telemetry Status Pills (Soil Condition, Weather, Air Quality) matching reference comps
  Widget _buildTopTelemetryPills(BuildContext context) {
    return Row(
      children: [
        // Pill 1: Tuproq & Bino (Healthy)
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
                    const Icon(Icons.eco_rounded, size: 18, color: Color(0xFF16A34A)),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Bino & Tuproq', ru: 'Почва & Корпус', en: 'Soil & Barn'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4B6354), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.tr(lang: _lang, uz: "A'lo darajada", ru: 'Отлично', en: 'Healthy'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF14532D), fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Pill 2: Ob-havo 28°C (Sunny)
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.wb_sunny_rounded, size: 18, color: Color(0xFFD97706)),
                    Text(
                      '28°C',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF854D0E)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Ob-havo', ru: 'Погода', en: 'Weather'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF713F12), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Quyoshli', ru: 'Солнечно', en: 'Sunny'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF713F12), fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Pill 3: Havo Sifati (Clean - Safe)
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.air_rounded, size: 18, color: Color(0xFF2563EB)),
                    Text(
                      '8 ppm',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Havo Sifati', ru: 'Воздух', en: 'Air Quality'),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4B6354), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.tr(lang: _lang, uz: 'Toza • A\'lo', ru: 'Безопасно', en: 'Clean • Safe'),
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

  /// Choose Your Farm & Flock Horizontal Photographic Cards
  Widget _buildChooseYourFarmSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tr(
                lang: _lang,
                uz: 'Fermangiz & Ekinlar',
                ru: 'Хозяйство & Посевы',
                en: 'Choose Your Farm',
              ),
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
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
                title: 'Green Valley Farm',
                sub: 'Sabzavot • 12 Ha',
                points: '1300 pts',
                imagePath: 'assets/images/sunset_farm.jpg',
                tag: 'Ochiq Dala',
              ),
              const SizedBox(width: 12),
              _buildFarmCarouselCard(
                title: 'Sunrise Fields',
                sub: 'G\'alla & Bug\'doy',
                points: '1200 pts',
                imagePath: 'assets/images/field_aerial.jpg',
                tag: 'Katta Maydon',
              ),
              const SizedBox(width: 12),
              _buildFarmCarouselCard(
                title: 'Riverbend Broilers',
                sub: 'Ross-308 • Bino #1',
                points: '1400 pts',
                imagePath: 'assets/images/broiler_flock.jpg',
                tag: 'Aqlli Bino',
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
    required String tag,
  }) {
    return Container(
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
    );
  }

  /// Hero Panoramic Flock Sanctuary Card
  Widget _buildHeroFlockSanctuaryCard(BuildContext context, int targetTemp) {
    final progressPercent = (_batchDay / 42.0).clamp(0.0, 1.0);

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

              // Top-Left Pill: Rating & Health Status
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                      SizedBox(width: 4),
                      Text(
                        '★ 4.8 Salomatlik',
                        style: TextStyle(
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseBeacon(size: 6, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'JONLI',
                        style: TextStyle(
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
                      "📍 $_district • Ross-308 Partiya #1",
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Ross-308 Asosiy Poda ($_currentCount bosh)",
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
                        Text(
                          '•  ${(progressPercent * 100).toInt()}% yakunlandi',
                          style: TextStyle(
                            color: Colors.white.withAlpha(210),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
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
            Text(
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
              label: 'Asosiy',
            ),

            // Tab 1: Diary (Book)
            _buildNavTabButton(
              index: 1,
              icon: Icons.menu_book_rounded,
              label: 'Kundalik',
            ),

            // Tab 2: Mic (Voice AI)
            _buildNavTabButton(
              index: 2,
              icon: Icons.mic_rounded,
              label: 'Ovozli AI',
            ),

            // Tab 3: Course (Graduation Cap)
            _buildNavTabButton(
              index: 3,
              icon: Icons.school_rounded,
              label: 'Kurs',
            ),

            // Tab 4: Settings (Person)
            _buildNavTabButton(
              index: 4,
              icon: Icons.person_rounded,
              label: 'Profil',
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

    return TactileCard(
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
    );
  }
}
