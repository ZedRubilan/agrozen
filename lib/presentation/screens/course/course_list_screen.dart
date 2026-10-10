import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../widgets/tactile_button.dart';
import '../../widgets/animated_entry.dart';
import 'package:agrozen/config/theme.dart';

class CourseListScreen extends StatefulWidget {
  final bool isEmbeddedInPageView;

  const CourseListScreen({
    super.key,
    this.isEmbeddedInPageView = false,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _lang = 'uz';
  List<int> _completedLessons = [];
  bool _isLoading = true;

  final List<Map<String, String>> _lessons = [
    {
      'num': '1',
      'title_uz': "Jo'jalar kelishidan oldin xonani tayyorlash",
      'title_ru': 'Подготовка помещения до завоза цыплят',
      'title_en': 'Pre-Placement Barn Preparation',
      'desc_uz': 'Dezinfeksiya, to\'shama, isitish tizimini sozlash',
      'desc_ru': 'Дезинфекция, подстилка, настройка обогрева',
      'desc_en': 'Disinfection, bedding, and heating setup',
    },
    {
      'num': '2',
      'title_uz': 'Dastlabki 3 kun: hal qiluvchi davr',
      'title_ru': 'Первые 3 дня: решающий период',
      'title_en': 'First 3 Days: The Critical Phase',
      'desc_uz': 'Suv va yemga o\'rgatish, harorat monitoringi',
      'desc_ru': 'Приучение к воде и корму, контроль температуры',
      'desc_en': 'Water and feed training, thermal monitoring',
    },
    {
      'num': '3',
      'title_uz': 'Harorat va shamollatish boshqaruvi',
      'title_ru': 'Управление температурой и вентиляцией',
      'title_en': 'Temperature and Ventilation Control',
      'desc_uz': 'Ammiakni yo\'qotish va qizib ketishdan saqlash',
      'desc_ru': 'Удаление аммиака и защита от перегрева',
      'desc_en': 'Ammonia exhaust and heat stress prevention',
    },
    {
      'num': '4',
      'title_uz': "To'g'ri oziqlantirish fazalari",
      'title_ru': 'Фазы правильного кормления',
      'title_en': 'Proper Feeding Phases',
      'desc_uz': 'Start, O\'sish va Finish yemlari me\'yorlari',
      'desc_ru': 'Нормы кормов Старт, Рост и Финиш',
      'desc_en': 'Starter, Grower, and Finisher feed norms',
    },
    {
      'num': '5',
      'title_uz': 'Kasalliklar va veterinar bilan ishlash',
      'title_ru': 'Болезни и работа с ветеринаром',
      'title_en': 'Diseases and Working with Veterinarians',
      'desc_uz': 'Asosiy alomatlar va favqulodda harakatlar',
      'desc_ru': 'Главные симптомы и экстренные действия',
      'desc_en': 'Primary symptoms and emergency response',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('app_language') ?? 'uz';
    final completed = prefs.getStringList('completed_lessons') ?? [];
    _completedLessons = completed.map((e) => int.tryParse(e) ?? 0).toList();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final allCompleted = _completedLessons.length >= _lessons.length;

    final bodyContent = _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 18.0,
              right: 18.0,
              top: widget.isEmbeddedInPageView ? 8.0 : 16.0,
              bottom: widget.isEmbeddedInPageView ? 110.0 : 28.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isEmbeddedInPageView) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'Kreditdan oldingi kurs',
                              ru: 'Курс до кредита',
                              en: 'Pre-Credit Course',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'Ross-308 parrandachilik akademiyasi',
                              ru: 'Академия птицеводства Ross-308',
                              en: 'Ross-308 Poultry Academy',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              '${_completedLessons.length}/${_lessons.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Photographic Hero Banner
                StaggeredSlideFade(
                  index: 0,
                  child: Container(
                    height: 185,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/chick_starter.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withAlpha(205),
                                  Colors.black.withAlpha(140),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.65, 1.0],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(45),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.tr(
                                            lang: _lang,
                                            uz: 'Parrandachilik kursi',
                                            ru: 'Обучение птицевода',
                                            en: 'Poultry Farmer Training',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        Text(
                                          AppStrings.tr(
                                            lang: _lang,
                                            uz: "Ross-308 standarti bo'yicha",
                                            ru: 'По стандарту Ross-308',
                                            en: 'According to Ross-308 standard',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF86EFAC),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.tr(
                                      lang: _lang,
                                      uz: "Tugallandi: ${_completedLessons.length} / ${_lessons.length}",
                                      ru: 'Пройдено: ${_completedLessons.length} из ${_lessons.length}',
                                      en: 'Completed: ${_completedLessons.length} of ${_lessons.length}',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(50),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                    ),
                                    child: Text(
                                      '${((_completedLessons.length / _lessons.length) * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Color(0xFFFDE047),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                child: LinearProgressIndicator(
                                  value: _lessons.isEmpty ? 0 : (_completedLessons.length / _lessons.length),
                                  minHeight: 7,
                                  backgroundColor: Colors.white.withAlpha(45),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                const SizedBox(height: 20),


                  if (allCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: TactileButton(
                        height: 56,
                        depth: 4,
                        borderRadius: 18,
                        backgroundColor: const Color(0xFFD97706),
                        shadowColor: const Color(0xFF92400E),
                        onPressed: () => context.push('/certificate'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.tr(
                                lang: _lang,
                                uz: "Sertifikatimni ko'rish",
                                ru: 'Посмотреть мой сертификат',
                                en: 'View My Certificate',
                              ),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: 'Darslar ro\'yxati',
                          ru: 'Уроки курса',
                          en: 'Course Lessons',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '5 ta modul',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _lessons[index];
                      final num = int.parse(item['num']!);
                      final isPassed = _completedLessons.contains(num);

                      final lessonTitle = _lang == 'en'
                          ? (item['title_en'] ?? item['title_uz']!)
                          : (_lang == 'ru' ? item['title_ru']! : item['title_uz']!);

                      final lessonDesc = _lang == 'en'
                          ? (item['desc_en'] ?? item['desc_uz']!)
                          : (_lang == 'ru' ? item['desc_ru']! : item['desc_uz']!);

                      return StaggeredSlideFade(
                        index: index + 1,
                        child: TactileCard(
                          onTap: () async {
                            await context.push('/course/$num');
                            _loadState();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPassed ? const Color(0xFF2D7A4C).withAlpha(100) : const Color(0xFFE2E8F0),
                                width: isPassed ? 1.6 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isPassed
                                      ? const Color(0xFF2D7A4C).withAlpha(15)
                                      : Colors.black.withAlpha(6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isPassed
                                        ? const Color(0xFFEAF5ED)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isPassed
                                          ? const Color(0xFF2D7A4C).withAlpha(60)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Center(
                                    child: isPassed
                                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2D7A4C), size: 24)
                                        : Text(
                                            '$num',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: Color(0xFF0F766E),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lessonTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        lessonDesc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAF7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: isPassed ? const Color(0xFF2D7A4C) : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );

    if (widget.isEmbeddedInPageView) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          AppStrings.tr(
            lang: _lang,
            uz: 'Kreditdan oldingi kurs',
            ru: 'Курс до кредита',
            en: 'Pre-Credit Course',
          ),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: bodyContent,
    );
  }
}
