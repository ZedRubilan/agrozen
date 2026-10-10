import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/daily_plan.dart';
import '../../data/repositories/knowledge_repository.dart';
import '../../domain/alerts/alert_models.dart';
import '../../domain/scheduler/day_calculator.dart';
import '../../core/localization/app_strings.dart';
import '../widgets/daily_task_card.dart';

class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  final KnowledgeRepository _repo = KnowledgeRepository();
  List<DailyPlan> _allPlans = [];
  int _currentBatchDay = 1;
  int _selectedDay = 1;
  String _lang = 'uz';
  NormsData? _norms;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('app_language') ?? 'uz';

    final arrivalStr = prefs.getString('arrival_date');
    if (arrivalStr != null) {
      _currentBatchDay = DayCalculator.calculateBatchDay(DateTime.parse(arrivalStr)).clamp(1, 42);
    }
    _selectedDay = _currentBatchDay;

    try {
      _allPlans = await _repo.getAllDailyPlans();
    } catch (_) {
      _allPlans = [];
    }

    try {
      _norms = await _repo.getParsedNorms();
    } catch (_) {
      _norms = null;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// Target temperature from the vet-verified `knowledge/norms.json`.
  int _getTemperatureForDay(int day) {
    final target = _norms?.temperatureTargetForDay(day);
    if (target != null) return target.round();
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
    final selectedPlan = _allPlans.firstWhere(
      (p) => p.day == _selectedDay,
      orElse: () => DailyPlan(
        day: _selectedDay,
        tasksRu: 'Уход за бройлерами: поддержание чистоты, вентиляция, кормление.',
        tasksUz: "Broylerlarni parvarishlash: tozalikni saqlash, shamollatish, oziqlantirish.",
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr(
            lang: _lang,
            uz: 'Kunlik reja (1–42)',
            ru: 'План по дням (1–42)',
            en: 'Daily Plan (1–42)',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Horizontal Day Picker Carousel
                Container(
                  height: 78,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemBuilder: (context, index) {
                      final dayNum = index + 1;
                      final isSelected = dayNum == _selectedDay;
                      final isToday = dayNum == _currentBatchDay;

                      final dayLabel = _lang == 'en'
                          ? 'D.$dayNum'
                          : (_lang == 'ru' ? 'Д.$dayNum' : '$dayNum-k');

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = dayNum),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF2D7A4C), Color(0xFF1B5E20)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (isToday ? const Color(0xFFE8F5ED) : const Color(0xFFF3F6F4)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isToday
                                  ? const Color(0xFF2D7A4C)
                                  : (isSelected ? Colors.transparent : const Color(0xFFE0E8E2)),
                              width: isToday ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1B5E20).withAlpha(80),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday ? const Color(0xFF1B5E20) : const Color(0xFF2A3A2D)),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF1B5E20),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Selected Day Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedDay == _currentBatchDay)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8F5ED), Color(0xFFDCEDE1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF2D7A4C).withAlpha(50), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF1B5E20), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  AppStrings.tr(
                                    lang: _lang,
                                    uz: 'Bu sizning bugungi partiya kuningiz!',
                                    ru: 'Это ваш текущий день партии!',
                                    en: 'This is your current batch day!',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        DailyTaskCard(
                          plan: selectedPlan,
                          language: _lang,
                          targetTemperature: _getTemperatureForDay(_selectedDay),
                        ),
                        const SizedBox(height: 16),
                        // Growth Stage Tips
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE2EBE4), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(6),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2D7A4C).withAlpha(25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF1B5E20), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppStrings.tr(
                                        lang: _lang,
                                        uz: "Bosqich bo'yicha tavsiyalar",
                                        ru: 'Рекомендации по периоду',
                                        en: 'Growth Stage Recommendations',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: Color(0xFF1B2A1E),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAF7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE8EDE9), width: 1),
                                  ),
                                  child: Text(
                                    _getStageRecommendation(_selectedDay, _lang),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.55,
                                      color: Color(0xFF334436),
                                      fontWeight: FontWeight.w500,
                                    ),
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
              ],
            ),
    );
  }

  String _getStageRecommendation(int day, String lang) {
    if (day <= 7) {
      return AppStrings.tr(
        lang: lang,
        uz: "Boshlang'ich davr (1-7 kunlar): 32-34°C haroratni ushlab turish va barcha jo'jalar dastlabki 2 soatda suv ichganiga ishonch hosil qilish o'ta muhim.",
        ru: 'Стартовый период (1-7 дни): критически важно поддерживать температуру 32-34°C и следить, чтобы все цыплята пили воду в первые 2 часа.',
        en: 'Starter phase (Days 1-7): Maintaining brooding temperature at 32-34°C and ensuring 100% chick water intake within the first 2 hours is critical.',
      );
    } else if (day <= 21) {
      return AppStrings.tr(
        lang: lang,
        uz: "O'sish davri (8-21 kunlar): O'sish yemiga asta-sekin o'tish, haroratni bosqichma-bosqich 27°C ga tushirish va shamollatishni kuchaytirish.",
        ru: 'Период активного роста (8-21 дни): плавный переход на корм "Рост", постепенное снижение температуры до 27°C, усиление вентиляции.',
        en: 'Grower phase (Days 8-21): Transition gradually to Grower feed, gradually reduce target temp to 27°C, and ramp up ventilation capacity.',
      );
    } else {
      return AppStrings.tr(
        lang: lang,
        uz: "Finish davri (22-42 kunlar): Finish yemi, vazn o'sishini qattiq nazorat qilish, yozda qizib ketishdan asrash va so'yishga tayyorgarlik.",
        ru: 'Финишный период (22-42 дни): корм "Финиш", максимальный контроль привеса, защита от перегрева летом, подготовка к забою.',
        en: 'Finisher phase (Days 22-42): Finisher feed, strict monitoring of weight gain and FCR, heat stress mitigation, and harvest scheduling.',
      );
    }
  }
}
