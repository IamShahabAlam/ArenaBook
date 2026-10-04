import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared, subtle motion. Everything here is skipped when the user turned on
/// "Remove animations" in the phone's accessibility settings.
extension ReduceMotion on BuildContext {
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// [normal], or zero when animations are disabled.
  Duration motion(Duration normal) => reduceMotion ? Duration.zero : normal;
}

extension ArenaMotion on Widget {
  /// Fade in with a small rise, played once when the widget first appears.
  /// [index] staggers items in a list (capped so long lists don't wait).
  Widget entrance(BuildContext context, {int index = 0, Duration delay = Duration.zero}) {
    if (context.reduceMotion) return this;
    return animate(
      delay: delay + (45 * index.clamp(0, 8)).ms,
    ).fadeIn(duration: 260.ms, curve: Curves.easeOut).slideY(begin: 0.06, end: 0, duration: 260.ms, curve: Curves.easeOutCubic);
  }

  /// Small "pop" for icons and tiles: scale up from 85% with a soft overshoot.
  Widget popIn(BuildContext context, {Duration delay = Duration.zero}) {
    if (context.reduceMotion) return this;
    return animate(delay: delay).fadeIn(duration: 220.ms).scaleXY(begin: 0.85, end: 1, duration: 420.ms, curve: Curves.easeOutBack);
  }
}

/// A number that counts to its new value instead of jumping, e.g. "Pending Dues" after Mark Paid.
/// The first build shows the value directly; only later changes animate.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({super.key, required this.value, required this.format, this.style});

  final int value;
  final String Function(int value) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: context.motion(const Duration(milliseconds: 450)),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v.round()), style: style),
    );
  }
}

/// Fades a tab in when it becomes the visible one (used inside the shell's IndexedStack,
/// which keeps every tab alive, so state and scroll position are preserved).
class TabFade extends StatelessWidget {
  const TabFade({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = context.motion(const Duration(milliseconds: 220));
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(offset: active ? Offset.zero : const Offset(0, 0.015), duration: duration, curve: Curves.easeOutCubic, child: child),
    );
  }
}
