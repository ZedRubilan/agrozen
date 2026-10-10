import 'package:flutter/material.dart';

/// A Duolingo-inspired chunky tactile button that depresses with physical 3D feedback.
/// Designed specifically for easy, confident tapping by farmers with dirty or gloved hands.
class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color shadowColor;
  final double height;
  final double borderRadius;
  final double depth;

  const TactileButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor = const Color(0xFF2D7A4C),
    this.shadowColor = const Color(0xFF1B5E20),
    this.height = 54,
    this.borderRadius = 16,
    this.depth = 4,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = _isPressed ? 0.0 : widget.depth;
    final topMargin = _isPressed ? widget.depth : 0.0;

    return SizedBox(
      height: widget.height + widget.depth,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onPressed != null) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (widget.onPressed != null) {
            setState(() => _isPressed = false);
            widget.onPressed!();
          }
        },
        onTapCancel: () {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 65),
          curve: Curves.easeOutQuad,
          height: widget.height,
          margin: EdgeInsets.only(top: topMargin, bottom: effectiveDepth),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              if (effectiveDepth > 0)
                BoxShadow(
                  color: widget.shadowColor,
                  offset: Offset(0, effectiveDepth),
                  blurRadius: 0,
                ),
              BoxShadow(
                color: widget.shadowColor.withAlpha(50),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Top subtle glossy sheen
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(35),
                          Colors.white.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Center(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
