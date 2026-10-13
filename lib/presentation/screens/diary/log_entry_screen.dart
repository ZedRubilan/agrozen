import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../domain/alerts/alert_models.dart';
import '../../../services/farm_store.dart';
import '../../ui/components.dart';
import '../../ui/format.dart';

enum LogKind { deaths, feed, weight }

/// One screen for all three daily records — deaths, feed and sample weight —
/// so they look and behave the same.
class LogEntryScreen extends StatefulWidget {
  final LogKind kind;

  const LogEntryScreen({super.key, required this.kind});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FarmSnapshot? _farm;
  bool _saving = false;

  String get _lang => _farm?.lang ?? 'uz';
  Fmt get _fmt => Fmt(_lang);
  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final farm = await FarmStore.load();
    if (!mounted) return;
    setState(() => _farm = farm);
  }

  double? get _value =>
      double.tryParse(_controller.text.trim().replaceAll(',', '.'));

  void _add(double delta) {
    final next = (_value ?? 0) + delta;
    _controller.text = Fmt.num(next);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() {});
  }

  String? _validate(String? raw) {
    final farm = _farm;
    final value = double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
    if (value == null) {
      return _t('Son kiriting', 'Введите число', 'Enter a number');
    }
    if (value <= 0) {
      return _t(
        "Son 0 dan katta bo'lishi kerak",
        'Число должно быть больше 0',
        'Must be greater than 0',
      );
    }
    switch (widget.kind) {
      case LogKind.deaths:
        if (value != value.roundToDouble()) {
          return _t(
            'Butun son kiriting',
            'Введите целое число',
            'Enter a whole number',
          );
        }
        if (farm != null && value > farm.currentCount) {
          return _t(
            "Tirik jo'jalar sonidan ko'p bo'la olmaydi",
            'Не может превышать текущее поголовье',
            'Cannot exceed current flock size',
          );
        }
      case LogKind.feed:
        if (value > 20000) {
          return _t('Juda katta son', 'Слишком большое число', 'Too large');
        }
      case LogKind.weight:
        if (value < 20 || value > 6000) {
          return _t(
            'Grammda kiriting (20–6000)',
            'Введите в граммах (20–6000)',
            'Enter grams (20–6000)',
          );
        }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final value = _value!;
    setState(() => _saving = true);

    List<AlertResult> alerts = const [];
    switch (widget.kind) {
      case LogKind.deaths:
        alerts = await FarmStore.logDeaths(value.round());
      case LogKind.feed:
        await FarmStore.logFeed(value);
      case LogKind.weight:
        final alert = await FarmStore.logWeight(value);
        if (alert != null) alerts = [alert];
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (alerts.isNotEmpty) {
      await _showAlert(alerts.first, value);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Saqlandi', 'Сохранено', 'Saved'))),
      );
    }
    if (mounted && context.canPop()) context.pop(true);
  }

  Future<void> _showAlert(AlertResult alert, double value) async {
    final vet = await FarmStore.vetFor(_farm?.district ?? '');
    if (!mounted) return;
    final vetLine =
        '${vet?['name'] ?? _t('Tuman veterinari', 'Районный ветеринар', 'District vet')}'
        '\nTel: ${vet?['phone'] ?? '—'}';

    final String title;
    final String body;
    if (alert.type == AlertType.lowWeight) {
      final day = _farm?.batchDay ?? 1;
      title = _t(
        'Diqqat: Vazn ortda qolmoqda!',
        'Внимание: Отставание в весе!',
        'Warning: Below target weight!',
      );
      body = _t(
        "Vazn (${value.round()} g) $day-kun me'yoridan (${alert.threshold.round()} g) 15% dan ortiq kam.\n\nYem sifati va bino haroratini tekshiring, veterinar bilan maslahatlashing:\n$vetLine",
        'Вес (${value.round()} г) ниже нормы дня $day (${alert.threshold.round()} г) более чем на 15%.\n\nПроверьте корм и температуру, посоветуйтесь с ветеринаром:\n$vetLine',
        'Weight (${value.round()} g) is more than 15% below the Day $day target (${alert.threshold.round()} g).\n\nCheck feed quality and house temperature, and talk to your vet:\n$vetLine',
      );
    } else {
      final rate =
          '${alert.actualValue.toStringAsFixed(1)}% > ${alert.threshold.toStringAsFixed(1)}%';
      title = _t(
        'Diqqat: Yuqori nobodlik!',
        'Внимание: Высокий падёж!',
        'Warning: High mortality!',
      );
      body = _t(
        "Nobodlik me'yordan yuqori ($rate).\n\nZudlik bilan veterinarga murojaat qiling:\n$vetLine",
        'Падёж выше нормы ($rate).\n\nСрочно свяжитесь с ветеринаром:\n$vetLine',
        'Mortality is above the norm ($rate).\n\nContact your veterinarian now:\n$vetLine',
      );
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 40,
          color: alert.severity == AlertSeverity.critical
              ? AppColors.danger
              : AppColors.warning,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, style: AppText.body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Tushundim', 'Понятно', 'Understood')),
          ),
        ],
      ),
    );
  }

  /// Colour and picture of each record type, shared with Today and Diary.
  (IconData, Color) get _look => switch (widget.kind) {
    LogKind.deaths => (Icons.heart_broken_rounded, Tone.danger.solid),
    LogKind.feed => (Icons.grain_rounded, Tone.warning.solid),
    LogKind.weight => (Icons.scale_rounded, Tone.info.solid),
  };

  /// −/+ step on the round buttons beside the number.
  double get _step => switch (widget.kind) {
    LogKind.deaths => 1,
    LogKind.feed => 1,
    LogKind.weight => 10,
  };

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    final kind = widget.kind;

    final title = switch (kind) {
      LogKind.deaths => _t('Nobodlik qaydi', 'Запись падежа', 'Record deaths'),
      LogKind.feed => _t('Yem sarfi', 'Расход корма', 'Record feed'),
      LogKind.weight => _t('Nazorat vazni', 'Контрольный вес', 'Record weight'),
    };
    final question = switch (kind) {
      LogKind.deaths => _t(
        "Bugun nechta jo'ja nobud bo'ldi?",
        'Сколько птиц погибло сегодня?',
        'How many birds died today?',
      ),
      LogKind.feed => _t(
        'Hozir qancha yem berdingiz?',
        'Сколько корма вы дали сейчас?',
        'How much feed did you give now?',
      ),
      LogKind.weight => _t(
        "Jo'jalarning o'rtacha vazni qancha?",
        'Какой средний вес птицы?',
        'What is the average bird weight?',
      ),
    };
    final unit = switch (kind) {
      LogKind.deaths => _t('bosh', 'гол.', 'birds'),
      LogKind.feed => _t('kg', 'кг', 'kg'),
      LogKind.weight => _t('g', 'г', 'g'),
    };
    final quickAdds = switch (kind) {
      LogKind.deaths => const [1.0, 2.0, 5.0, 10.0],
      LogKind.feed => const [5.0, 10.0, 25.0, 50.0],
      LogKind.weight => const <double>[],
    };
    final (icon, color) = _look;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: farm == null
          ? const LoadingView()
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  Reveal(child: _buildHeader(farm, icon, color, question)),
                  const Gap(AppSpace.lg),
                  Reveal(
                    index: 1,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _RoundStep(
                                icon: Icons.remove_rounded,
                                color: color,
                                onTap: (_value ?? 0) >= _step
                                    ? () => _add(-_step)
                                    : null,
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _controller,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: kind != LogKind.deaths,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]'),
                                    ),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    color: AppColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.border,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    errorMaxLines: 2,
                                  ),
                                  validator: _validate,
                                  onChanged: (_) => setState(() {}),
                                  onFieldSubmitted: (_) => _save(),
                                ),
                              ),
                              _RoundStep(
                                icon: Icons.add_rounded,
                                color: color,
                                onTap: () => _add(_step),
                              ),
                            ],
                          ),
                          Text(
                            unit,
                            style: AppText.label.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          if (quickAdds.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.sm),
                            Row(
                              children: [
                                for (var i = 0; i < quickAdds.length; i++) ...[
                                  if (i > 0) const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: _QuickAdd(
                                      label: '+${Fmt.num(quickAdds[i])}',
                                      color: color,
                                      onTap: () => _add(quickAdds[i]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Gap(),
                  Reveal(index: 2, child: _buildGauge(farm, color)),
                ],
              ),
            ),
      bottomNavigationBar: farm == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.sm,
                AppSpace.screen,
                AppSpace.lg,
              ),
              child: PrimaryButton(
                icon: Icons.check_rounded,
                label: _t('Qaydni saqlash', 'Сохранить запись', 'Save entry'),
                busy: _saving,
                onPressed: _save,
              ),
            ),
    );
  }

  /// Tinted panel: big coloured disc, the question, and where we are now.
  Widget _buildHeader(
    FarmSnapshot farm,
    IconData icon,
    Color color,
    String question,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.82)!,
            Color.lerp(color, Colors.white, 0.94)!,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: AppShadow.glow(color),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question, style: AppText.section),
                const SizedBox(height: AppSpace.xs),
                Text(_contextLine(farm), style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Live check while typing: where this entry puts today against the norm.
  Widget _buildGauge(FarmSnapshot farm, Color color) {
    final entered = _value ?? 0;
    final double fill;
    final double? marker;
    final bool ok;
    final String reading;

    switch (widget.kind) {
      case LogKind.feed:
        final target = farm.requirements.totalDailyFeedKg;
        final total = farm.todayFeedKg + entered;
        fill = target > 0 ? total / target : 0;
        marker = null;
        ok = true;
        reading = _t(
          'Bugun jami: ${_fmt.kg(total)} / ${_fmt.kg(target)}',
          'Всего сегодня: ${_fmt.kg(total)} / ${_fmt.kg(target)}',
          'Today in total: ${_fmt.kg(total)} / ${_fmt.kg(target)}',
        );
      case LogKind.deaths:
        // Same formula as AlertEngine: today's deaths / birds at day start.
        final base = farm.currentCount + farm.todayDeaths;
        final pct = base > 0 ? (farm.todayDeaths + entered) / base * 100 : 0.0;
        const limit = 1.0; // norms.json mortality threshold, %/day
        fill = pct / (limit * 2); // the 1 % limit sits in the middle
        marker = 0.5;
        ok = pct <= limit;
        reading = _t(
          'Bugungi nobodlik: ${Fmt.num(pct)}% (me\'yor ≤ 1%)',
          'Падёж сегодня: ${Fmt.num(pct)}% (норма ≤ 1%)',
          "Today's mortality: ${Fmt.num(pct)}% (norm ≤ 1%)",
        );
      case LogKind.weight:
        final target = farm.spec.targetWeightG;
        final ratio = target > 0 ? entered / target : 0.0;
        fill = ratio / 1.2; // 100 % of target at 5/6 of the bar
        marker = 0.85 / 1.2; // the −15 % warning line
        ok = entered == 0 || ratio >= 0.85;
        reading = entered == 0
            ? _hintTitle(farm)
            : _t(
                "Me'yorning ${Fmt.num(ratio * 100, decimals: 0)}% · me'yor ${_fmt.grams(target)}",
                '${Fmt.num(ratio * 100, decimals: 0)}% от нормы · норма ${_fmt.grams(target)}',
                '${Fmt.num(ratio * 100, decimals: 0)}% of target · target ${_fmt.grams(target)}',
              );
    }

    final barColor = !ok
        ? AppColors.danger
        : (widget.kind == LogKind.feed && fill >= 1
              ? AppColors.primary
              : color);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.insights_rounded : Icons.warning_amber_rounded,
                size: 18,
                color: ok ? AppColors.inkSecondary : AppColors.danger,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(reading, style: AppText.label)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          _MarkerBar(value: fill, marker: marker, color: barColor),
          const SizedBox(height: AppSpace.md),
          Text(_hintBody(farm), style: AppText.caption),
        ],
      ),
    );
  }

  String _contextLine(FarmSnapshot farm) {
    switch (widget.kind) {
      case LogKind.deaths:
        return _t(
          "Hozir tirik: ${_fmt.birds(farm.currentCount)} · bugun yozilgan: ${farm.todayDeaths}",
          'Сейчас живых: ${_fmt.birds(farm.currentCount)} · сегодня записано: ${farm.todayDeaths}',
          'Alive now: ${_fmt.birds(farm.currentCount)} · recorded today: ${farm.todayDeaths}',
        );
      case LogKind.feed:
        return _t(
          'Bugun berilgan: ${_fmt.kg(farm.todayFeedKg)}. Yangi miqdor qo\'shiladi.',
          'Сегодня уже: ${_fmt.kg(farm.todayFeedKg)}. Новое количество прибавится.',
          'Given today: ${_fmt.kg(farm.todayFeedKg)}. This amount is added.',
        );
      case LogKind.weight:
        return _t(
          "10 ta jo'jani turli joydan olib torting va o'rtacha vaznni yozing.",
          'Взвесьте 10 птиц из разных мест птичника и запишите средний вес.',
          'Weigh 10 birds from different spots and enter the average.',
        );
    }
  }

  String _hintTitle(FarmSnapshot farm) {
    final day = farm.batchDay;
    switch (widget.kind) {
      case LogKind.deaths:
        return _t("Me'yor", 'Норма', 'Norm');
      case LogKind.feed:
        return _t(
          "$day-kun me'yori: ${_fmt.kg(farm.requirements.totalDailyFeedKg)}",
          'Норма дня $day: ${_fmt.kg(farm.requirements.totalDailyFeedKg)}',
          'Day $day target: ${_fmt.kg(farm.requirements.totalDailyFeedKg)}',
        );
      case LogKind.weight:
        return _t(
          "$day-kun me'yori: ${_fmt.grams(farm.spec.targetWeightG)}",
          'Норма дня $day: ${_fmt.grams(farm.spec.targetWeightG)}',
          'Day $day target: ${_fmt.grams(farm.spec.targetWeightG)}',
        );
    }
  }

  String _hintBody(FarmSnapshot farm) {
    switch (widget.kind) {
      case LogKind.deaths:
        return _t(
          "Sutkalik nobodlik 1% dan oshmasligi kerak. Oshsa — veterinarga murojaat qiling.",
          'Суточный падёж не должен превышать 1%. Если больше — обратитесь к ветеринару.',
          'Daily mortality should stay under 1%. If higher, contact your vet.',
        );
      case LogKind.feed:
        return _t(
          "${_fmt.grams(farm.spec.dailyFeedPerBirdG)} har bir jo'jaga · ${farm.spec.feedFormDescription(_lang)}",
          '${_fmt.grams(farm.spec.dailyFeedPerBirdG)} на птицу · ${farm.spec.feedFormDescription(_lang)}',
          '${_fmt.grams(farm.spec.dailyFeedPerBirdG)} per bird · ${farm.spec.feedFormDescription(_lang)}',
        );
      case LogKind.weight:
        return _t(
          "Me'yordan 15% kam bo'lsa, ilova sizni ogohlantiradi.",
          'Если вес ниже нормы более чем на 15%, приложение предупредит вас.',
          'If weight is more than 15% under target, the app will warn you.',
        );
    }
  }
}

/// Round −/+ button beside the big number.
class _RoundStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RoundStep({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color.withAlpha(36) : AppColors.surfaceMuted,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 52,
          child: Icon(
            icon,
            size: 26,
            color: enabled ? color : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Pill that adds a fixed amount ("+25").
class _QuickAdd extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAdd({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(28),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(label, style: AppText.label.copyWith(fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

/// Rounded bar that animates to [value] (0–1) with an optional limit line.
class _MarkerBar extends StatelessWidget {
  final double value;
  final double? marker;
  final Color color;

  const _MarkerBar({required this.value, required this.color, this.marker});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: 18,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                height: 12,
                width: w * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: (w * marker!).clamp(0.0, w - 2),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: AppColors.ink),
                ),
            ],
          ),
        );
      },
    );
  }
}
