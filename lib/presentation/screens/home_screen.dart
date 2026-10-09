import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/daily_plan.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../domain/scheduler/day_calculator.dart';
import '../../domain/alerts/alert_engine.dart';
import '../../domain/alerts/alert_models.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/weather_climate_card.dart';
import '../widgets/loan_profit_tracker_card.dart';
import '../widgets/flock_pathway_card.dart';
import '../widgets/tactile_button.dart';
import '../../services/daily_counters.dart';
import '../../core/localization/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _farmerName = 'Fermer';
  String _district = 'Toshkent';
  String _lang = 'uz';
  int _initialCount = 500;
  int _currentCount = 495;
  DateTime _arrivalDate = DateTime.now();
  int _batchDay = 1;
  DailyPlan? _todayPlan;
  Map<String, dynamic>? _todayVet;
  AlertResult? _activeAlert;
  NormsData? _norms;
  bool _isLoading = true;

  final KnowledgeRepository _knowledgeRepo = KnowledgeRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
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

    // Load today's plan
    _todayPlan = await _knowledgeRepo.getDailyPlan(_batchDay);

    // Load local vet
    final vets = await _knowledgeRepo.getVetByDistrict(_district);
    if (vets.isNotEmpty) {
      _todayVet = vets.first;
    }

    // Check the deterministic alert rule against the vet-verified norms.
    final recordedMortality = DailyCounters.getMortality(prefs);
    if (recordedMortality > 0) {
      final norms = await _knowledgeRepo.getParsedNorms();
      _norms = norms;
      final alertEngine = AlertEngine(norms);
      _activeAlert = alertEngine.checkMortality(
        deaths: recordedMortality,
        currentCount: _currentCount,
      );
    } else {
      _norms = await _knowledgeRepo.getParsedNorms();
      _activeAlert = null;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// Target temperature for a batch day, taken from the vet-verified
  /// `knowledge/norms.json` rather than a hardcoded table.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final targetTemp = _getTemperatureForDay(_batchDay);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.egg_alt_rounded, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AgroZen', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: AppStrings.tr(lang: _lang, uz: 'Asosiy', ru: 'Главная', en: 'Home'),
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.menu_book_rounded,
                label: AppStrings.tr(lang: _lang, uz: 'Kundalik', ru: 'Дневник', en: 'Diary'),
                isSelected: false,
                onTap: () => context.push('/diary'),
              ),

              // Big Appealing Center Floating Ovoz Button
              GestureDetector(
                onTap: () => context.push('/ask?mode=field'),
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2D7A4C), Color(0xFF1B5E20)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withAlpha(150),
                              offset: const Offset(0, 6),
                              blurRadius: 12,
                            ),
                            BoxShadow(
                              color: const Color(0xFF2D7A4C).withAlpha(60),
                              offset: const Offset(0, -1),
                              blurRadius: 4,
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFF8F9F5), width: 3.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.mic_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.tr(lang: _lang, uz: 'OVOZ', ru: 'ГОЛОС', en: 'VOICE'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildNavItem(
                icon: Icons.school_rounded,
                label: AppStrings.tr(lang: _lang, uz: 'Kurs', ru: 'Курс', en: 'Course'),
                isSelected: false,
                onTap: () => context.push('/course'),
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: AppStrings.tr(lang: _lang, uz: 'Profil', ru: 'Профиль', en: 'Profile'),
                isSelected: false,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Greeting Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withAlpha(200),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'Assalomu alaykum, $_farmerName!',
                              ru: 'Здравствуйте, $_farmerName!',
                              en: 'Welcome, $_farmerName!',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'Hudud: $_district | Partiya: $_currentCount bosh',
                              ru: 'Регион: $_district | Партия: $_currentCount голов',
                              en: 'Region: $_district | Flock: $_currentCount birds',
                            ),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          // Day Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.tr(
                                  lang: _lang,
                                  uz: '$_batchDay-kun (42 kundan)',
                                  ru: '$_batchDay-й день из 42',
                                  en: 'Day $_batchDay of 42',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${((_batchDay / 42) * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (_batchDay / 42).clamp(0.0, 1.0),
                              backgroundColor: Colors.white.withAlpha(60),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 42-Day Milestone Pathway Roadmap (Duolingo-style)
                    FlockPathwayCard(
                      batchDay: _batchDay,
                      language: _lang,
                      onOpenPlan: () => context.push('/daily-plan'),
                    ),
                    const SizedBox(height: 14),

                    // Real-time Regional Weather & Microclimate Guidance
                    WeatherClimateCard(
                      district: _district,
                      batchDay: _batchDay,
                      targetHouseTemp: targetTemp.toDouble(),
                      language: _lang,
                    ),
                    const SizedBox(height: 14),

                    // Active Alert Card if any
                    if (_activeAlert != null)
                      AlertCard.fromAlertResult(
                        alert: _activeAlert!,
                        locale: _lang,
                        vetName: _todayVet?['name'] as String?,
                        vetPhone: _todayVet?['phone'] as String?,
                      ),
                    const SizedBox(height: 10),

                    // Bank Loan Payoff & Profit Tracker
                    LoanProfitTrackerCard(
                      currentCount: _currentCount,
                      initialCount: _initialCount,
                      batchDay: _batchDay,
                      language: _lang,
                    ),
                    const SizedBox(height: 14),

                    // Hands-Free Field Mode Hero Button (Designed for dirty hands)
                    TactileButton(
                      height: 72,
                      backgroundColor: theme.colorScheme.primary,
                      shadowColor: const Color(0xFF1B5E20),
                      borderRadius: 22,
                      depth: 4.5,
                      onPressed: () => context.push('/ask?mode=field'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(120), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.tr(
                                      lang: _lang,
                                      uz: "DALA REJIMI: OVOZLI YORDAMCHI",
                                      ru: "РЕЖИМ ПОЛЯ: СПРОСИТЬ ГОЛОСОМ",
                                      en: "FIELD MODE: VOICE AI ASSISTANT",
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppStrings.tr(
                                      lang: _lang,
                                      uz: "Qo'llar kirlanganda: 1-bosish va gapiring",
                                      ru: "Грязные руки: 1 нажатие и говорите",
                                      en: "Dirty hands: 1 tap & speak",
                                    ),
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Stats Row
                    Row(
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
                            iconColor: Colors.deepOrange,
                            onTap: () => context.push('/daily-plan'),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            iconColor: Colors.blue.shade700,
                            onTap: () => context.push('/diary'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Today's Plan Card
                    if (_todayPlan != null)
                      DailyTaskCard(
                        plan: _todayPlan!,
                        language: _lang,
                        targetTemperature: targetTemp,
                        onWatchVideo: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.tr(
                                  lang: _lang,
                                  uz: "Videogid ochilmoqda: ${_todayPlan!.videoUrl ?? "https://youtube.com"}",
                                  ru: 'Открываем видеогид: ${_todayPlan!.videoUrl ?? "https://youtube.com"}',
                                  en: 'Opening video guide: ${_todayPlan!.videoUrl ?? "https://youtube.com"}',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    // Quick Action Buttons Grid
                    Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'Tezkor amallar',
                        ru: 'Быстрые действия',
                        en: 'Quick Actions',
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _buildActionTile(
                          icon: Icons.edit_calendar_rounded,
                          label: AppStrings.tr(
                            lang: _lang,
                            uz: 'Nobodlik yozish',
                            ru: 'Записать падёж',
                            en: 'Log Mortality',
                          ),
                          color: Colors.red.shade700,
                          onTap: () => context.push('/diary/mortality'),
                        ),
                        _buildActionTile(
                          icon: Icons.grain_rounded,
                          label: AppStrings.tr(
                            lang: _lang,
                            uz: 'Yem yozish',
                            ru: 'Записать корм',
                            en: 'Log Feed',
                          ),
                          color: Colors.amber.shade900,
                          onTap: () => context.push('/diary/feed'),
                        ),
                        _buildActionTile(
                          icon: Icons.scale_rounded,
                          label: AppStrings.tr(
                            lang: _lang,
                            uz: "Og'irlik yozish",
                            ru: 'Записать вес',
                            en: 'Log Weight',
                          ),
                          color: Colors.teal.shade700,
                          onTap: () => context.push('/diary/weight'),
                        ),
                        _buildActionTile(
                          icon: Icons.smart_toy_rounded,
                          label: AppStrings.tr(
                            lang: _lang,
                            uz: 'Savol berish',
                            ru: 'Спросить ИИ',
                            en: 'Ask AI',
                          ),
                          color: theme.colorScheme.primary,
                          onTap: () => context.push('/ask'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Local Vet Banner
                    if (_todayVet != null)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: const Icon(Icons.local_hospital, color: Colors.green),
                          ),
                          title: Text(
                            _todayVet!['name'] as String? ?? 'Hududiy veterinar',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${_todayVet!['phone'] ?? ''}\n${_todayVet!['organization'] ?? ''}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isRu
                                        ? 'Вызов ветеринара: ${_todayVet!['phone']}'
                                        : "Veterinarga qo'ng'iroq: ${_todayVet!['phone']}",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xFF1B5E20) : const Color(0xFF6B7280);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
