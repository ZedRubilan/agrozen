import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../services/external_actions.dart';
import '../../widgets/tactile_button.dart';
import '../../widgets/animated_entry.dart';
import 'course_guide_data.dart';

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
  Locale? _observedLocale;

  /// The single lesson step currently in focus (1..5).
  int _activeStep = 1;

  /// Whether the single-focus card is currently showing the 1-question inline check.
  bool _isQuickQuizMode = false;
  int _selectedQuizOption = -1;
  bool _quizSubmitted = false;
  bool _quizCorrect = false;

  /// Optional collapsible overview of all 5 lessons (collapsed by default to keep focus on 1 thing).
  bool _showAllStepsOverview = false;

  final CourseRepository _courseRepo = CourseRepository();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.maybeLocaleOf(context);
    if (_observedLocale != null &&
        currentLocale != null &&
        currentLocale != _observedLocale) {
      _observedLocale = currentLocale;
      _loadState(localeOverride: currentLocale.languageCode);
    } else {
      _observedLocale = currentLocale;
    }
  }

  Future<void> _loadState({String? localeOverride, int? preserveStep}) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final lang = CourseGuideData.normalizeLang(
      prefs.getString('app_language') ?? localeOverride ?? 'uz',
    );
    final completedRaw = prefs.getStringList('completed_lessons') ?? [];
    final completed = completedRaw
        .map((e) => int.tryParse(e) ?? 0)
        .where((id) => id >= 1 && id <= 5)
        .toSet()
        .toList()
      ..sort();

    int nextFocusStep = preserveStep ?? 1;
    if (preserveStep == null) {
      for (int i = 1; i <= 5; i++) {
        if (!completed.contains(i)) {
          nextFocusStep = i;
          break;
        }
      }
      if (completed.length >= 5) {
        nextFocusStep = 5;
      }
    }

    if (!mounted) return;
    setState(() {
      _lang = lang;
      _completedLessons = completed;
      _activeStep = nextFocusStep.clamp(1, 5);
      _isQuickQuizMode = false;
      _selectedQuizOption = -1;
      _quizSubmitted = false;
      _quizCorrect = false;
      _isLoading = false;
    });
  }

  void _selectStep(int stepId) {
    setState(() {
      _activeStep = stepId.clamp(1, 5);
      _isQuickQuizMode = false;
      _selectedQuizOption = -1;
      _quizSubmitted = false;
      _quizCorrect = false;
    });
  }

  Future<void> _submitInlineQuiz(CourseModuleGuide module) async {
    if (_selectedQuizOption < 0) return;
    final isCorrect = _selectedQuizOption == module.correctOptionIndex;

    setState(() {
      _quizSubmitted = true;
      _quizCorrect = isCorrect;
    });

    if (isCorrect) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('completed_lessons') ?? [];
      final idStr = module.id.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList('completed_lessons', list);
      }
      final farmerId = prefs.getString('farmer_id') ?? 'local_farmer';
      await _courseRepo.saveProgress(
        farmerId: farmerId,
        lessonNumber: module.id,
        quizPassed: true,
      );
      if (!mounted) return;
      setState(() {
        if (!_completedLessons.contains(module.id)) {
          _completedLessons = [..._completedLessons, module.id]..sort();
        }
      });
    }
  }

  void _advanceToNextStep() {
    // Find the next incomplete step after _activeStep, or the first incomplete step.
    int? nextStep;
    for (int i = _activeStep + 1; i <= 5; i++) {
      if (!_completedLessons.contains(i)) {
        nextStep = i;
        break;
      }
    }
    if (nextStep == null) {
      for (int i = 1; i <= 5; i++) {
        if (!_completedLessons.contains(i)) {
          nextStep = i;
          break;
        }
      }
    }
    if (nextStep != null) {
      _selectStep(nextStep);
    } else if (_activeStep < 5) {
      _selectStep(_activeStep + 1);
    } else {
      setState(() {
        _isQuickQuizMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = CourseGuideData.getModules(_lang);
    final currentModule = CourseGuideData.getModule(_activeStep, _lang);
    final completedCount = _completedLessons.length.clamp(0, modules.length);
    final allCompleted = completedCount >= modules.length;
    final isCurrentPassed = _completedLessons.contains(currentModule.id);

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
              top: widget.isEmbeddedInPageView ? 8.0 : 14.0,
              bottom: widget.isEmbeddedInPageView ? 110.0 : 28.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isEmbeddedInPageView) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.tr(
                                lang: _lang,
                                uz: 'Bir vaqtda bitta qadam — oson va tushunarli',
                                ru: 'Один шаг за раз — просто и понятно',
                                en: 'One step at a time — simple & practical',
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$completedCount/${modules.length}',
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
                  const SizedBox(height: 12),
                ],

                // 1. Compact Progress & 5-Step Guided Pathway Card
                StaggeredSlideFade(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2214),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withAlpha(35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Color(0xFF4ADE80),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.tr(
                                        lang: _lang,
                                        uz: 'Tugallandi: $completedCount / ${modules.length}',
                                        ru: 'Пройдено: $completedCount из ${modules.length}',
                                        en: 'Completed: $completedCount of ${modules.length}',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    Text(
                                      AppStrings.tr(
                                        lang: _lang,
                                        uz: "Ross-308 standarti bo'yicha 5 qadam",
                                        ru: '5 шагов по стандарту Ross-308',
                                        en: '5 steps by Ross-308 standard',
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF86EFAC),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Text(
                                '${((completedCount / modules.length) * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                          child: LinearProgressIndicator(
                            value: completedCount / modules.length,
                            minHeight: 6,
                            backgroundColor: Colors.white.withAlpha(35),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF22C55E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Interactive 5-Step Selector Pills
                        Row(
                          children: List.generate(modules.length, (index) {
                            final stepNum = index + 1;
                            final isStepDone =
                                _completedLessons.contains(stepNum);
                            final isStepActive = _activeStep == stepNum;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index < modules.length - 1 ? 6.0 : 0.0,
                                ),
                                child: InkWell(
                                  key: ValueKey('course_step_pill_$stepNum'),
                                  onTap: () => _selectStep(stepNum),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isStepActive
                                          ? const Color(0xFF15803D)
                                          : (isStepDone
                                              ? const Color(0xFF22C55E)
                                                  .withAlpha(40)
                                              : Colors.white.withAlpha(18)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isStepActive
                                            ? const Color(0xFF4ADE80)
                                            : (isStepDone
                                                ? const Color(0xFF22C55E)
                                                    .withAlpha(110)
                                                : Colors.white24),
                                        width: isStepActive ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isStepDone)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Color(0xFF4ADE80),
                                          )
                                        else
                                          Text(
                                            '$stepNum',
                                            style: TextStyle(
                                              color: isStepActive
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        if (isStepDone) ...[
                                          const SizedBox(width: 3),
                                          Text(
                                            '$stepNum',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Certificate Unlocked Banner (when all 5 steps are completed)
                if (allCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.white,
                                  size: 24,
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
                                        uz: 'Tabriklaymiz! Kurs 100% yakunlandi',
                                        ru: 'Поздравляем! Курс пройден на 100%',
                                        en: 'Congratulations! Course 100% Completed',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: Color(0xFF78350F),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppStrings.tr(
                                        lang: _lang,
                                        uz: "Bank krediti uchun tayyorgarlik sertifikatingiz tayyor.",
                                        ru: 'Ваш сертификат готовности для банка открыт.',
                                        en: 'Your pre-credit readiness certificate is unlocked.',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TactileButton(
                            height: 52,
                            depth: 4,
                            borderRadius: 16,
                            backgroundColor: const Color(0xFFD97706),
                            shadowColor: const Color(0xFF92400E),
                            onPressed: () => context.push('/certificate'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.tr(
                                    lang: _lang,
                                    uz: "Sertifikatimni ko'rish",
                                    ru: 'Посмотреть мой сертификат',
                                    en: 'View My Certificate',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. SINGLE-FOCUS ACTIVE LESSON CARD (The Farmer Focuses on Only ONE Thing Here)
                StaggeredSlideFade(
                  index: 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: _isQuickQuizMode
                        ? _buildInlineQuizCard(
                            context,
                            currentModule,
                            allCompleted,
                          )
                        : _buildFocusedLessonCard(
                            context,
                            currentModule,
                            isCurrentPassed,
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Optional Compact Toggle for All 5 Steps (keeps visual clutter zero by default)
                InkWell(
                  key: const ValueKey('toggle_all_course_steps'),
                  onTap: () => setState(
                    () => _showAllStepsOverview = !_showAllStepsOverview,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2EBE4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.format_list_numbered_rounded,
                              size: 18,
                              color: Color(0xFF52665A),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.tr(
                                lang: _lang,
                                uz: "Barcha 5 dars ro'yxati",
                                ru: 'Список всех 5 уроков',
                                en: 'All 5 Course Lessons',
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _showAllStepsOverview
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF52665A),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAllStepsOverview) ...[
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final mod = modules[index];
                      final isPassed = _completedLessons.contains(mod.id);
                      final isCurrent = _activeStep == mod.id;

                      return TactileCard(
                        onTap: () => _selectStep(mod.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFFEAF5ED)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF15803D)
                                  : (isPassed
                                      ? const Color(0xFF2D7A4C).withAlpha(90)
                                      : const Color(0xFFE2E8F0)),
                              width: isCurrent ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isPassed
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: isPassed
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : Text(
                                          '${mod.id}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mod.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      mod.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF52665A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: AppStrings.tr(
                                  lang: _lang,
                                  uz: "Darsni ochish",
                                  ru: 'Открыть урок',
                                  en: 'Open lesson',
                                ),
                                onPressed: () async {
                                  await context.push('/course/${mod.id}');
                                  _loadState(preserveStep: mod.id);
                                },
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

  Widget _buildFocusedLessonCard(
    BuildContext context,
    CourseModuleGuide module,
    bool isPassed,
  ) {
    return Container(
      key: ValueKey('focused_lesson_card_${module.id}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPassed
              ? const Color(0xFF15803D).withAlpha(110)
              : const Color(0xFFE2EBE4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Step Badge + Video Guide Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isPassed
                      ? const Color(0xFFEAF5ED)
                      : const Color(0xFF15803D).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPassed
                          ? Icons.check_circle_rounded
                          : Icons.flag_circle_rounded,
                      size: 15,
                      color: const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPassed
                          ? AppStrings.tr(
                              lang: _lang,
                              uz: '${module.id}-QADAM • TOPSHIRILGAN',
                              ru: 'ШАГ ${module.id} • ПРОЙДЕНО',
                              en: 'STEP ${module.id} • COMPLETED',
                            )
                          : AppStrings.tr(
                              lang: _lang,
                              uz: '${module.id}-QADAM (5 tadan) • HOZIRGI VAZIFA',
                              ru: 'ШАГ ${module.id} ИЗ 5 • ТЕКУЩИЙ ФОКУС',
                              en: 'STEP ${module.id} OF 5 • CURRENT FOCUS',
                            ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => const ExternalActions().openVideo(
                  context,
                  module.videoUrl,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: 'Video',
                          ru: 'Видео',
                          en: 'Video',
                        ),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Module Title & Subtitle
          Text(
            module.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            module.subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52665A),
            ),
          ),

          const SizedBox(height: 16),

          // 3 Simple Scannable Rule Cards
          ...module.keyPoints.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2EBE4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EBE4)),
                      ),
                      child: Icon(
                        point.icon,
                        size: 20,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  point.badge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            point.description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 4),

          // Practical Farmer & Credit Benefit Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    module.farmerTakeaway,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Single Primary Action Button to Answer 1 Question & Progress
          TactileButton(
            key: ValueKey('start_inline_quiz_btn_${module.id}'),
            height: 54,
            depth: 4,
            borderRadius: 16,
            backgroundColor: const Color(0xFF15803D),
            shadowColor: const Color(0xFF0B2214),
            onPressed: () {
              setState(() {
                _isQuickQuizMode = true;
                _selectedQuizOption = -1;
                _quizSubmitted = false;
                _quizCorrect = false;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPassed
                      ? Icons.replay_circle_filled_rounded
                      : Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isPassed
                        ? AppStrings.tr(
                            lang: _lang,
                            uz: 'Savolni qayta tekshirish (1 savol)',
                            ru: 'Повторить вопрос шага (1 вопрос)',
                            en: 'Practice Step Question Again (1 Q)',
                          )
                        : AppStrings.tr(
                            lang: _lang,
                            uz: '1 ta savolga javob berish va davom etish',
                            ru: 'Ответить на 1 вопрос и продолжить',
                            en: 'Answer 1 Question to Continue',
                          ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Secondary Row: Full Lesson Reader or Next Step
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await context.push('/course/${module.id}');
                  _loadState(preserveStep: module.id);
                },
                icon: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: Color(0xFF52665A),
                ),
                label: Text(
                  AppStrings.tr(
                    lang: _lang,
                    uz: "Batafsil o'qish",
                    ru: 'Читать подробно',
                    en: 'Read Full Lesson',
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF52665A),
                  ),
                ),
              ),
              if (module.id < 5)
                TextButton.icon(
                  onPressed: () => _selectStep(module.id + 1),
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  label: Text(
                    AppStrings.tr(
                      lang: _lang,
                      uz: '${module.id + 1}-qadamga o\'tish',
                      ru: 'К шагу ${module.id + 1}',
                      en: 'Go to Step ${module.id + 1}',
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineQuizCard(
    BuildContext context,
    CourseModuleGuide module,
    bool allCompleted,
  ) {
    final options = module.quizOptions;
    final correctIndex = module.correctOptionIndex;

    return Container(
      key: ValueKey('inline_quiz_card_${module.id}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF15803D), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _isQuickQuizMode = false),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: Color(0xFF52665A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: 'Qoidalarga qaytish',
                          ru: 'Назад к правилам',
                          en: 'Back to rules',
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF52665A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.tr(
                    lang: _lang,
                    uz: '${module.id}-QADAM SAVOLI',
                    ru: 'ВОПРОС ШАГА ${module.id}',
                    en: 'STEP ${module.id} CHECK',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            module.quizQuestion,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(options.length, (index) {
            final isSelected = _selectedQuizOption == index;
            Color tileBg = const Color(0xFFF4F7F4);
            Color borderColor = const Color(0xFFE2EBE4);
            IconData iconData = isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_off_rounded;
            Color iconColor =
                isSelected ? const Color(0xFF15803D) : Colors.grey.shade500;

            if (_quizSubmitted) {
              if (index == correctIndex) {
                tileBg = const Color(0xFFEAF5ED);
                borderColor = const Color(0xFF15803D);
                iconData = Icons.check_circle_rounded;
                iconColor = const Color(0xFF15803D);
              } else if (isSelected && !_quizCorrect) {
                tileBg = const Color(0xFFFEF2F2);
                borderColor = const Color(0xFFDC2626);
                iconData = Icons.cancel_rounded;
                iconColor = const Color(0xFFDC2626);
              }
            } else if (isSelected) {
              tileBg = const Color(0xFFEAF5ED);
              borderColor = const Color(0xFF15803D);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                onTap: _quizSubmitted
                    ? null
                    : () => setState(() => _selectedQuizOption = index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ||
                              (_quizSubmitted && index == correctIndex)
                          ? 1.8
                          : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, color: iconColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ||
                                    (_quizSubmitted && index == correctIndex)
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          if (!_quizSubmitted)
            TactileButton(
              height: 52,
              depth: 4,
              borderRadius: 16,
              backgroundColor: const Color(0xFF15803D),
              shadowColor: const Color(0xFF0B2214),
              onPressed: _selectedQuizOption >= 0
                  ? () => _submitInlineQuiz(module)
                  : null,
              child: Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: 'Javobni tekshirish',
                  ru: 'Проверить ответ',
                  en: 'Check Answer',
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _quizCorrect
                        ? const Color(0xFFEAF5ED)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _quizCorrect
                          ? const Color(0xFF15803D)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _quizCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _quizCorrect
                                ? const Color(0xFF15803D)
                                : const Color(0xFFDC2626),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _quizCorrect
                                  ? AppStrings.tr(
                                      lang: _lang,
                                      uz: "To'g'ri! ${module.id}-qadam bajarildi.",
                                      ru: 'Правильно! Шаг ${module.id} пройден.',
                                      en: 'Correct! Step ${module.id} completed.',
                                    )
                                  : AppStrings.tr(
                                      lang: _lang,
                                      uz: "Noto'g'ri. Yana bir bor urinib ko'ring!",
                                      ru: 'Неверно. Попробуйте еще раз!',
                                      en: 'Incorrect. Please try again!',
                                    ),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                color: _quizCorrect
                                    ? const Color(0xFF1B5E20)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        module.quizExplanation,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TactileButton(
                  height: 52,
                  depth: 4,
                  borderRadius: 16,
                  backgroundColor: _quizCorrect
                      ? (allCompleted
                          ? const Color(0xFFD97706)
                          : const Color(0xFF15803D))
                      : const Color(0xFFD97706),
                  shadowColor: _quizCorrect
                      ? (allCompleted
                          ? const Color(0xFF92400E)
                          : const Color(0xFF0B2214))
                      : const Color(0xFF92400E),
                  onPressed: () {
                    if (_quizCorrect) {
                      if (allCompleted) {
                        context.push('/certificate');
                      } else {
                        _advanceToNextStep();
                      }
                    } else {
                      setState(() {
                        _quizSubmitted = false;
                        _selectedQuizOption = -1;
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _quizCorrect
                            ? (allCompleted
                                ? AppStrings.tr(
                                    lang: _lang,
                                    uz: "Sertifikatimni ko'rish",
                                    ru: 'Посмотреть сертификат',
                                    en: 'View My Certificate',
                                  )
                                : AppStrings.tr(
                                    lang: _lang,
                                    uz: 'Keyingi qadamga o\'tish',
                                    ru: 'Перейти к следующему шагу',
                                    en: 'Continue to Next Step',
                                  ))
                            : AppStrings.tr(
                                lang: _lang,
                                uz: 'Qayta urinish',
                                ru: 'Попробовать снова',
                                en: 'Try Again',
                              ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (_quizCorrect) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
