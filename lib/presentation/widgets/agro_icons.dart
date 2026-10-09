import 'package:flutter/material.dart';

/// Custom-crafted friendly vector icons and cartoonish badges for AgroZen.
/// Eliminates raw emojis in favor of crisp, harmonious vector graphics that match
/// the soft, organic Duolingo-style visual identity.

/// A friendly, rounded cartoon chick icon.
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
        border: Border.all(color: fg.withAlpha(80), width: 1.5),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _ChickPainter(color: fg),
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

/// A friendly plant / sprout vector icon.
class AgroSproutIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const AgroSproutIcon({
    super.key,
    this.size = 28,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? const Color(0xFF2D7A4C);
    final bg = backgroundColor ?? const Color(0xFFEAF5ED);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withAlpha(70), width: 1.5),
      ),
      child: Center(
        child: Icon(Icons.eco_rounded, size: size * 0.58, color: fg),
      ),
    );
  }
}

/// A friendly vector badge representing national flags (UZ, RU, EN)
/// cleanly without ugly OS-dependent emoji flags.
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildFlagContent(),
    );
  }

  Widget _buildFlagContent() {
    switch (code.toLowerCase()) {
      case 'uz':
        return Column(
          children: [
            Expanded(child: Container(color: const Color(0xFF1EB53A))),
            Container(height: 1.5, color: const Color(0xFFCE1126)),
            Expanded(child: Container(color: Colors.white)),
            Container(height: 1.5, color: const Color(0xFFCE1126)),
            Expanded(child: Container(color: const Color(0xFF0099B5))),
          ],
        );
      case 'ru':
        return Column(
          children: [
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: const Color(0xFF0039A6))),
            Expanded(child: Container(color: const Color(0xFFD52B1E))),
          ],
        );
      case 'en':
      default:
        return Container(
          color: const Color(0xFF012169),
          child: Center(
            child: Text(
              'EN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.42,
              ),
            ),
          ),
        );
    }
  }
}

/// A friendly vector badge for status indicators.
class AgroStatusBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;

  const AgroStatusBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
