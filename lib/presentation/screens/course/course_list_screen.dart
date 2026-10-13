import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/farm_store.dart';
import '../../../services/lesson_progress.dart';
import '../../ui/broiler_photos.dart';
import '../../ui/components.dart';
import '../home_screen.dart';
import 'course_guide_data.dart';
import 'lesson_look.dart';

/// Learn tab: the 5-lesson course (required for the loan certificate) and
/// links to the reference material.
class CourseListScreen extends StatefulWidget {
  final bool isEmbeddedInPageView;

  const CourseListScreen({super.key, this.isEmbeddedInPageView = false});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _lang = 'uz';
  Set<int>? _done;

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    FarmStore.changes.addListener(_load);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First load needs the app locale, which is only readable from here.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    FarmStore.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = await LessonProgress.completed();
    if (!mounted) return;
    setState(() {
      _lang = CourseGuideData.normalizeLang(
        prefs.getString('app_language') ??
            Localizations.maybeLocaleOf(context)?.languageCode ??
            'uz',
      );
      _done = done;
    });
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    var section = 0;
    Widget reveal(Widget child) => Reveal(index: section++, child: child);

    final body = done == null
        ? const LoadingView()
        : PageBody(
            onRefresh: _load,
            children: [
              reveal(
                PageHeader(
                  title: _t("O'rganish", 'Обучение', 'Learn'),
                  subtitle: _t(
                    '5 ta qisqa dars — imtiyozli kredit uchun sertifikat',
                    '5 коротких уроков — сертификат для льготного кредита',
                    '5 short lessons — a certificate for a farm loan',
                  ),
                ),
              ),
              reveal(_buildProgress(done)),
              const Gap(AppSpace.xl),
              reveal(SectionHeader(title: _t('Darslar', 'Уроки', 'Lessons'))),
              ..._buildLessons(done).map(reveal),
              const Gap(AppSpace.xl),
              reveal(
                SectionHeader(
                  title: _t("Ma'lumotnoma", 'Справка', 'Reference'),
                ),
              ),
              reveal(
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ReferenceTile(
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          title: _t(
                            '42 kunlik reja',
                            'План на 42 дня',
                            '42-day plan',
                          ),
                          subtitle: _t(
                            'Har kun uchun harorat, yem, suv va vazifalar',
                            'Температура, корм, вода и задачи на каждый день',
                            'Temperature, feed, water and tasks for every day',
                          ),
                          onTap: () => _open('/daily-plan'),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: _ReferenceTile(
                          icon: Icons.chat_bubble_rounded,
                          color: AppColors.info,
                          title: _t(
                            "Yordamchidan so'rang",
                            'Спросите помощника',
                            'Ask the assistant',
                          ),
                          subtitle: _t(
                            'Ovoz, matn yoki rasm bilan',
                            'Голосом, текстом или по фото',
                            'By voice, text or photo',
                          ),
                          onTap: () => HomeTabs.of(
                            context,
                          )?.select(HomeScreen.assistantTab),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    if (widget.isEmbeddedInPageView) return body;
    return Scaffold(appBar: AppBar(), body: body);
  }

  /// Photo card: lessons ring, what's left, and one big white button.
  Widget _buildProgress(Set<int> done) {
    final total = LessonProgress.totalLessons;
    final next = LessonProgress.nextLesson(done);
    final finished = next == null;
    return PhotoCard(
      image: BroilerPhotos.finisher,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProgressRing(
                value: done.length / total,
                size: 84,
                stroke: 8,
                color: finished ? AppColors.gold : Colors.white,
                trackColor: Colors.white.withAlpha(56),
                child: finished
                    ? const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.gold,
                        size: 38,
                      )
                    : CountUpText(
                        value: done.length.toDouble(),
                        format: (v) => '${v.round()}/$total',
                        style: AppText.metric.copyWith(color: Colors.white),
                      ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        '${done.length} / $total dars tugatildi',
                        'Пройдено уроков: ${done.length} из $total',
                        '${done.length} of $total lessons done',
                      ),
                      style: AppText.section.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      finished
                          ? _t(
                              'Sertifikatingiz tayyor!',
                              'Ваш сертификат готов!',
                              'Your certificate is ready!',
                            )
                          : _t(
                              'Har bir dars ~1 daqiqa va 1 ta savol',
                              'Каждый урок ~1 минута и 1 вопрос',
                              'Each lesson is ~1 minute and 1 question',
                            ),
                      style: AppText.bodyMuted.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                shape: const StadiumBorder(),
              ),
              icon: Icon(
                finished
                    ? Icons.workspace_premium_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                finished
                    ? _t(
                        'Sertifikatni ochish',
                        'Открыть сертификат',
                        'Open certificate',
                      )
                    : (done.isEmpty
                          ? _t(
                              'Kursni boshlash',
                              'Начать курс',
                              'Start the course',
                            )
                          : _t(
                              'Davom etish: $next-dars',
                              'Продолжить: урок $next',
                              'Continue: lesson $next',
                            )),
              ),
              onPressed: () =>
                  _open(finished ? '/certificate' : '/course/$next'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLessons(Set<int> done) {
    final next = LessonProgress.nextLesson(done);
    final modules = CourseGuideData.getModules(_lang);
    final cards = <Widget>[];
    for (final m in modules) {
      if (cards.isNotEmpty) cards.add(const Gap());
      cards.add(
        _LessonCard(
          number: m.id,
          title: '${m.id}. ${m.title}',
          subtitle: m.subtitle,
          duration: m.durationLabel,
          done: done.contains(m.id),
          isNext: m.id == next,
          doneLabel: _t("O'tildi", 'Пройден', 'Done'),
          nextLabel: _t('Keyingi', 'Следующий', 'Up next'),
          onTap: () => _open('/course/${m.id}'),
        ),
      );
    }
    return cards;
  }
}

class _LessonCard extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final String duration;
  final bool done;
  final bool isNext;
  final String doneLabel;
  final String nextLabel;
  final VoidCallback onTap;

  const _LessonCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.done,
    required this.isNext,
    required this.doneLabel,
    required this.nextLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = lessonLook(number);
    return AppCard(
      onTap: onTap,
      borderColor: isNext ? AppColors.primary : null,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                  ),
                  boxShadow: AppShadow.glow(color),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              if (done)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    StatusPill(icon: Icons.schedule_rounded, label: duration),
                    if (done)
                      StatusPill(label: doneLabel, tone: Tone.primary)
                    else if (isNext)
                      StatusPill(
                        icon: Icons.play_arrow_rounded,
                        label: nextLabel,
                        tone: Tone.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

/// Square shortcut tile with a solid round icon.
class _ReferenceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReferenceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: AppShadow.glow(color),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppSpace.md),
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.caption),
        ],
      ),
    );
  }
}
