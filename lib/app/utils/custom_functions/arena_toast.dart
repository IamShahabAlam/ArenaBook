import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/arena_theme.dart';

enum ToastType { info, success, error }

/// Short top notification (the prototype's toast pill), drawn in the navigator's Overlay.
///
/// Own implementation instead of Get.snackbar: GetX keeps a static, global snackbar queue
/// (toasts pile up and can get stuck), while here a new toast simply replaces the current one.
class ArenaToast {
  ArenaToast._();

  static const displayDuration = Duration(seconds: 3);

  static OverlayEntry? _entry;
  static Timer? _timer;
  static final _visible = ValueNotifier<bool>(false);

  /// Text currently on screen (null when none). Handy for tests.
  static String? get currentMessage => _message;
  static String? _message;

  static void success(String message) => show(message, type: ToastType.success);
  static void error(String message) => show(message, type: ToastType.error);

  static void show(String message, {ToastType type = ToastType.info}) {
    final overlay = Get.key.currentState?.overlay;
    if (overlay == null) return;
    dismiss(animate: false);

    _message = message;
    _visible.value = false;
    _entry = OverlayEntry(
      builder: (_) => _ToastView(message: message, type: type, visible: _visible),
    );
    overlay.insert(_entry!);
    // Next frame: flip to visible so the entrance animates.
    WidgetsBinding.instance.addPostFrameCallback((_) => _visible.value = true);
    _timer = Timer(displayDuration, dismiss);
  }

  static void dismiss({bool animate = true}) {
    _timer?.cancel();
    _timer = null;
    _message = null;
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    if (!animate) {
      if (entry.mounted) entry.remove();
      return;
    }
    _visible.value = false;
    Timer(_ToastView.animation, () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message, required this.type, required this.visible});

  static const animation = Duration(milliseconds: 250);

  final String message;
  final ToastType type;
  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<ArenaColors>() ?? ArenaColors.dark;
    final (icon, color) = switch (type) {
      ToastType.info => (Icons.info_rounded, c.cricketText),
      ToastType.success => (Icons.check_circle_rounded, c.cricketText),
      ToastType.error => (Icons.error_rounded, c.dangerText),
    };

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 24,
      right: 24,
      // A toast informs, it must never block the header buttons underneath it.
      child: IgnorePointer(
        child: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, shown, child) => AnimatedSlide(
            offset: shown ? Offset.zero : const Offset(0, -0.4),
            duration: animation,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(opacity: shown ? 1 : 0, duration: animation, child: child),
          ),
          child: Center(
            child: Semantics(
              liveRegion: true, // screen readers announce it
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Material(
                  color: c.surface,
                  shape: StadiumBorder(side: BorderSide(color: c.border)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            message,
                            style: TextStyle(fontFamily: ArenaTheme.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
