import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Custom-crafted friendly vector icons and cartoonish badges for AgroZen.
/// Eliminates raw emojis in favor of crisp, harmonious vector graphics that match
/// the soft, organic Duolingo-style visual identity.

/// The natural, rounded photographic AgroZen logo badge (`assets/images/agrozen_logo.png`).
class AgroChickIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const AgroChickIcon({
    super.key,
    this.size = 28,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? const Color(0xFFE5A338);
    final bg = backgroundColor ?? const Color(0xFFFFF7E6);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withAlpha(110), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: Image.asset(
          'assets/images/agrozen_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: CustomPaint(
              size: Size(size * 0.65, size * 0.65),
              painter: _ChickPainter(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChickPainter extends CustomPainter {
  final Color color;
  _ChickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final beakPaint = Paint()
      ..color = const Color(0xFFC84B31)
      ..style = PaintingStyle.fill;

    // Body: rounded plump oval
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.48, size.height * 0.58),
      width: size.width * 0.72,
      height: size.height * 0.62,
    );
    canvas.drawOval(bodyRect, paint);

    // Head: rounded circle
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.32),
      size.width * 0.3,
      paint,
    );

    // Beak: tiny cute orange triangle
    final beakPath = Path()
      ..moveTo(size.width * 0.72, size.height * 0.32)
      ..lineTo(size.width * 0.94, size.height * 0.36)
      ..lineTo(size.width * 0.72, size.height * 0.42)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Eye: friendly dark dot with white glint
    final eyePaint = Paint()..color = const Color(0xFF2E2E2E);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.28), size.width * 0.05, eyePaint);
    final glintPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.54, size.height * 0.26), size.width * 0.02, glintPaint);

    // Wing: subtle soft curved accent
    final wingPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.62),
        width: size.width * 0.32,
        height: size.height * 0.24,
      ),
      wingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChickPainter oldDelegate) => oldDelegate.color != color;
}

/// A crisp, uncropped 4:3 rounded-rectangle vector flag badge for UZ, RU, and EN.
/// Uses custom canvas painting with safe inset margins so flag stripes, crescents,
/// and crosses are never cut off by circular clipping.
class AgroFlagBadge extends StatelessWidget {
  final String code; // 'uz', 'ru', 'en'
  final double size;

  const AgroFlagBadge({
    super.key,
    required this.code,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final width = (size * 1.32).roundToDouble();
    final height = size;
    final radius = (size * 0.28).clamp(6.0, 14.0);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFDCE6DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((radius - 1.5).clamp(4.0, 12.0)),
        child: CustomPaint(
          size: Size(width - 3, height - 3),
          painter: _NationalFlagPainter(code: code.toLowerCase()),
        ),
      ),
    );
  }
}

class _NationalFlagPainter extends CustomPainter {
  final String code;

  const _NationalFlagPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    if (code == 'uz') {
      // Uzbekistan Flag: Sky Blue top, Red line, White middle, Red line, Green bottom
      final bluePaint = Paint()..color = const Color(0xFF0099B5);
      final redPaint = Paint()..color = const Color(0xFFCE1126);
      final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
      final greenPaint = Paint()..color = const Color(0xFF1EB53A);

      canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.31), bluePaint);
      canvas.drawRect(Rect.fromLTWH(0, h * 0.31, w, h * 0.04), redPaint);
      canvas.drawRect(Rect.fromLTWH(0, h * 0.35, w, h * 0.30), whitePaint);
      canvas.drawRect(Rect.fromLTWH(0, h * 0.65, w, h * 0.04), redPaint);
      canvas.drawRect(Rect.fromLTWH(0, h * 0.69, w, h * 0.31), greenPaint);

      // White crescent in safe inset on the top-left blue band
      final cx = w * 0.22;
      final cy = h * 0.155;
      final rOuter = h * 0.095;
      canvas.drawCircle(Offset(cx, cy), rOuter, whitePaint);
      canvas.drawCircle(
        Offset(cx + rOuter * 0.38, cy),
        rOuter * 0.82,
        bluePaint,
      );

      // Subtle star dots to the right of the crescent
      final dotRadius = (h * 0.022).clamp(0.8, 2.2);
      for (int row = 0; row < 2; row++) {
        for (int col = 0; col < 3; col++) {
          canvas.drawCircle(
            Offset(w * (0.36 + col * 0.065), h * (0.11 + row * 0.09)),
            dotRadius,
            whitePaint,
          );
        }
      }
    } else if (code == 'ru') {
      // Russian Flag: White top, Royal Blue middle, Crimson Red bottom
      final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
      final bluePaint = Paint()..color = const Color(0xFF0039A6);
      final redPaint = Paint()..color = const Color(0xFFD52B1E);

      canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 3), whitePaint);
      canvas.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3), bluePaint);
      canvas.drawRect(Rect.fromLTWH(0, (h * 2) / 3, w, h / 3), redPaint);
    } else {
      // English (UK Union Jack): Deep Navy field with white & red saltires and central cross
      final navyPaint = Paint()..color = const Color(0xFF012169);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), navyPaint);

      final whiteDiag = Paint()
        ..color = Colors.white
        ..strokeWidth = h * 0.22
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset.zero, Offset(w, h), whiteDiag);
      canvas.drawLine(Offset(w, 0), Offset(0, h), whiteDiag);

      final redDiag = Paint()
        ..color = const Color(0xFFC8102E)
        ..strokeWidth = h * 0.09
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset.zero, Offset(w, h), redDiag);
      canvas.drawLine(Offset(w, 0), Offset(0, h), redDiag);

      final whiteCross = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.38, 0, w * 0.24, h),
        whiteCross,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.34, w, h * 0.32),
        whiteCross,
      );

      final redCross = Paint()..color = const Color(0xFFC8102E);
      canvas.drawRect(
        Rect.fromLTWH(w * 0.43, 0, w * 0.14, h),
        redCross,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.40, w, h * 0.20),
        redCross,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NationalFlagPainter oldDelegate) =>
      oldDelegate.code != code;
}

/// Payme-inspired animated progress dots indicator for multi-step onboarding.
class AgroProgressDots extends StatelessWidget {
  final int currentStep; // 0-indexed (0..totalSteps-1)
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onDotTapped;

  const AgroProgressDots({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.border,
    this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isPassed = index < currentStep;
        return GestureDetector(
          onTap: onDotTapped != null ? () => onDotTapped!(index) : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isActive ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor
                    : (isPassed ? activeColor.withAlpha(110) : inactiveColor),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        );
      }),
    );
  }
}
