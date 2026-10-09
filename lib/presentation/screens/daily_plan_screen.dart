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
    final theme = Theme.of(context);

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
                  height: 72,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          duration: const Duration(milliseconds: 180),
                          width: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isToday ? theme.colorScheme.primary.withAlpha(25) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : (isSelected ? theme.colorScheme.primary : Colors.transparent),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : theme.colorScheme.primary,
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
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.tr(
                                    lang: _lang,
                                    uz: 'Bu sizning bugungi partiya kuningiz!',
                                    ru: 'Это ваш текущий день партии!',
                                    en: 'This is your current batch day!',
                                  ),
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr(
                                    lang: _lang,
                                    uz: "Bosqich bo'yicha tavsiyalar",
                                    ru: 'Рекомендации по периоду',
                                    en: 'Growth Stage Recommendations',
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _getStageRecommendation(_selectedDay, _lang),
                                  style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade800),
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
