import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../app/config/app_strings.dart';
import '../../../app/config/arena_theme.dart';
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
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.cricket.withValues(alpha: 0.12),
                              border: Border.all(color: c.cricket.withValues(alpha: 0.35)),
                            ),
                          ).animate(onPlay: (a) => a.repeat(reverse: true)).fade(begin: 0.5, end: 1, duration: 900.ms),
                          Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [ArenaColors.lime, ArenaColors.emerald],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                  boxShadow: [BoxShadow(color: ArenaColors.emerald.withValues(alpha: 0.35), blurRadius: 20)],
                                ),
                                child: Icon(Icons.emoji_events_rounded, color: c.onAccent, size: 28),
                              )
                              .animate(onPlay: (a) => a.repeat(reverse: true))
                              .moveY(begin: 6, end: -26, duration: 550.ms, curve: Curves.easeOutQuad)
                              .scaleXY(begin: 1, end: 1.05, duration: 550.ms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(AppStrings.appTagline, textAlign: TextAlign.center, style: context.text.bodySmall),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms),
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
