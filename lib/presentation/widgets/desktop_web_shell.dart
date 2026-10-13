import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Clean Phone-First Web Shell:
/// - On mobile screens (width <= 500): Renders 100% full-screen native mobile UI.
/// - On wider screens (desktop / tablet): Centers the clean phone interface
///   without any clutter, external panels, or distraction ribbons outside the phone view.
class DesktopWebShell extends StatelessWidget {
  final Widget child;

  const DesktopWebShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile or short screens: full-bleed native experience
        if (constraints.maxWidth <= 600 || constraints.maxHeight <= 700) {
          return child;
        }

        // Wide & tall screens: pure phone interface centered, zero external clutter
        return Scaffold(
          backgroundColor: AppColors.surfaceMuted,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
                maxHeight: 910,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withAlpha(25),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
