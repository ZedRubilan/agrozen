import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/localization/app_strings.dart';
import '../../domain/broiler/broiler_grower_library.dart';
import '../ui/components.dart';
import '../ui/format.dart';

/// The farmer's sample weighings against the Ross-308 / Cobb-500 target curve.
/// Shows day 1 up to a week past today (at least 14 days) so early weighings
/// are not squashed; the scale fits that window. Tap or drag to read a day.
///
/// Colours: measured = primary green, target = info blue (dashed). The pair
/// passes the dataviz palette validator (CVD ΔE 27, normal-vision ΔE 30).
class GrowthChartCard extends StatefulWidget {
  /// Batch day → measured average weight in grams.
  final Map<int, double> weighings;
  final int batchDay;
  final String lang;

  const GrowthChartCard({
    super.key,
    required this.weighings,
    required this.batchDay,
    required this.lang,
  });

  @override
  State<GrowthChartCard> createState() => _GrowthChartCardState();
}

class _GrowthChartCardState extends State<GrowthChartCard> {
  int? _selected;

  /// Last day on the x axis: a week ahead of today, 14..42.
  int get _lastDay => (widget.batchDay + 7).clamp(14, 42);

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: widget.lang, uz: uz, ru: ru, en: en);

  List<double> get _target => [
    for (var d = 1; d <= 42; d++)
      BroilerGrowerLibrary.specForDay(d).targetWeightG,
  ];

  void _pick(Offset local, Size size) {
    final plot = _GrowthPainter.plotRect(size);
    final t = ((local.dx - plot.left) / plot.width).clamp(0.0, 1.0);
    final day = (1 + t * (_lastDay - 1)).round();
    if (day != _selected) setState(() => _selected = day);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = Fmt(widget.lang);
    final target = _target;
    final day = _selected;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.xs,
            children: [
              _LegendKey(
                color: AppColors.primary,
                label: _t(
                  'Sizning tortishlaringiz',
                  'Ваши взвешивания',
                  'Your weighings',
                ),
              ),
              _LegendKey(
                color: AppColors.info,
                dashed: true,
                label: _t(
                  "Me'yor (Ross-308)",
                  'Норма (Ross-308)',
                  'Target (Ross-308)',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AspectRatio(
            aspectRatio: 1.6,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _pick(d.localPosition, size),
                  onHorizontalDragUpdate: (d) => _pick(d.localPosition, size),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration:
                        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                        ? Duration.zero
                        : AppMotion.count,
                    curve: Curves.easeOutCubic,
                    builder: (context, reveal, _) => CustomPaint(
                      size: size,
                      painter: _GrowthPainter(
                        target: target,
                        weighings: widget.weighings,
                        today: widget.batchDay,
                        lastDay: _lastDay,
                        selected: day,
                        reveal: reveal,
                        kgUnit: _t('kg', 'кг', 'kg'),
                        gUnit: _t('g', 'г', 'g'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: day == null
                ? Text(
                    _t(
                      "Kunni ko'rish uchun grafikka bosing",
                      'Нажмите на график, чтобы увидеть день',
                      'Tap the chart to read a day',
                    ),
                    key: const ValueKey('hint'),
                    style: AppText.caption,
                  )
                : Row(
                    key: ValueKey(day),
                    children: [
                      StatusPill(label: fmt.day(day), tone: Tone.neutral),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          [
                            if (widget.weighings[day] != null)
                              _t(
                                'Tortildi: ${fmt.grams(widget.weighings[day]!)}',
                                'Взвешено: ${fmt.grams(widget.weighings[day]!)}',
                                'Weighed: ${fmt.grams(widget.weighings[day]!)}',
                              ),
                            _t(
                              "Me'yor: ${fmt.grams(target[day - 1])}",
                              'Норма: ${fmt.grams(target[day - 1])}',
                              'Target: ${fmt.grams(target[day - 1])}',
                            ),
                          ].join(' · '),
                          style: AppText.label,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendKey extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendKey({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 10,
          child: CustomPaint(painter: _KeyPainter(color, dashed)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ],
    );
  }
}

class _KeyPainter extends CustomPainter {
  final Color color;
  final bool dashed;

  _KeyPainter(this.color, this.dashed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (dashed) {
      canvas.drawLine(Offset(0, y), Offset(6, y), paint);
      canvas.drawLine(Offset(11, y), Offset(size.width, y), paint);
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      canvas.drawCircle(Offset(size.width / 2, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(_KeyPainter old) => false;
}

class _GrowthPainter extends CustomPainter {
  final List<double> target;
  final Map<int, double> weighings;
  final int today;
  final int lastDay;
  final int? selected;
  final double reveal;
  final String kgUnit;
  final String gUnit;

  _GrowthPainter({
    required this.target,
    required this.weighings,
    required this.today,
    required this.lastDay,
    required this.selected,
    required this.reveal,
    required this.kgUnit,
    required this.gUnit,
  });

  static const _axisStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMuted,
  );

  static Rect plotRect(Size size) =>
      Rect.fromLTRB(44, 8, size.width - 8, size.height - 22);

  @override
  void paint(Canvas canvas, Size size) {
    final plot = plotRect(size);
    final visible = <double>[
      ...target.take(lastDay),
      for (final e in weighings.entries)
        if (e.key <= lastDay) e.value,
    ];
    final maxG = visible.reduce((a, b) => a > b ? a : b);
    // Grid step so there are at most 5 lines: 50 g … 1 kg.
    final step = const [
      50.0,
      100.0,
      200.0,
      250.0,
      500.0,
      1000.0,
    ].firstWhere((s) => maxG / s <= 5, orElse: () => 1000.0);
    final top = (maxG / step).ceil() * step;

    double x(int day) => plot.left + (day - 1) / (lastDay - 1) * plot.width;
    double y(double g) => plot.bottom - g / top * plot.height;

    String axis(double g) {
      if (g == 0) return '0';
      if (g < 1000) return '${g.round()} $gUnit';
      final kg = g / 1000;
      return '${kg == kg.roundToDouble() ? kg.round() : kg} $kgUnit';
    }

    // Hairline grid + y labels.
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var g = 0.0; g <= top + 0.1; g += step) {
      final gy = y(g);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), grid);
      _text(canvas, axis(g), Offset(0, gy - 7));
    }
    // X labels: day 1 and every week inside the window.
    for (final d in [1, for (var w = 7; w <= lastDay; w += 7) w]) {
      _text(canvas, '$d', Offset(x(d) - 6, plot.bottom + 6));
    }

    // "Today" marker.
    final todayX = x(today.clamp(1, lastDay));
    canvas.drawLine(
      Offset(todayX, plot.top),
      Offset(todayX, plot.bottom),
      Paint()
        ..color = AppColors.primary.withAlpha(60)
        ..strokeWidth = 1,
    );

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, plot.left + plot.width * reveal + 6, size.height),
    );

    // Target curve: 2 px dashed blue.
    final targetPath = Path()..moveTo(x(1), y(target.first));
    for (var d = 2; d <= lastDay; d++) {
      targetPath.lineTo(x(d), y(target[d - 1]));
    }
    _dashed(
      canvas,
      targetPath,
      Paint()
        ..color = AppColors.info
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Measured: 2 px green line + 8 px dots with a 2 px surface ring.
    final days = weighings.keys.where((d) => d <= lastDay).toList()..sort();
    if (days.isNotEmpty) {
      final line = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(x(days.first), y(weighings[days.first]!));
      for (final d in days.skip(1)) {
        path.lineTo(x(d), y(weighings[d]!));
      }
      canvas.drawPath(path, line);
      for (final d in days) {
        final c = Offset(x(d), y(weighings[d]!));
        canvas.drawCircle(c, 6, Paint()..color = AppColors.surface);
        canvas.drawCircle(c, 4, Paint()..color = AppColors.primary);
      }
      // Direct label on the latest weighing only.
      final last = days.last;
      final label = '${weighings[last]!.round()} $gUnit';
      final lp = Offset(x(last), y(weighings[last]!));
      _text(
        canvas,
        label,
        Offset((lp.dx - 20).clamp(plot.left, plot.right - 48), lp.dy - 22),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      );
    }
    canvas.restore();

    // Crosshair for the tapped day.
    final sel = selected;
    if (sel != null) {
      final sx = x(sel);
      canvas.drawLine(
        Offset(sx, plot.top),
        Offset(sx, plot.bottom),
        Paint()
          ..color = AppColors.ink.withAlpha(90)
          ..strokeWidth = 1,
      );
      final tc = Offset(sx, y(target[sel - 1]));
      canvas.drawCircle(tc, 6, Paint()..color = AppColors.surface);
      canvas.drawCircle(tc, 4, Paint()..color = AppColors.info);
      final w = weighings[sel];
      if (w != null) {
        final wc = Offset(sx, y(w));
        canvas.drawCircle(wc, 7, Paint()..color = AppColors.surface);
        canvas.drawCircle(wc, 5, Paint()..color = AppColors.primary);
      }
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + 6), paint);
        dist += 11;
      }
    }
  }

  void _text(Canvas canvas, String text, Offset at, {TextStyle? style}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style ?? _axisStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_GrowthPainter old) =>
      old.reveal != reveal ||
      old.selected != selected ||
      old.today != today ||
      old.lastDay != lastDay ||
      old.weighings != weighings;
}
