import 'package:flutter/material.dart';

import '../../../app/config/arena_theme.dart';
import 'arena_dialog.dart';
import 'info_dialogs.dart';

/// Shown by AppAccessService while the trial switch blocks the app. The user can't close it:
/// no close button, no barrier tap, back does nothing. Only the service removes it, once IsAppEnable is true again.
class TrialExpiredDialog extends StatelessWidget {
  const TrialExpiredDialog({super.key});

  static const message = 'Your trial has expired; please contact the developer.';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ArenaDialog(
        title: 'Trial Expired',
        icon: Icons.lock_clock_rounded,
        iconColor: context.arena.dangerText,
        closable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium),
            const SizedBox(height: 14),
            const SupportContacts(),
          ],
        ),
      ),
    );
  }
}
