import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../ui/components.dart';

/// Shared layout for every onboarding step: animated step bar, an icon disc
/// beside the title, content that slides in, and one primary button pinned to
/// the bottom.
class OnboardingScaffold extends StatelessWidget {
  static const int totalSteps = 4;

  /// 1-based step number; null hides the step counter (e.g. when editing).
  final int? step;
  final String title;
  final String? subtitle;
  final Widget? header;

  /// Picture beside the title (none on the language step, which has a photo).
  final IconData? icon;
  final Color accent;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final bool busy;

  const OnboardingScaffold({
    super.key,
    this.step,
    required this.title,
    this.subtitle,
    this.header,
    this.icon,
    this.accent = AppColors.primary,
    required this.children,
    required this.buttonLabel,
    required this.onNext,
    this.onBack,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    var i = 0;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: AppSpace.md),
                    if (step != null) ...[
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _StepBar(step: step!, total: totalSteps),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Text('$step / $totalSteps', style: AppText.label),
                      const SizedBox(width: AppSpace.md),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageBody(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.sm,
                  AppSpace.screen,
                  AppSpace.xl,
                ),
                children: [
                  if (header != null) ...[
                    reveal(header!),
                    const Gap(AppSpace.xl),
                  ],
                  reveal(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent,
                                  Color.lerp(accent, Colors.black, 0.2)!,
                                ],
                              ),
                              boxShadow: AppShadow.glow(accent),
                            ),
                            child: Icon(icon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: AppSpace.md),
                        ],
                        Expanded(
                          child: Text(title, style: AppText.screenTitle),
                        ),
                      ],
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    reveal(Text(subtitle!, style: AppText.bodyMuted)),
                  ],
                  const Gap(AppSpace.xl),
                  ...children.map(reveal),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                boxShadow: AppShadow.raised,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.md,
                  AppSpace.screen,
                  AppSpace.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: PrimaryButton(
                      label: buttonLabel,
                      icon: busy ? null : Icons.arrow_forward_rounded,
                      iconAtEnd: true,
                      busy: busy,
                      onPressed: onNext,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four rounded segments; done ones are green and the current one fills in.
class _StepBar extends StatelessWidget {
  final int step;
  final int total;

  const _StepBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.border),
                    if (i <= step)
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: i == step && !still ? 0 : 1,
                          end: 1,
                        ),
                        duration: AppMotion.enter,
                        curve: AppMotion.curve,
                        builder: (context, v, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: v,
                          child: const ColoredBox(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Selectable option card used in onboarding lists.
class OptionCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        color: selected ? AppColors.primarySoft : null,
        borderColor: selected ? AppColors.primary : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.cardTitle),
                  if (subtitle != null) Text(subtitle!, style: AppText.caption),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.medium,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded,
                key: ValueKey(selected),
                size: 26,
                color: selected ? AppColors.primary : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
