import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../widgets/arena_widgets.dart';

/// Base dialog frame: title row with close button, scrollable body, actions.
class ArenaDialog extends StatelessWidget {
  const ArenaDialog({super.key, required this.title, required this.icon, required this.child, this.iconColor, this.titleColor, this.actions = const []});

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final Widget child;
  final List<Widget> actions;

  static Future<T?> show<T>(Widget dialog) {
    final context = Get.context;
    if (context == null) return Future.value();
    return showDialog<T>(context: context, builder: (_) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor ?? c.cricketText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: context.text.titleMedium?.copyWith(color: titleColor)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(backgroundColor: c.surfaceMuted),
                    icon: Icon(Icons.close_rounded, size: 18, color: c.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(color: c.border),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: actions[i])],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yes/No confirmation. Resolves to true only when confirmed.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.icon = Icons.help_rounded,
    this.tone = SoftTone.success,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;
  final SoftTone tone;

  static Future<bool> ask({
    required String title,
    required String message,
    required String confirmLabel,
    IconData icon = Icons.help_rounded,
    SoftTone tone = SoftTone.success,
  }) async {
    final result = await ArenaDialog.show<bool>(ConfirmDialog(title: title, message: message, confirmLabel: confirmLabel, icon: icon, tone: tone));
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ArenaDialog(
      title: title,
      icon: icon,
      actions: [
        SoftButton(label: 'Not now', onPressed: () => Navigator.of(context).pop(false)),
        SoftButton(label: confirmLabel, tone: tone, solid: true, onPressed: () => Navigator.of(context).pop(true)),
      ],
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(message, style: context.text.bodyMedium),
      ),
    );
  }
}
