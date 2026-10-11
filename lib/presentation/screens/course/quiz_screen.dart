import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/repositories/course_repository.dart';
import '../../widgets/tactile_button.dart';
import 'course_guide_data.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _lang = 'uz';
  int _selectedOption = -1;
  bool _submitted = false;
  bool _isCorrect = false;
  final CourseRepository _courseRepo = CourseRepository();

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lang = CourseGuideData.normalizeLang(
        prefs.getString('app_language') ?? 'uz',
      );
    });
  }

  Future<void> _submitAnswer(int correct) async {
    setState(() {
      _submitted = true;
      _isCorrect = _selectedOption == correct;
    });

    if (_isCorrect) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('completed_lessons') ?? [];
      final idStr = widget.lessonId.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList('completed_lessons', list);
      }
      final farmerId = prefs.getString('farmer_id') ?? 'local_farmer';
      await _courseRepo.saveProgress(
        farmerId: farmerId,
        lessonNumber: widget.lessonId,
        quizPassed: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final module = CourseGuideData.getModule(widget.lessonId, _lang);
    final options = module.quizOptions;
    final correctIndex = module.correctOptionIndex;
    final explanation = module.quizExplanation;

    final titleText = AppStrings.tr(
      lang: _lang,
      uz: 'Test: Dars ${widget.lessonId}',
      ru: 'Тест: Урок ${widget.lessonId}',
      en: 'Quiz: Lesson ${widget.lessonId}',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: 'SAVOL',
                          ru: 'ВОПРОС',
                          en: 'QUESTION',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      module.quizQuestion,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(options.length, (index) {
                final isSelected = _selectedOption == index;
                Color tileBg = Colors.white;
                Color borderColor = const Color(0xFFE2E8F0);
                IconData iconData = isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded;
                Color iconColor = isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400;

                if (_submitted) {
                  if (index == correctIndex) {
                    tileBg = const Color(0xFFEAF5ED);
                    borderColor = const Color(0xFF2D7A4C);
                    iconData = Icons.check_circle_rounded;
                    iconColor = const Color(0xFF2D7A4C);
                  } else if (isSelected && !_isCorrect) {
                    tileBg = const Color(0xFFFEF2F2);
                    borderColor = const Color(0xFFDC2626);
                    iconData = Icons.cancel_rounded;
                    iconColor = const Color(0xFFDC2626);
                  }
                } else if (isSelected) {
                  tileBg = theme.colorScheme.primary.withAlpha(18);
                  borderColor = theme.colorScheme.primary;
                  iconColor = theme.colorScheme.primary;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: _submitted
                        ? null
                        : () => setState(() => _selectedOption = index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ||
                                  (_submitted && index == correctIndex)
                              ? 2
                              : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(15)
                                : Colors.black.withAlpha(4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(iconData, color: iconColor, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              options[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ||
                                        (_submitted && index == correctIndex)
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              if (!_submitted)
                TactileButton(
                  height: 56,
                  depth: 4,
                  borderRadius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  shadowColor: const Color(0xFF1B4E31),
                  onPressed: _selectedOption >= 0
                      ? () => _submitAnswer(correctIndex)
                      : null,
                  child: Text(
                    AppStrings.tr(
                      lang: _lang,
                      uz: 'Javobni tekshirish',
                      ru: 'Проверить ответ',
                      en: 'Check Answer',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
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
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _isCorrect
                            ? const Color(0xFFEAF5ED)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isCorrect
                              ? const Color(0xFF2D7A4C)
                              : const Color(0xFFDC2626),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _isCorrect
                                    ? const Color(0xFF2D7A4C)
                                    : const Color(0xFFDC2626),
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isCorrect
                                      ? AppStrings.tr(
                                          lang: _lang,
                                          uz: "To'g'ri! Dars muvaffaqiyatli topshirildi.",
                                          ru: 'Правильно! Урок успешно сдан.',
                                          en: 'Correct! Lesson completed successfully.',
                                        )
                                      : AppStrings.tr(
                                          lang: _lang,
                                          uz: "Noto'g'ri. Yana bir bor urinib ko'ring!",
                                          ru: 'Неверно. Попробуйте еще раз!',
                                          en: 'Incorrect. Please try again!',
                                        ),
                                  style: TextStyle(
                                    color: _isCorrect
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFF991B1B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              explanation,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isCorrect && widget.lessonId < 5) ...[
                      TactileButton(
                        height: 54,
                        depth: 4,
                        borderRadius: 18,
                        backgroundColor: const Color(0xFF15803D),
                        shadowColor: const Color(0xFF0B2214),
                        onPressed: () {
                          context.pushReplacement(
                            '/course/${widget.lessonId + 1}',
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.tr(
                                lang: _lang,
                                uz: 'Keyingi darsga o\'tish (${widget.lessonId + 1}-dars)',
                                ru: 'К следующему уроку (Урок ${widget.lessonId + 1})',
                                en: 'Continue to Lesson ${widget.lessonId + 1}',
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TactileButton(
                      height: 56,
                      depth: 4,
                      borderRadius: 18,
                      backgroundColor: _isCorrect
                          ? const Color(0xFF2D7A4C)
                          : const Color(0xFFD97706),
                      shadowColor: _isCorrect
                          ? const Color(0xFF1B4E31)
                          : const Color(0xFF92400E),
                      onPressed: () {
                        if (_isCorrect) {
                          context.pop();
                        } else {
                          setState(() {
                            _submitted = false;
                            _selectedOption = -1;
                          });
                        }
                      },
                      child: Text(
                        _isCorrect
                            ? AppStrings.tr(
                                lang: _lang,
                                uz: 'Yakunlash',
                                ru: 'Готово',
                                en: 'Done',
                              )
                            : AppStrings.tr(
                                lang: _lang,
                                uz: 'Qayta urinish',
                                ru: 'Попробовать снова',
                                en: 'Try Again',
                              ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
