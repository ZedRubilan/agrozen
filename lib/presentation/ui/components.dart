import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// The small set of building blocks every AgroZen screen is made from.
///
/// Rule of thumb: if a screen needs a card, a row, a metric or a warning, it
/// uses one of these — never a hand-rolled `Container(decoration: …)`.

/// Semantic colour role for badges, banners and tiles.
enum Tone { neutral, primary, warning, danger, info }

extension ToneColors on Tone {
  /// Bright fill for solid discs and buttons that carry a white icon.
  Color get solid {
    switch (this) {
      case Tone.warning:
        return AppColors.gold;
      default:
        return foreground;
    }
  }

  Color get foreground {
    switch (this) {
      case Tone.neutral:
        return AppColors.inkSecondary;
      case Tone.primary:
        return AppColors.primary;
      case Tone.warning:
        return AppColors.warning;
      case Tone.danger:
        return AppColors.danger;
      case Tone.info:
        return AppColors.info;
    }
  }

  Color get background {
    switch (this) {
      case Tone.neutral:
        return AppColors.surfaceMuted;
      case Tone.primary:
        return AppColors.primarySoft;
      case Tone.warning:
        return AppColors.warningSoft;
      case Tone.danger:
        return AppColors.dangerSoft;
      case Tone.info:
        return AppColors.infoSoft;
    }
  }
}

/// White, rounded surface that floats on a soft shadow. Tappable when
/// [onTap] is given — it then shrinks slightly while pressed.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    this.color,
    this.borderColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final tinted = widget.color != null && widget.color != AppColors.surface;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.fast,
      curve: AppMotion.curve,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: tinted ? null : AppShadow.card,
        ),
        child: Material(
          color: widget.color ?? AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: widget.borderColor == null
                ? BorderSide.none
                : BorderSide(color: widget.borderColor!, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null
                ? null
                : (v) => setState(() => _pressed = v),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Section title with an optional text action on the right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final action = actionLabel != null && onAction != null
        ? TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            ),
            child: Text(actionLabel!),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: MediaQuery.textScalerOf(context).scale(14) > 19
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.section),
                if (action != null) action,
              ],
            )
          : Row(
              children: [
                Expanded(child: Text(title, style: AppText.section)),
                if (action != null)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: action,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Rounded-square icon on a soft tone background.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    this.tone = Tone.primary,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.52, color: tone.foreground),
    );
  }
}

/// Small rounded label, e.g. "Day 14" or "Done".
class StatusPill extends StatelessWidget {
  final String label;
  final Tone tone;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    this.tone = Tone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: tone.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One number with its label, for use inside a card or grid.
class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Tone tone;
  final VoidCallback? onTap;

  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.tone = Tone.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: icon, tone: tone, size: 28),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: AppText.metric),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of [MetricTile]s (or any equal-height children).
class MetricGrid extends StatelessWidget {
  final List<Widget> children;

  const MetricGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(14) > 19) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Gap(AppSpace.sm),
            children[i],
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: AppSpace.sm));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Coloured message block for warnings, alerts and prompts.
class NoticeBanner extends StatelessWidget {
  final Tone tone;
  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const NoticeBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tone.foreground, size: 22),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.cardTitle.copyWith(color: AppColors.ink),
                    ),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        message!,
                        style: AppText.bodyMuted.copyWith(color: AppColors.ink),
                      ),
                    ],
                  ],
                ),
              ),
              if (onClose != null)
                InkResponse(
                  onTap: onClose,
                  radius: 20,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable row with an icon badge, used for menus, settings and lists.
class ListRow extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.tone = Tone.primary,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            IconBadge(icon: icon, tone: tone),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.cardTitle),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.bodyMuted),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// A card holding several [ListRow]s separated by hairlines.
class ListGroup extends StatelessWidget {
  final List<Widget> children;

  const ListGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(const Divider(indent: 68, height: 1));
      }
      items.add(children[i]);
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: items),
    );
  }
}

/// Title block at the top of a tab or screen.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.screenTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    subtitle!,
                    style: AppText.bodyMuted.copyWith(color: subtitleColor),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Scrollable page body with the standard padding, width cap and
/// pull-to-refresh.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final EdgeInsets padding;

  const PageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.screen,
      AppSpace.lg,
      AppSpace.screen,
      AppSpace.xxl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return list;
  }
}

/// Vertical gap between cards on a page.
class Gap extends StatelessWidget {
  final double size;

  const Gap([this.size = AppSpace.md, Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}

/// Centered spinner used while a page loads.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Thin rounded progress bar.
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? color;

  const AppProgressBar({super.key, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        color: color,
      ),
    );
  }
}

/// Full-width primary button with an optional icon and a busy state.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final Color? color;

  /// Put the icon after the label (e.g. a "next" arrow).
  final bool iconAtEnd;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.color,
    this.iconAtEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = color == null
        ? null
        : FilledButton.styleFrom(backgroundColor: color);
    final child = busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : Text(label);
    return SizedBox(
      width: double.infinity,
      child: icon != null && !busy
          ? FilledButton.icon(
              onPressed: onPressed,
              iconAlignment: iconAtEnd
                  ? IconAlignment.end
                  : IconAlignment.start,
              style: style,
              icon: Icon(icon),
              label: child,
            )
          : FilledButton(
              onPressed: busy ? null : onPressed,
              style: style,
              child: child,
            ),
    );
  }
}

/// Fades and lifts its child into place when the screen opens. Give each
/// section of a page a rising [index] so they arrive one after another.
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;

  const Reveal({super.key, required this.child, this.index = 0});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay = AppMotion.stagger * widget.index.clamp(0, 8);
    final total = AppMotion.enter + delay;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: AppMotion.curve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _progress.value)),
          child: child,
        ),
      ),
    );
  }
}

/// A number that counts up to [value] the first time it is shown and glides
/// to new values afterwards. [format] turns the number into the final text,
/// so the settled label is exactly what `Fmt` would print.
class CountUpText extends StatelessWidget {
  final double value;
  final String Function(double value) format;
  final TextStyle? style;

  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? value : 0, end: value),
      duration: still ? Duration.zero : AppMotion.count,
      curve: Curves.easeOutQuart,
      builder: (context, v, _) => Text(format(v), maxLines: 1, style: style),
    );
  }
}

/// Circular progress that fills up when shown, with [child] in the middle.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 9,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surfaceMuted,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = value.clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? target : 0, end: target),
        duration: still ? Duration.zero : AppMotion.count,
        curve: Curves.easeOutQuart,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(v, stroke, color, trackColor),
          child: Center(child: child),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;
  final Color track;

  _RingPainter(this.value, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -1.5708,
        6.2832 * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Frosted pill used on top of photos (location, phase, round buttons).
class GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? tooltip;

  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill = Material(
      color: Colors.white.withAlpha(46),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withAlpha(70))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 18),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) pill = Tooltip(message: tooltip!, child: pill);
    return pill;
  }
}

/// Rounded photo card with the deep green shade on top, for white content
/// (course progress, batch summary). Falls back to plain green offline.
class PhotoCard extends StatelessWidget {
  final String image;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Alignment imageAlignment;

  const PhotoCard({
    super.key,
    required this.image,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.imageAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadow.raised,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.primaryDark),
            ),
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                alignment: imageAlignment,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.heroShade.withAlpha(120),
                      AppColors.heroShade.withAlpha(225),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// One target number (temperature, feed, water, weight…) as a tappable tile:
/// small semantic icon beside the label, the value, a supporting caption.
/// The [hero] tile is tinted soft amber — use at most one per screen
/// (brooding temperature matters most).
class TargetTile extends StatelessWidget {
  final bool hero;
  final IconData icon;
  final Tone tone;
  final String label;
  final double value;
  final String Function(double) format;
  final String caption;
  final VoidCallback? onTap;

  const TargetTile({
    super.key,
    this.hero = false,
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    required this.format,
    required this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: hero ? AppColors.warningSoft : null,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tone.foreground),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppText.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpace.sm),
          Text(format(value), style: AppText.metric),
          if (caption.isNotEmpty) ...[
            const Gap(AppSpace.xs),
            Text(caption, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

/// The card under a tab's [PageHeader]: where things stand right now, with a
/// small farm photo, an optional progress line and an optional action.
class SummaryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String image;
  final double? progress;
  final Widget? action;

  const SummaryCard({
    super.key,
    required this.title,
    required this.image,
    this.subtitle,
    this.progress,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.metric),
                    if (subtitle != null) ...[
                      const Gap(AppSpace.xs),
                      Text(subtitle!, style: AppText.bodyMuted),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: ColoredBox(color: AppColors.primarySoft),
                  ),
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const Gap(AppSpace.md),
            AppProgressBar(value: progress!, color: AppColors.primary),
          ],
          if (action != null) ...[const Gap(AppSpace.lg), action!],
        ],
      ),
    );
  }
}

/// One-off celebration: coloured confetti falls once (≈1.6 s) and is gone.
/// Ignores touches; renders nothing with "reduce motion" on.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  // Created up front: a lazy controller would first be built in dispose()
  // when reduce-motion skipped it, which is illegal there.
  late final AnimationController _c;
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_still && !_c.isAnimating && !_c.isCompleted) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(_c),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> t;

  _ConfettiPainter(this.t) : super(repaint: t);

  static const _colors = [
    AppColors.primary,
    AppColors.gold,
    AppColors.sun,
    AppColors.info,
    AppColors.danger,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0 || v >= 1) return;
    final fade = v < 0.75 ? 1.0 : (1 - v) / 0.25;
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      // Deterministic per-piece randomness.
      final a = ((i * 73) % 100) / 100;
      final b = ((i * 37 + 11) % 100) / 100;
      final c = ((i * 53 + 29) % 100) / 100;
      final x0 = size.width * (0.5 + (a - 0.5) * 0.3);
      final vx = (b - 0.5) * size.width * 1.1;
      final vy = -size.height * (0.55 + c * 0.45);
      final g = size.height * 1.9;
      final x = x0 + vx * v;
      final y = size.height * 0.45 + vy * v + 0.5 * g * v * v;
      paint.color = _colors[i % _colors.length].withAlpha((255 * fade).round());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((a * 6 + v * 10 * (b - 0.5)) * 3.1416);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 4.5),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

/// Secondary information stays discoverable without dominating the page.
/// Text grows naturally; the entire labelled header is a touch target.
class DetailSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Tone tone;
  final List<Widget> children;
  const DetailSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.tone = Tone.primary,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xs,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        AppSpace.md,
      ),
      leading: IconBadge(icon: icon, tone: tone),
      title: Text(title, style: AppText.cardTitle),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppText.bodyMuted),
      expansionAnimationStyle: AnimationStyle(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.medium,
        curve: AppMotion.curve,
      ),
      children: children,
    ),
  );
}
