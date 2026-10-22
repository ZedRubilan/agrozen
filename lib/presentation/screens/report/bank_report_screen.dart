import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../services/farm_store.dart';
import '../../../services/lesson_progress.dart';
import '../../../services/loan_report.dart';
import '../../../services/report_export.dart';
import '../../ui/broiler_photos.dart';
import '../../ui/components.dart';
import '../../ui/format.dart';
import '../../widgets/agro_icons.dart';

/// The batch report for the farmer's bank or insurer: flock survival, diary
/// discipline, growth against Ross-308 and the course — scored by plain rules
/// and shared as a PDF only after the farmer agrees.
class BankReportScreen extends StatefulWidget {
  const BankReportScreen({super.key});

  @override
  State<BankReportScreen> createState() => _BankReportScreenState();
}

class _BankReportScreenState extends State<BankReportScreen> {
  final _paperKey = GlobalKey();
  LoanReport? _report;
  DateTime? _consentAt;
  bool _loaded = false;
  bool _sharing = false;

  String get _lang => _report?.farm.lang ?? 'uz';
  Fmt get _fmt => Fmt(_lang);
  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    final lessons = await LessonProgress.completed();
    var limit = 4.0;
    try {
      final norms = await KnowledgeRepository().getParsedNorms();
      limit = norms.cumulativeMortalityThresholdPercent;
    } catch (_) {
      // Keep the shipped 4 % threshold.
    }
    final consent = await ReportConsent.givenAt();
    if (!mounted) return;
    setState(() {
      _report = LoanReport.build(
        farm: farm,
        lessonsDone: lessons.length,
        cumulativeMortalityLimitPct: limit,
      );
      _consentAt = consent;
      _loaded = true;
    });
  }

  Future<void> _giveConsent() async {
    await ReportConsent.give();
    final at = await ReportConsent.givenAt();
    if (mounted) setState(() => _consentAt = at);
  }

  Future<void> _revokeConsent() async {
    await ReportConsent.revoke();
    if (mounted) setState(() => _consentAt = null);
  }

  Future<void> _sharePdf() async {
    final boundary = _paperKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    setState(() => _sharing = true);
    try {
      const ratio = 3.0;
      final png = await ReportExport.capture(boundary, pixelRatio: ratio);
      final pdf = await ReportExport.pdfFromPng(
        png,
        widthPx: (boundary.size.width * ratio).round(),
        heightPx: (boundary.size.height * ratio).round(),
        title: _t('AgroZen hisoboti', 'Отчёт AgroZen', 'AgroZen report'),
      );
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await ReportExport.share(
        pdf,
        fileName: 'agrozen_report_$stamp.pdf',
        text: _t(
          'AgroZen: broyler partiyasi hisoboti',
          'AgroZen: отчёт о партии бройлеров',
          'AgroZen: broiler batch report',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                "PDF yaratib bo'lmadi. Qayta urinib ko'ring.",
                'Не удалось создать PDF. Попробуйте ещё раз.',
                "Couldn't create the PDF. Please try again.",
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Bank uchun hisobot', 'Отчёт для банка', 'Bank report')),
      ),
      body: !_loaded || report == null
          ? const LoadingView()
          : _consentAt == null
          ? _buildConsent(report)
          : _buildReport(report),
    );
  }

  // --- Consent --------------------------------------------------------------

  Widget _buildConsent(LoanReport report) {
    var section = 0;
    Widget reveal(Widget child) => Reveal(index: section++, child: child);

    Widget point(IconData icon, Tone tone, String text) =>
        ListRow(icon: icon, tone: tone, title: text);

    return Column(
      children: [
        Expanded(
          child: PageBody(
            children: [
              reveal(
                PhotoCard(
                  image: BroilerPhotos.farmAerial,
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadow.glow(Colors.white),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        _t(
                          "Bankka partiyangizni ko'rsating",
                          'Покажите банку свою партию',
                          'Show your bank how the batch is going',
                        ),
                        style: AppText.screenTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        _t(
                          "Kundalikni to'liq yuritgan fermerga imtiyozli kredit olish va uni qaytarish osonroq.",
                          'Фермеру, который ведёт дневник, проще получить льготный кредит и вернуть его.',
                          'A farmer who keeps the diary finds it easier to get a concessional loan and repay it.',
                        ),
                        style: AppText.body.copyWith(
                          color: Colors.white.withAlpha(225),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpace.xl),
              reveal(
                SectionHeader(
                  title: _t(
                    'Hisobotga kiradi',
                    'В отчёт войдёт',
                    "What's in the report",
                  ),
                ),
              ),
              reveal(
                ListGroup(
                  children: [
                    point(
                      Icons.pets_rounded,
                      Tone.primary,
                      _t(
                        'Parrandalar soni va saqlanish',
                        'Поголовье и сохранность',
                        'Flock size and survival',
                      ),
                    ),
                    point(
                      Icons.trending_down_rounded,
                      Tone.danger,
                      _t(
                        "Haftalar bo'yicha nobudlik",
                        'Падёж по неделям',
                        'Losses week by week',
                      ),
                    ),
                    point(
                      Icons.monitor_weight_rounded,
                      Tone.info,
                      _t(
                        "Vazn va yem — Ross-308 me'yoriga nisbatan",
                        'Вес и корм в сравнении с Ross-308',
                        'Weight and feed against Ross-308',
                      ),
                    ),
                    point(
                      Icons.school_rounded,
                      Tone.warning,
                      _t(
                        'Kundalik intizomi va kurs',
                        'Дисциплина дневника и курс',
                        'Diary discipline and the course',
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(),
              reveal(
                NoticeBanner(
                  tone: Tone.info,
                  icon: Icons.lock_rounded,
                  title: _t(
                    'Telefoningizdan faqat siz yuborasiz',
                    'Отправляете только вы, со своего телефона',
                    'Only you send it, from your own phone',
                  ),
                  message: _t(
                    "Savollaringiz, rasmlaringiz va kontaktlaringiz hisobotga kirmaydi. Roziligingizni istalgan vaqtda qaytarib olishingiz mumkin.",
                    'Ваши вопросы, фото и контакты в отчёт не попадают. Согласие можно отозвать в любой момент.',
                    'Your questions, photos and contacts are never included. You can withdraw consent at any time.',
                  ),
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          child: PrimaryButton(
            label: _t(
              'Roziman, hisobot tuzish',
              'Согласен, сформировать отчёт',
              'I agree, build the report',
            ),
            icon: Icons.verified_user_rounded,
            onPressed: _giveConsent,
          ),
        ),
      ],
    );
  }

  // --- Report ---------------------------------------------------------------

  Widget _buildReport(LoanReport report) {
    var section = 0;
    Widget reveal(Widget child) => Reveal(index: section++, child: child);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: RepaintBoundary(
                  key: _paperKey,
                  child: ColoredBox(
                    color: AppColors.background,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen,
                        AppSpace.lg,
                        AppSpace.screen,
                        AppSpace.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          reveal(_header(report)),
                          const Gap(),
                          reveal(_scoreCard(report)),
                          const Gap(AppSpace.xl),
                          reveal(
                            SectionHeader(
                              title: _t(
                                "Asosiy ko'rsatkichlar",
                                'Ключевые показатели',
                                'Key figures',
                              ),
                            ),
                          ),
                          reveal(_metrics(report)),
                          const Gap(AppSpace.xl),
                          reveal(
                            SectionHeader(
                              title: _t(
                                "Haftalar bo'yicha nobudlik",
                                'Падёж по неделям',
                                'Losses by week',
                              ),
                            ),
                          ),
                          reveal(_weeks(report)),
                          const Gap(AppSpace.lg),
                          reveal(_footer(report)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _BottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: _t('PDF yuborish', 'Отправить PDF', 'Share PDF'),
                icon: Icons.picture_as_pdf_rounded,
                busy: _sharing,
                onPressed: _sharePdf,
              ),
              TextButton(
                onPressed: _revokeConsent,
                child: Text(
                  _t(
                    'Rozilikni qaytarib olish',
                    'Отозвать согласие',
                    'Withdraw consent',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(LoanReport r) {
    final farm = r.farm;
    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());
    Widget fact(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AgroChickIcon(size: 44),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Broyler partiyasi hisoboti',
                        'Отчёт о партии бройлеров',
                        'Broiler batch report',
                      ),
                      style: AppText.section,
                    ),
                    const SizedBox(height: 2),
                    Text('AgroZen · $date', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              fact(_t('Fermer', 'Фермер', 'Farmer'), farm.farmerName),
              fact(_t('Hudud', 'Район', 'District'), farm.locationLabel),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              fact(
                _t('Partiya kuni', 'День партии', 'Batch day'),
                _fmt.dayOf(farm.batchDay, 42),
              ),
              fact(
                _t('Kelgan sana', 'Дата завоза', 'Placed on'),
                DateFormat('dd.MM.yyyy').format(farm.arrivalDate),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              fact(
                _t("Qo'yilgan", 'Посажено', 'Placed'),
                _fmt.birds(farm.initialCount),
              ),
              fact(
                _t('Tirik', 'Живых', 'Alive'),
                _fmt.birds(farm.currentCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, Tone tone}) _riskLook(LoanRisk risk) {
    switch (risk) {
      case LoanRisk.low:
        return (
          label: _t('Past xavf', 'Низкий риск', 'Low risk'),
          tone: Tone.primary,
        );
      case LoanRisk.medium:
        return (
          label: _t("O'rtacha xavf", 'Средний риск', 'Medium risk'),
          tone: Tone.warning,
        );
      case LoanRisk.high:
        return (
          label: _t('Yuqori xavf', 'Высокий риск', 'High risk'),
          tone: Tone.danger,
        );
    }
  }

  Widget _scoreCard(LoanReport r) {
    final look = _riskLook(r.risk);
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                value: r.score / LoanReport.maxScore,
                size: 104,
                stroke: 10,
                color: look.tone.solid,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountUpText(
                      value: r.score.toDouble(),
                      format: (v) => v.round().toString(),
                      style: AppText.display,
                    ),
                    Text(
                      _t('100 dan', 'из 100', 'of 100'),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Kreditni qaytarish ishonchliligi',
                        'Надёжность возврата кредита',
                        'Loan repayment reliability',
                      ),
                      style: AppText.cardTitle,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    StatusPill(
                      label: look.label,
                      tone: look.tone,
                      icon: Icons.shield_rounded,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      _t(
                        "Qoidalar bo'yicha hisoblanadi, neyrotarmoq emas",
                        'Считается по правилам, а не нейросетью',
                        'Scored by fixed rules, not by AI',
                      ),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          for (final f in r.factors) ...[
            _factorRow(r, f),
            if (f != r.factors.last) const SizedBox(height: AppSpace.md),
          ],
        ],
      ),
    );
  }

  Widget _factorRow(LoanReport r, ReportFactor f) {
    final farm = r.farm;
    final (String title, String detail, IconData icon) = switch (f.key) {
      'survival' => (
        _t('Saqlanish', 'Сохранность', 'Survival'),
        _t(
          "Nobudlik ${Fmt.num(farm.cumulativeMortalityPct)}% (chegara ${Fmt.num(r.cumulativeMortalityLimitPct)}%)",
          'Падёж ${Fmt.num(farm.cumulativeMortalityPct)}% (порог ${Fmt.num(r.cumulativeMortalityLimitPct)}%)',
          'Losses ${Fmt.num(farm.cumulativeMortalityPct)}% (limit ${Fmt.num(r.cumulativeMortalityLimitPct)}%)',
        ),
        Icons.favorite_rounded,
      ),
      'diary' => (
        _t('Kundalik', 'Дневник', 'Diary'),
        _t(
          '${farm.batchDay} kundan ${r.daysRecorded} kun yozilgan',
          'Записи за ${r.daysRecorded} из ${farm.batchDay} дн.',
          '${r.daysRecorded} of ${farm.batchDay} days recorded',
        ),
        Icons.edit_note_rounded,
      ),
      'weight' => (
        _t('Vazn', 'Вес', 'Weight'),
        r.weightVsTarget == null
            ? _t("Hali tortilmagan", 'Ещё не взвешивали', 'Not weighed yet')
            : _t(
                "Me'yorning ${Fmt.num(r.weightVsTarget! * 100, decimals: 0)}%",
                '${Fmt.num(r.weightVsTarget! * 100, decimals: 0)}% от нормы',
                '${Fmt.num(r.weightVsTarget! * 100, decimals: 0)}% of target',
              ),
        Icons.monitor_weight_rounded,
      ),
      _ => (
        _t("O'qish", 'Обучение', 'Training'),
        r.certified
            ? _t(
                'Sertifikat olingan',
                'Сертификат получен',
                'Certificate earned',
              )
            : _t(
                '${LessonProgress.totalLessons} darsdan ${r.lessonsDone} tasi',
                '${r.lessonsDone} из ${LessonProgress.totalLessons} уроков',
                '${r.lessonsDone} of ${LessonProgress.totalLessons} lessons',
              ),
        Icons.school_rounded,
      ),
    };
    final tone = f.share >= 0.75
        ? Tone.primary
        : (f.share >= 0.4 ? Tone.warning : Tone.danger);

    return Row(
      children: [
        IconBadge(icon: icon, tone: tone, size: 36),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppText.cardTitle)),
                  Text(
                    '${f.points} / ${f.maxPoints}',
                    style: AppText.label.copyWith(color: tone.foreground),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(detail, style: AppText.caption),
              const SizedBox(height: AppSpace.xs),
              AppProgressBar(value: f.share, color: tone.foreground),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metrics(LoanReport r) {
    final farm = r.farm;
    final survivalNorm = 100 - r.cumulativeMortalityLimitPct;
    final weightRatio = r.weightVsTarget;
    return MetricGrid(
      children: [
        MetricTile(
          icon: Icons.favorite_rounded,
          tone: farm.survivalPct >= survivalNorm ? Tone.primary : Tone.danger,
          label: _t('Saqlanish', 'Сохранность', 'Survival'),
          value: '${Fmt.num(farm.survivalPct)}%',
          caption: _t(
            "Me'yor: kamida ${Fmt.num(survivalNorm)}%",
            'Норма: от ${Fmt.num(survivalNorm)}%',
            'Norm: at least ${Fmt.num(survivalNorm)}%',
          ),
        ),
        MetricTile(
          icon: Icons.edit_note_rounded,
          tone: r.diaryCoverage >= 0.8 ? Tone.primary : Tone.warning,
          label: _t('Yozuvli kunlar', 'Дни с записями', 'Days recorded'),
          value: '${Fmt.num(r.diaryCoverage * 100, decimals: 0)}%',
          caption: _t(
            'Pilot maqsadi: kamida 80%',
            'Цель пилота: от 80%',
            'Pilot target: at least 80%',
          ),
        ),
        MetricTile(
          icon: Icons.monitor_weight_rounded,
          tone: weightRatio == null
              ? Tone.neutral
              : (weightRatio >= 0.95 ? Tone.primary : Tone.warning),
          label: _t("O'rtacha vazn", 'Средний вес', 'Average weight'),
          value: farm.hasWeight ? _fmt.grams(farm.lastWeightG) : '—',
          caption: _t(
            "Me'yor ${_fmt.grams(farm.targetForLastWeight)}",
            'Норма ${_fmt.grams(farm.targetForLastWeight)}',
            'Target ${_fmt.grams(farm.targetForLastWeight)}',
          ),
        ),
        MetricTile(
          icon: Icons.grass_rounded,
          tone: r.fcr == null
              ? Tone.neutral
              : (r.fcr! <= r.spec.targetFcr * 1.05
                    ? Tone.primary
                    : Tone.warning),
          label: _t('Yem konversiyasi', 'Конверсия корма', 'Feed conversion'),
          value: r.fcr == null ? '—' : Fmt.num(r.fcr!, decimals: 2),
          caption: r.fcr == null
              ? _t(
                  'Har kungi yem va vazn kerak',
                  'Нужны корм за каждый день и вес',
                  'Needs daily feed and a weighing',
                )
              : _t(
                  "Me'yor ${Fmt.num(r.spec.targetFcr, decimals: 2)}",
                  'Норма ${Fmt.num(r.spec.targetFcr, decimals: 2)}',
                  'Target ${Fmt.num(r.spec.targetFcr, decimals: 2)}',
                ),
        ),
      ],
    );
  }

  Widget _weeks(LoanReport r) {
    if (r.weeks.every((w) => w.deaths == 0)) {
      return AppCard(
        child: Text(
          _t(
            "Nobudlik yozilmagan.",
            'Падёж не записан.',
            'No losses recorded.',
          ),
          style: AppText.bodyMuted,
        ),
      );
    }
    final maxPct = r.weeks.fold(0.0, (m, w) => w.pct > m ? w.pct : m);
    return AppCard(
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final w in r.weeks)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${Fmt.num(w.pct)}%', style: AppText.label),
                          const SizedBox(height: AppSpace.xs),
                          AnimatedContainer(
                            duration: AppMotion.medium,
                            height: maxPct > 0 ? 96 * w.pct / maxPct + 2 : 2,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(
                                w.pct == maxPct ? 255 : 150,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
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
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (final w in r.weeks)
                Expanded(
                  child: Text(
                    _t('${w.week}-hafta', '${w.week} нед.', 'Wk ${w.week}'),
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            _t(
              "Har bir ustun — haftadagi nobudlik, qo'yilgan jo'jalarga nisbatan.",
              'Каждый столбец — падёж за неделю от числа посаженных цыплят.',
              'Each bar is the week\'s losses as a share of chicks placed.',
            ),
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _footer(LoanReport r) {
    final consent = _consentAt == null
        ? ''
        : DateFormat('dd.MM.yyyy HH:mm').format(_consentAt!);
    return Text(
      _t(
        "Fermer ma'lumot berishga rozilik bergan: $consent. Ma'lumotlar AgroZen kundaligidan; me'yorlar Ross-308 / Cobb-500. Hisobot tibbiy xulosa emas.",
        'Фермер дал согласие на передачу данных $consent. Данные из дневника AgroZen, нормы Ross-308 / Cobb-500. Отчёт не является ветеринарным заключением.',
        'The farmer agreed to share this data on $consent. Data from the AgroZen diary; norms: Ross-308 / Cobb-500. Not a veterinary opinion.',
      ),
      style: AppText.caption,
      textAlign: TextAlign.center,
    );
  }
}

/// White bar pinned to the bottom with the screen's main action.
class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadow.raised,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.md,
                AppSpace.screen,
                AppSpace.md,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
