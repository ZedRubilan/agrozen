import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/lesson_progress.dart';
import '../../ui/components.dart';
import 'course_guide_data.dart';
import 'lesson_look.dart';

/// One-question check at the end of a lesson. Passing it marks the lesson done.
class QuizScreen extends StatefulWidget {
  final int lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _lang = 'uz';
  int _selected = -1;
  bool _submitted = false;
  bool _correct = false;
  Set<int> _done = {};

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  int get _id => widget.lessonId.clamp(1, LessonProgress.totalLessons);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lang = CourseGuideData.normalizeLang(
        prefs.getString('app_language') ?? 'uz',
      );
    });
  }

  Future<void> _submit(CourseModuleGuide module) async {
    final correct = _selected == module.correctOptionIndex;
    setState(() {
      _submitted = true;
      _correct = correct;
    });
    if (correct) await LessonProgress.markPassed(_id);
    final done = await LessonProgress.completed();
    if (!mounted) return;
    setState(() => _done = done);
  }

  void _retry() => setState(() {
    _selected = -1;
    _submitted = false;
    _correct = false;
  });

  @override
  Widget build(BuildContext context) {
    final module = CourseGuideData.getModule(_id, _lang);
    final next = LessonProgress.nextLesson(_done);
    final (icon, color) = lessonLook(_id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('Test: $_id-dars', 'Тест: урок $_id', 'Quiz: lesson $_id'),
        ),
      ),
      body: Stack(
        children: [
          PageBody(
            children: [
              Reveal(
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                    ),
                    boxShadow: AppShadow.glow(color),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(56),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          module.quizQuestion,
                          style: AppText.section.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpace.lg),
              for (var i = 0; i < module.quizOptions.length; i++) ...[
                Reveal(
                  index: i + 1,
                  child: _OptionTile(
                    letter: String.fromCharCode(65 + i),
                    text: module.quizOptions[i],
                    selected: _selected == i,
                    state: !_submitted
                        ? _OptionState.idle
                        : (i == module.correctOptionIndex
                              ? _OptionState.correct
                              : (i == _selected
                                    ? _OptionState.wrong
                                    : _OptionState.idle)),
                    onTap: _submitted
                        ? null
                        : () => setState(() => _selected = i),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
              const Gap(AppSpace.lg),
              if (!_submitted)
                PrimaryButton(
                  icon: Icons.check_rounded,
                  label: _t('Tekshirish', 'Проверить', 'Check answer'),
                  onPressed: _selected < 0 ? null : () => _submit(module),
                )
              else ...[
                _ResultCard(
                  correct: _correct,
                  title: _correct
                      ? _t(
                          "To'g'ri! Dars tugatildi.",
                          'Верно! Урок пройден.',
                          'Correct! Lesson complete.',
                        )
                      : _t(
                          "Noto'g'ri. Yana urinib ko'ring.",
                          'Неверно. Попробуйте ещё раз.',
                          'Not quite. Try again.',
                        ),
                  message: module.quizExplanation,
                ),
                const Gap(AppSpace.lg),
                if (!_correct)
                  PrimaryButton(
                    icon: Icons.refresh_rounded,
                    label: _t('Qayta urinish', 'Ещё раз', 'Try again'),
                    onPressed: _retry,
                  )
                else if (next == null)
                  PrimaryButton(
                    icon: Icons.workspace_premium_rounded,
                    label: _t(
                      'Sertifikatni olish',
                      'Получить сертификат',
                      'Get your certificate',
                    ),
                    onPressed: () => context.pushReplacement('/certificate'),
                  )
                else
                  PrimaryButton(
                    icon: Icons.arrow_forward_rounded,
                    iconAtEnd: true,
                    label: _t('Keyingi dars', 'Следующий урок', 'Next lesson'),
                    onPressed: () => context.pushReplacement('/course/$next'),
                  ),
              ],
            ],
          ),
          if (_submitted && _correct)
            const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color? fill;
    switch (state) {
      case _OptionState.correct:
        accent = AppColors.primary;
        fill = AppColors.primarySoft;
      case _OptionState.wrong:
        accent = AppColors.danger;
        fill = AppColors.dangerSoft;
      case _OptionState.idle:
        accent = selected ? AppColors.primary : AppColors.inkMuted;
        fill = selected ? AppColors.primarySoft : null;
    }
    final solid = state != _OptionState.idle || selected;

    final tile = Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        borderColor: solid ? accent : null,
        color: fill,
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.medium,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: solid ? accent : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: switch (state) {
                    _OptionState.correct => const Icon(
                      Icons.check_rounded,
                      key: ValueKey('ok'),
                      color: Colors.white,
                    ),
                    _OptionState.wrong => const Icon(
                      Icons.close_rounded,
                      key: ValueKey('no'),
                      color: Colors.white,
                    ),
                    _OptionState.idle => Text(
                      letter,
                      key: ValueKey(letter),
                      style: AppText.label.copyWith(
                        color: solid ? Colors.white : AppColors.inkSecondary,
                      ),
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(child: Text(text, style: AppText.body)),
          ],
        ),
      ),
    );

    if (state != _OptionState.wrong) return tile;
    // A short head-shake for the wrong answer.
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(8 * (1 - v) * math.sin(v * math.pi * 6), 0),
        child: child,
      ),
      child: tile,
    );
  }
}

/// Big result card: green with a check, or amber with a hint.
class _ResultCard extends StatelessWidget {
  final bool correct;
  final String title;
  final String message;

  const _ResultCard({
    required this.correct,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.primary : AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: Color.lerp(color, Colors.white, 0.88),
        border: Border.all(color: color.withAlpha(120), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: AppShadow.glow(color),
              ),
              child: Icon(
                correct ? Icons.emoji_events_rounded : Icons.lightbulb_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.section),
                const SizedBox(height: AppSpace.xs),
                Text(message, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
