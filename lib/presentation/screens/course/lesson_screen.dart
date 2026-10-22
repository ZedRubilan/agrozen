import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/external_actions.dart';
import '../../../services/lesson_progress.dart';
import '../../ui/broiler_photos.dart';
import '../../ui/components.dart';
import 'course_guide_data.dart';
import 'lesson_look.dart';

/// One lesson: the key rules, the takeaway, a short note and the quiz.
class LessonScreen extends StatefulWidget {
  final int lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String _lang = 'uz';
  bool _passed = false;
  bool _loaded = false;

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = await LessonProgress.completed();
    if (!mounted) return;
    setState(() {
      _lang = CourseGuideData.normalizeLang(
        prefs.getString('app_language') ?? 'uz',
      );
      _passed = done.contains(widget.lessonId);
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.lessonId.clamp(1, LessonProgress.totalLessons);
    final module = CourseGuideData.getModule(id, _lang);
    final (icon, color) = lessonLook(id);
    var i = 0;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('$id-dars (5 tadan)', 'Урок $id из 5', 'Lesson $id of 5'),
        ),
      ),
      body: !_loaded
          ? const LoadingView()
          : PageBody(
              children: [
                reveal(_buildHero(module, icon, color)),
                const Gap(AppSpace.xl),
                reveal(
                  SectionHeader(
                    title: _t(
                      'Asosiy qoidalar',
                      'Главные правила',
                      'Key rules',
                    ),
                  ),
                ),
                for (var p = 0; p < module.keyPoints.length; p++) ...[
                  if (p > 0) const Gap(),
                  reveal(_buildPoint(p + 1, module.keyPoints[p], color)),
                ],
                const Gap(AppSpace.lg),
                reveal(
                  _WhyCard(
                    title: _t(
                      'Nega bu muhim',
                      'Почему это важно',
                      'Why it matters',
                    ),
                    message: module.farmerTakeaway,
                  ),
                ),
                const Gap(AppSpace.xl),
                reveal(
                  SectionHeader(
                    title: _t('Batafsil', 'Подробнее', 'More detail'),
                  ),
                ),
                reveal(
                  AppCard(
                    child: Text(module.detailedNote, style: AppText.body),
                  ),
                ),
                const Gap(),
                reveal(
                  _VideoCard(
                    label: _t(
                      "Videoni ko'rish",
                      'Смотреть видео',
                      'Watch video',
                    ),
                    onTap: () => const ExternalActions().openVideo(
                      context,
                      module.videoUrl,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !_loaded
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.sm,
                AppSpace.screen,
                AppSpace.lg,
              ),
              child: PrimaryButton(
                icon: Icons.quiz_rounded,
                label: _passed
                    ? _t(
                        'Testni qayta topshirish',
                        'Пройти тест ещё раз',
                        'Retake the quiz',
                      )
                    : _t('Testni boshlash', 'Начать тест', 'Take the quiz'),
                onPressed: () async {
                  await context.push('/course/$id/quiz');
                  if (mounted) _load();
                },
              ),
            ),
    );
  }

  /// White card with the lesson's icon tile, title, subtitle, duration and
  /// passed state.
  Widget _buildHero(CourseModuleGuide module, IconData icon, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(36),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const Spacer(),
              StatusPill(
                label: module.durationLabel,
                icon: Icons.schedule_rounded,
              ),
              if (_passed) ...[
                const SizedBox(width: AppSpace.xs),
                StatusPill(
                  label: _t("O'tildi", 'Пройден', 'Passed'),
                  tone: Tone.primary,
                  icon: Icons.check_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(module.title, style: AppText.screenTitle.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpace.xs),
          Text(module.subtitle, style: AppText.bodyMuted),
        ],
      ),
    );
  }

  Widget _buildPoint(int n, CourseRulePoint point, Color color) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha(36),
                  shape: BoxShape.circle,
                ),
                child: Icon(point.icon, color: color, size: 24),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.title, style: AppText.cardTitle),
                const SizedBox(height: AppSpace.xs),
                StatusPill(label: point.badge, tone: Tone.warning),
                const SizedBox(height: AppSpace.sm),
                Text(
                  point.description,
                  style: AppText.bodyMuted.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Why it matters" on a soft green banner.
class _WhyCard extends StatelessWidget {
  final String title;
  final String message;

  const _WhyCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => NoticeBanner(
    tone: Tone.primary,
    icon: Icons.lightbulb_rounded,
    title: title,
    message: message,
  );
}

/// Photo card with a big white play button.
class _VideoCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _VideoCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: PhotoCard(
          image: BroilerPhotos.chicksFeederLine,
          child: SizedBox(
            height: 110,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.raised,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primaryDark,
                    size: 36,
                  ),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.section.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
