import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';

/// Animated, illustrated sky for the current weather: sun or moon and stars,
/// drifting clouds, rain, snow, lightning or fog over the hills and a poultry
/// house (its windows glow at night).
///
/// Everything is drawn, so it works offline and costs no image assets. One
/// 40 s loop drives all motion; every movement completes whole cycles in that
/// time so the loop is seamless. With "reduce motion" on it is a still picture,
/// and it stops ticking when its tab is hidden ([TickerMode]).
class WeatherScene extends StatefulWidget {
  final WeatherSky sky;
  final bool isDay;

  /// Outside temperature, °C — warms or cools the clear-sky colours.
  final double temperature;

  const WeatherScene({
    super.key,
    required this.sky,
    required this.isDay,
    required this.temperature,
  });

  @override
  State<WeatherScene> createState() => _WeatherSceneState();
}

class _WeatherSceneState extends State<WeatherScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _clock
        ..stop()
        ..value = 0.27; // a pleasant frame: clouds spread, rain mid-fall
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ScenePainter(
          clock: _clock,
          sky: widget.sky,
          isDay: widget.isDay,
          temperature: widget.temperature,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Sky colours (top → horizon) for a sky, time of day and temperature.
List<Color> weatherSkyColors(WeatherSky sky, bool isDay, double temperature) {
  if (!isDay) {
    switch (sky) {
      case WeatherSky.clear:
      case WeatherSky.partlyCloudy:
        return const [Color(0xFF0B1026), Color(0xFF2B3A67)];
      case WeatherSky.storm:
        return const [Color(0xFF0A0A1F), Color(0xFF2A2D45)];
      case WeatherSky.rain:
        return const [Color(0xFF0F172A), Color(0xFF334155)];
      default:
        return const [Color(0xFF1E2433), Color(0xFF3B4357)];
    }
  }
  switch (sky) {
    case WeatherSky.clear:
      if (temperature >= 30) {
        return const [Color(0xFFF97316), Color(0xFFFDE68A)];
      }
      if (temperature <= 5) {
        return const [Color(0xFF3B82F6), Color(0xFFDBEAFE)];
      }
      return const [Color(0xFF2F80ED), Color(0xFF9FD3F7)];
    case WeatherSky.partlyCloudy:
      return const [Color(0xFF4A8FD9), Color(0xFFBBDCF2)];
    case WeatherSky.overcast:
      return const [Color(0xFF5E6E85), Color(0xFFB8C4D3)];
    case WeatherSky.fog:
      return const [Color(0xFF7D8DA3), Color(0xFFD5DCE5)];
    case WeatherSky.rain:
      return const [Color(0xFF334155), Color(0xFF6B7A90)];
    case WeatherSky.snow:
      return const [Color(0xFF7586A0), Color(0xFFDDE5EF)];
    case WeatherSky.storm:
      return const [Color(0xFF1E1B4B), Color(0xFF4B5563)];
  }
}

class _ScenePainter extends CustomPainter {
  final Animation<double> clock;
  final WeatherSky sky;
  final bool isDay;
  final double temperature;

  _ScenePainter({
    required this.clock,
    required this.sky,
    required this.isDay,
    required this.temperature,
  }) : super(repaint: clock);

  static const double _tau = math.pi * 2;

  // Fixed pseudo-random layouts, so particles never jump between frames.
  static final List<List<double>> _stars = _seeded(26, 11);
  static final List<List<double>> _drops = _seeded(70, 23);
  static final List<List<double>> _flakes = _seeded(48, 37);

  static List<List<double>> _seeded(int n, int seed) {
    final r = math.Random(seed);
    return List.generate(
      n,
      (_) => [r.nextDouble(), r.nextDouble(), r.nextDouble()],
    );
  }

  bool get _sunVisible =>
      sky == WeatherSky.clear || sky == WeatherSky.partlyCloudy;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final rect = Offset.zero & size;

    // 1. Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: weatherSkyColors(sky, isDay, temperature),
        ).createShader(rect),
    );

    // 2. Stars on clear / partly cloudy nights.
    if (!isDay && _sunVisible) _paintStars(canvas, size, t);

    // 3. Sun or moon.
    if (_sunVisible) {
      isDay ? _paintSun(canvas, size, t) : _paintMoon(canvas, size, t);
    }

    // 4. Clouds.
    switch (sky) {
      case WeatherSky.clear:
        break;
      case WeatherSky.partlyCloudy:
        _paintClouds(canvas, size, t, count: 3, dark: false);
      case WeatherSky.overcast:
      case WeatherSky.fog:
        _paintClouds(canvas, size, t, count: 5, dark: false);
      case WeatherSky.rain:
      case WeatherSky.snow:
        _paintClouds(canvas, size, t, count: 5, dark: sky == WeatherSky.rain);
      case WeatherSky.storm:
        _paintClouds(canvas, size, t, count: 6, dark: true);
    }

    // 5. Lightning flash behind the rain.
    if (sky == WeatherSky.storm) _paintLightning(canvas, size, t);

    // 6. Ground: hills and the poultry house.
    _paintGround(canvas, size);

    // 7. Precipitation and fog in front of everything.
    if (sky == WeatherSky.rain || sky == WeatherSky.storm) {
      _paintRain(canvas, size, t, heavy: sky == WeatherSky.storm);
    }
    if (sky == WeatherSky.snow) _paintSnow(canvas, size, t);
    if (sky == WeatherSky.fog) _paintFog(canvas, size, t);
  }

  void _paintStars(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white;
    for (final s in _stars) {
      final twinkle =
          0.45 + 0.55 * (0.5 + 0.5 * math.sin(_tau * (t * 8 + s[2])));
      paint.color = Colors.white.withAlpha((200 * twinkle).round());
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height * 0.62),
        0.8 + s[2] * 1.2,
        paint,
      );
    }
  }

  void _paintSun(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.8, size.height * 0.3);
    final hot = temperature >= 30;
    final r = hot ? 30.0 : 26.0;
    final pulse = 0.5 + 0.5 * math.sin(_tau * t * 10);

    // Glow.
    canvas.drawCircle(
      c,
      r * (2.3 + 0.25 * pulse),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF3B0).withAlpha(hot ? 170 : 130),
            const Color(0x00FFF3B0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.6)),
    );

    // Rays: 12 rays turn one ray-gap (30°) per loop, so the loop is seamless.
    final rays = Paint()
      ..color = const Color(0xFFFFE08A).withAlpha(210)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final turn = t * _tau / 12;
    for (var i = 0; i < 12; i++) {
      final a = turn + i * _tau / 12;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * (r + 7), c + dir * (r + 15 + 3 * pulse), rays);
    }

    // Disc.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFF7CC), Color(0xFFFFC93C)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _paintMoon(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.8, size.height * 0.28);
    const r = 20.0;
    canvas.drawCircle(
      c,
      r * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFFE8EEFF,
            ).withAlpha(60 + (30 * math.sin(_tau * t * 4)).round()),
            const Color(0x00E8EEFF),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.4)),
    );
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()
        ..addOval(Rect.fromCircle(center: c + const Offset(9, -6), radius: r)),
    );
    canvas.drawPath(moon, Paint()..color = const Color(0xFFF5F3E7));
  }

  /// A puffy cloud made of overlapping circles; [w] is its width.
  void _cloud(Canvas canvas, Offset at, double w, Paint paint) {
    final h = w * 0.36;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(at.dx, at.dy + h * 0.55, w, h * 0.45),
          Radius.circular(h * 0.25),
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: at + Offset(w * 0.22, h * 0.62),
          radius: h * 0.36,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: at + Offset(w * 0.45, h * 0.42),
          radius: h * 0.5,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: at + Offset(w * 0.7, h * 0.5),
          radius: h * 0.42,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: at + Offset(w * 0.86, h * 0.7),
          radius: h * 0.3,
        ),
      );
    // One path, so translucent clouds don't show darker overlaps.
    path.fillType = PathFillType.nonZero;
    canvas.drawPath(path, paint);
  }

  void _paintClouds(
    Canvas canvas,
    Size size,
    double t, {
    required int count,
    required bool dark,
  }) {
    final Color tint;
    if (dark) {
      tint = isDay ? const Color(0xFF475569) : const Color(0xFF1F2937);
    } else {
      tint = isDay ? Colors.white : const Color(0xFF64748B);
    }
    for (var i = 0; i < count; i++) {
      // Back clouds are smaller, slower and fainter: depth.
      final depth = i / math.max(1, count - 1);
      final w = size.width * (0.28 + 0.2 * depth);
      final laps = i.isEven ? 1 : 2; // whole laps per loop → seamless
      final seed = (i * 0.37) % 1;
      final span = size.width + w * 2;
      final x = ((seed + t * laps) % 1) * span - w;
      final y = size.height * (0.06 + 0.34 * ((i * 0.53) % 1));
      final alpha = dark ? 235 : (isDay ? 150 + (80 * depth).round() : 170);
      _cloud(canvas, Offset(x, y), w, Paint()..color = tint.withAlpha(alpha));
    }
  }

  void _paintLightning(Canvas canvas, Size size, double t) {
    // Two strikes per loop (every 20 s), each a quick double flicker.
    final phase = (t * 2) % 1;
    double flash = 0;
    if (phase < 0.012) flash = 1;
    if (phase > 0.02 && phase < 0.028) flash = 0.7;
    if (flash == 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withAlpha((90 * flash).round()),
    );
    final x0 = size.width * (t < 0.5 ? 0.32 : 0.6);
    final bolt = Path()
      ..moveTo(x0, size.height * 0.22)
      ..lineTo(x0 - 10, size.height * 0.42)
      ..lineTo(x0 + 4, size.height * 0.42)
      ..lineTo(x0 - 8, size.height * 0.66);
    canvas.drawPath(
      bolt,
      Paint()
        ..color = const Color(0xFFFFF7AE).withAlpha((255 * flash).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintGround(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final snowy = sky == WeatherSky.snow;

    final Color far;
    final Color near;
    if (snowy) {
      far = isDay ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8);
      near = isDay ? const Color(0xFFF8FAFC) : const Color(0xFFCBD5E1);
    } else if (isDay) {
      far = const Color(0xFF3F8F4F);
      near = const Color(0xFF256B37);
    } else {
      far = const Color(0xFF173528);
      near = const Color(0xFF0E2419);
    }

    final farHill = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.3, h * 0.62, w * 0.62, h * 0.76)
      ..quadraticBezierTo(w * 0.85, h * 0.86, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(farHill, Paint()..color = far);

    final nearHill = Path()
      ..moveTo(0, h * 0.9)
      ..quadraticBezierTo(w * 0.45, h * 0.78, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(nearHill, Paint()..color = near);

    // Poultry house: long low building with a gable roof and vents.
    final bx = w * 0.56; // right side: the temperature sits bottom-left
    final by = h * 0.77;
    final bw = w * 0.34;
    final bh = h * 0.1;
    final wall = Paint()
      ..color = snowy
          ? (isDay ? const Color(0xFF8B6B4A) : const Color(0xFF4B3A2A))
          : (isDay ? const Color(0xFFF1EDE4) : const Color(0xFF2B2F36));
    final roof = Paint()
      ..color = snowy
          ? (isDay ? Colors.white : const Color(0xFFCBD5E1))
          : (isDay ? const Color(0xFFB4532A) : const Color(0xFF1B1E24));
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), wall);
    canvas.drawPath(
      Path()
        ..moveTo(bx - 5, by + 1)
        ..lineTo(bx + bw * 0.08, by - bh * 0.55)
        ..lineTo(bx + bw * 0.92, by - bh * 0.55)
        ..lineTo(bx + bw + 5, by + 1)
        ..close(),
      roof,
    );
    // Windows: dark by day, warm light at night.
    final windowPaint = Paint()
      ..color = isDay ? const Color(0xFF5B6B60) : const Color(0xFFFFC857);
    for (var i = 0; i < 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bx + bw * (0.1 + i * 0.17),
            by + bh * 0.3,
            bw * 0.09,
            bh * 0.32,
          ),
          const Radius.circular(1.5),
        ),
        windowPaint,
      );
    }
    if (!isDay) {
      // Soft glow spilling from the windows.
      canvas.drawRect(
        Rect.fromLTWH(bx, by + bh * 0.1, bw, bh * 0.7),
        Paint()
          ..color = const Color(0x33FFC857)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _paintRain(Canvas canvas, Size size, double t, {required bool heavy}) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(isDay ? 150 : 110)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final n = heavy ? _drops.length : (_drops.length * 0.7).round();
    for (var i = 0; i < n; i++) {
      final d = _drops[i];
      final laps = 36 + (d[2] * 8).floor(); // whole laps per loop
      final y = ((d[1] + t * laps) % 1) * (size.height + 30) - 20;
      final x = d[0] * (size.width + 30) - 0.18 * y;
      final len = 10 + 8 * d[2];
      canvas.drawLine(Offset(x, y), Offset(x - len * 0.2, y + len), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white.withAlpha(230);
    for (final f in _flakes) {
      final laps = 5 + (f[2] * 4).floor();
      final y = ((f[1] + t * laps) % 1) * (size.height + 12) - 6;
      final sway = 9 * math.sin(_tau * (t * 6 + f[0]));
      canvas.drawCircle(
        Offset(f[0] * size.width + sway, y),
        1.4 + 2.2 * f[2],
        paint,
      );
    }
  }

  void _paintFog(Canvas canvas, Size size, double t) {
    // Overall haze that thickens towards the ground…
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withAlpha(isDay ? 30 : 10),
            Colors.white.withAlpha(isDay ? 150 : 70),
          ],
        ).createShader(rect),
    );
    // …and slow drifting bands.
    final paint = Paint()
      ..color = Colors.white.withAlpha(isDay ? 170 : 80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.3 + i * 0.13);
      final dir = i.isEven ? 1 : -1;
      final x = size.width * 0.22 * math.sin(_tau * (t + i * 0.2)) * dir;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - size.width * 0.25, y, size.width * 0.9, 26),
          const Radius.circular(13),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + size.width * 0.75, y + 8, size.width * 0.7, 22),
          const Radius.circular(11),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.sky != sky || old.isDay != isDay || old.temperature != temperature;
}
