import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/farm_store.dart';
import '../../../services/lesson_progress.dart';
import '../../ui/components.dart';
import 'lesson_look.dart';
import '../../widgets/agro_icons.dart';

/// Readiness certificate, issued only after all 5 lessons are passed.
class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  FarmSnapshot? _farm;
  Set<int> _done = {};

  String get _lang => _farm?.lang ?? 'uz';
  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    final done = await LessonProgress.completed();
    if (!mounted) return;
    setState(() {
      _farm = farm;
      _done = done;
    });
  }

  Future<void> _share(String date) async {
    final farm = _farm!;
    final text = _t(
      "AgroZen — Tayyorgarlik sertifikati\nFermer: ${farm.farmerName} (${farm.locationLabel})\nBroyler yetishtirish bo'yicha tayyorgarlik kursi yakunlandi. Sana: $date",
      'AgroZen — Сертификат готовности\nФермер: ${farm.farmerName} (${farm.locationLabel})\nПройден вводный курс по выращиванию бройлеров. Дата: $date',
      'AgroZen — Readiness Certificate\nFarmer: ${farm.farmerName} (${farm.locationLabel})\nCompleted broiler farming readiness training. Date: $date',
    );
    try {
      await Share.share(text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              "Ulashib bo'lmadi.",
              'Не удалось поделиться.',
              'Could not open sharing.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    final complete = _done.length >= LessonProgress.totalLessons;
    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'Tayyorgarlik sertifikati',
            'Сертификат готовности',
            'Readiness certificate',
          ),
        ),
      ),
      body: farm == null
          ? const LoadingView()
          : Stack(
              children: [
                PageBody(
                  children: complete
                      ? [
                          Reveal(child: _buildCertificate(farm, date)),
                          const Gap(AppSpace.lg),
                          PrimaryButton(
                            icon: Icons.share_rounded,
                            label: _t('Ulashish', 'Поделиться', 'Share'),
                            onPressed: () => _share(date),
                          ),
                        ]
                      : [Reveal(child: _buildLocked())],
                ),
                if (complete) const Positioned.fill(child: ConfettiBurst()),
              ],
            ),
    );
  }

  /// Cream "paper" with a double gold frame, the AgroZen medal and the name.
  Widget _buildCertificate(FarmSnapshot farm, String date) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7D774), AppColors.gold, Color(0xFFB7791F)],
        ),
        boxShadow: AppShadow.glow(AppColors.gold),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.xl,
          AppSpace.xl,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg - 4),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEB), Colors.white],
          ),
          border: Border.all(color: AppColors.gold.withAlpha(120)),
        ),
        child: Column(
          children: [
            const _ShiningMedal(),
            const Gap(AppSpace.lg),
            Text(
              _t('SERTIFIKAT', 'СЕРТИФИКАТ', 'CERTIFICATE'),
              style: AppText.section.copyWith(
                letterSpacing: 4,
                color: const Color(0xFF92600A),
              ),
            ),
            const Text('AgroZen', style: AppText.caption),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.gold.withAlpha(110))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                ),
                Expanded(child: Divider(color: AppColors.gold.withAlpha(110))),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              _t(
                'Ushbu sertifikat tasdiqlaydiki,',
                'Настоящим подтверждается, что',
                'This certificate confirms that',
              ),
              style: AppText.bodyMuted,
            ),
            const Gap(AppSpace.sm),
            Text(
              farm.farmerName,
              textAlign: TextAlign.center,
              style: AppText.screenTitle.copyWith(fontSize: 26),
            ),
            Text(farm.locationLabel, style: AppText.caption),
            const Gap(),
            Text(
              _t(
                "broyler jo'jalarini yetishtirish texnologiyasi, biologik xavfsizlik va parvarishlash me'yorlari bo'yicha tayyorgarlik kursini muvaffaqiyatli yakunladi.",
                'успешно прошёл(ла) вводный курс по технологии выращивания бройлеров, биобезопасности и нормам содержания.',
                'has successfully completed the introductory course on broiler management, biosecurity and welfare standards.',
              ),
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
            const Gap(AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_t('Sana', 'Дата', 'Date')}: $date',
                    style: AppText.label,
                  ),
                ),
                StatusPill(
                  label: _t('5/5 dars', '5/5 уроков', '5/5 lessons'),
                  tone: Tone.primary,
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Not earned yet: progress ring and the five lessons, done ones ticked.
  Widget _buildLocked() {
    final total = LessonProgress.totalLessons;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        children: [
          ProgressRing(
            value: _done.length / total,
            size: 120,
            stroke: 10,
            color: AppColors.gold,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.gold, size: 28),
                Text('${_done.length}/$total', style: AppText.metric),
              ],
            ),
          ),
          const Gap(AppSpace.lg),
          Text(
            _t(
              'Avval 5 ta darsni tugating',
              'Сначала пройдите все 5 уроков',
              'Finish all 5 lessons first',
            ),
            textAlign: TextAlign.center,
            style: AppText.section,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _t(
              'Tugatildi: ${_done.length} / 5',
              'Пройдено: ${_done.length} из 5',
              'Done: ${_done.length} of 5',
            ),
            style: AppText.bodyMuted,
          ),
          const Gap(AppSpace.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var id = 1; id <= total; id++) ...[
                if (id > 1) const SizedBox(width: AppSpace.sm),
                _lessonDot(id),
              ],
            ],
          ),
          const Gap(AppSpace.xl),
          PrimaryButton(
            label: _t('Darslarga qaytish', 'К урокам', 'Back to lessons'),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home?tab=3'),
          ),
        ],
      ),
    );
  }

  Widget _lessonDot(int id) {
    final (icon, color) = lessonLook(id);
    final done = _done.contains(id);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: done ? color : AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: done ? Colors.white : AppColors.inkMuted,
          ),
        ),
        if (done)
          const Positioned(
            right: -4,
            bottom: -4,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.surface,
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// The AgroZen chick medal in a gold ring, with one light sweep across it.
class _ShiningMedal extends StatelessWidget {
  const _ShiningMedal();

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final medal = Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7D774), Color(0xFFB7791F)],
        ),
      ),
      child: const AgroChickIcon(size: 96),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : -1, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOut,
      builder: (context, v, child) {
        if (v >= 1) return child!;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(v * 2 - 1, -1),
            end: Alignment(v * 2 + 0.2, 1),
            colors: [
              Colors.white.withAlpha(0),
              Colors.white.withAlpha(150),
              Colors.white.withAlpha(0),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          child: child,
        );
      },
      child: medal,
    );
  }
}
