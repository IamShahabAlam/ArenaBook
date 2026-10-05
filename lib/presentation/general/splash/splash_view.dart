import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../app/config/app_strings.dart';
import '../../../app/config/arena_theme.dart';
import '../../../app/utils/custom_widgets/arena_logo.dart';
import '../../arena/widgets/motion.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    const total = Duration(milliseconds: AppStrings.splashTime);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: controller.skip,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right_rounded, size: 16),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.border),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _OrbitingLogo(),
                    const SizedBox(height: 28),
                    Text.rich(
                      TextSpan(
                        text: 'ARENA',
                        children: [
                          TextSpan(
                            text: 'BOOK',
                            style: TextStyle(color: c.cricketText),
                          ),
                        ],
                      ),
                      style: context.text.headlineSmall?.copyWith(fontSize: 28, letterSpacing: 0.5),
                    ).entrance(context, delay: 250.ms),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(AppStrings.appTagline, textAlign: TextAlign.center, style: context.text.bodySmall),
                    ).entrance(context, delay: 400.ms),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        height: 6,
                        color: c.surfaceMuted,
                        alignment: Alignment.centerLeft,
                        child: Container(height: 6, decoration: const BoxDecoration(gradient: ArenaColors.ctaGradient)).animate().custom(
                          duration: total,
                          builder: (context, value, child) => FractionallySizedBox(widthFactor: value, child: child),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LOADING ARENABOOK ${AppStrings.kappVersionWithDate.toUpperCase()}',
                      style: context.text.labelSmall?.copyWith(color: c.textMuted, letterSpacing: 1.6, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stadium logo on the gradient disc, with a floodlight-like arc orbiting around it.
class _OrbitingLogo extends StatelessWidget {
  const _OrbitingLogo();

  static const _size = 136.0;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final still = context.reduceMotion;

    // Soft emerald halo (same background avatar as before).
    Widget halo = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.cricket.withValues(alpha: 0.12),
        border: Border.all(color: c.cricket.withValues(alpha: 0.35)),
      ),
    );

    // Gradient disc with the logo (same avatar as before, logo instead of the trophy).
    Widget disc = Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [ArenaColors.lime, ArenaColors.emerald], begin: Alignment.topRight, end: Alignment.bottomLeft),
        boxShadow: [BoxShadow(color: ArenaColors.emerald.withValues(alpha: 0.35), blurRadius: 22)],
      ),
      alignment: Alignment.center,
      child: ArenaLogo(size: 54, color: c.onAccent), // wide mark: needs a bigger box to look balanced in the round disc
    );

    Widget orbit = CustomPaint(
      size: const Size.square(_size - 16),
      painter: _OrbitPainter(track: c.border, head: ArenaColors.lime),
    );

    Widget dashes = CustomPaint(
      size: const Size.square(_size),
      painter: _DashedRingPainter(color: c.cricket.withValues(alpha: 0.28)),
    );

    if (!still) {
      halo = halo.animate(onPlay: (a) => a.repeat(reverse: true)).fade(begin: 0.55, end: 1, duration: 1400.ms, curve: Curves.easeInOut);
      disc = disc.popIn(context).animate(onPlay: (a) => a.repeat(reverse: true)).scaleXY(begin: 1, end: 1.04, duration: 1400.ms, curve: Curves.easeInOut);
      orbit = orbit.animate().fadeIn(duration: 400.ms).animate(onPlay: (a) => a.repeat()).rotate(duration: 1600.ms);
      dashes = dashes.animate(onPlay: (a) => a.repeat()).rotate(begin: 0, end: -1, duration: const Duration(seconds: 12));
    }

    return SizedBox.square(
      dimension: _size,
      child: Stack(alignment: Alignment.center, children: [dashes, orbit, halo, disc]),
    );
  }
}

/// Faint full track plus a ~120° arc that fades in from its tail to a bright head dot.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.track, required this.head});

  final Color track;
  final Color head;

  static const _sweep = math.pi * 2 / 3;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke);
    final center = rect.center;
    final radius = arcRect.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track.withValues(alpha: 0.6),
    );

    // Arc runs from -sweep to 0 (angle 0 = 3 o'clock); the gradient brightens towards its head.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [ArenaColors.emerald.withValues(alpha: 0), ArenaColors.emerald, head],
        stops: const [1 - _sweep / (math.pi * 2), 1 - _sweep / (math.pi * 4), 1.0],
      ).createShader(arcRect);
    canvas.drawArc(arcRect, -_sweep, _sweep, false, arcPaint);

    // Glowing head
    final headPos = center + Offset(radius, 0);
    canvas.drawCircle(headPos, 6, Paint()..color = head.withValues(alpha: 0.25));
    canvas.drawCircle(headPos, 3.2, Paint()..color = head);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.track != track || old.head != head;
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashes = 36;
    const gap = 0.45; // fraction of each segment left empty
    final rect = (Offset.zero & size).deflate(1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    const segment = math.pi * 2 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * segment, segment * (1 - gap), false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}
