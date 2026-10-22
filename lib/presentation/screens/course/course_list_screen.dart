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
              const Gap(AppSpace.lg),
              reveal(SectionHeader(title: _t('Darslar', 'Уроки', 'Lessons'))),
              reveal(ListGroup(children: _buildLessons(done))),
              const Gap(AppSpace.lg),
              reveal(
                DetailSection(
                  title: _t("Ma'lumotnoma", 'Справка', 'Reference'),
                  subtitle: _t(
                    '42 kunlik reja va yordamchi',
                    'План на 42 дня и помощник',
                    '42-day plan and assistant',
                  ),
                  icon: Icons.menu_book_outlined,
                  children: [
                    ListRow(
                      icon: Icons.calendar_month_rounded,
                      title: _t(
                        '42 kunlik reja',
                        'План на 42 дня',
                        '42-day plan',
                      ),
                      onTap: () => _open('/daily-plan'),
                    ),
                    ListRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: _t(
                        "Yordamchidan so'rang",
                        'Спросите помощника',
                        'Ask the assistant',
                      ),
                      onTap: () =>
                          HomeTabs.of(context)?.select(HomeScreen.assistantTab),
                    ),
                  ],
                ),
              ),
            ],
          );

    if (widget.isEmbeddedInPageView) return body;
    return Scaffold(appBar: AppBar(), body: body);
  }

  /// Course progress with one clear next action.
  Widget _buildProgress(Set<int> done) {
    final total = LessonProgress.totalLessons;
    final next = LessonProgress.nextLesson(done);
    final finished = next == null;
    return SummaryCard(
      image: BroilerPhotos.finisher,
      title: _t(
        '${done.length} / $total dars tugatildi',
        'Пройдено уроков: ${done.length} из $total',
        '${done.length} of $total lessons done',
      ),
      subtitle: finished
          ? _t(
              'Sertifikatingiz tayyor!',
              'Ваш сертификат готов!',
              'Your certificate is ready!',
            )
          : _t(
              'Har bir dars ~1 daqiqa',
              'Каждый урок ~1 минута',
              'About 1 minute per lesson',
            ),
      progress: done.length / total,
      action: PrimaryButton(
        icon: finished
            ? Icons.workspace_premium_rounded
            : Icons.play_arrow_rounded,
        label: finished
            ? _t(
                'Sertifikatni ochish',
                'Открыть сертификат',
                'Open certificate',
              )
            : (done.isEmpty
                  ? _t('Kursni boshlash', 'Начать курс', 'Start the course')
                  : _t(
                      'Davom etish: $next-dars',
                      'Продолжить: урок $next',
                      'Continue: lesson $next',
                    )),
        onPressed: () => _open(finished ? '/certificate' : '/course/$next'),
      ),
    );
  }

  List<Widget> _buildLessons(Set<int> done) {
    final next = LessonProgress.nextLesson(done);
    final modules = CourseGuideData.getModules(_lang);
    final cards = <Widget>[];
    for (final m in modules) {
      cards.add(
        _LessonCard(
          number: m.id,
          title: m.title,
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
  final String duration;
  final bool done;
  final bool isNext;
  final String doneLabel;
  final String nextLabel;
  final VoidCallback onTap;

  const _LessonCard({
    required this.number,
    required this.title,
    required this.duration,
    required this.done,
    required this.isNext,
    required this.doneLabel,
    required this.nextLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: isNext ? AppColors.primarySoft : Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            // Same footprint as an IconBadge so the list lines up with others.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: done
                    ? AppColors.primary
                    : isNext
                    ? AppColors.surface
                    : AppColors.surfaceMuted,
              ),
              child: Center(
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : Text('$number', style: AppText.label),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.cardTitle),
                  const Gap(AppSpace.xs),
                  Text(
                    done
                        ? '$doneLabel · $duration'
                        : isNext
                        ? '$nextLabel · $duration'
                        : duration,
                    style: AppText.caption.copyWith(
                      color: isNext
                          ? AppColors.primaryDark
                          : AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Icon(
              isNext
                  ? Icons.play_circle_outline_rounded
                  : Icons.chevron_right_rounded,
              color: isNext ? AppColors.primary : AppColors.inkMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
