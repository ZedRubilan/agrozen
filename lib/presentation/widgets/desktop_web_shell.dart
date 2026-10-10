import 'package:flutter/material.dart';

/// Clean Phone-First Web Shell:
/// - On mobile screens (width <= 500): Renders 100% full-screen native mobile UI.
/// - On wider screens (desktop / tablet): Centers the clean phone interface
///   without any clutter, external panels, or distraction ribbons outside the phone view.
class DesktopWebShell extends StatelessWidget {
  final Widget child;

  const DesktopWebShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Mobile screens: full-bleed native experience
    if (screenWidth <= 500) {
      return child;
    }

    // Wide screens: pure phone interface centered, zero external clutter
    return Scaffold(
      backgroundColor: const Color(0xFFEDF3EE),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
            maxHeight: 910,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white,
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2618).withAlpha(35),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}
