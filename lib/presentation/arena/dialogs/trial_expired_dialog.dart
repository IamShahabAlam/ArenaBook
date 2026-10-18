import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/app_access_service.dart';
import 'arena_dialog.dart';
import 'info_dialogs.dart';

/// Shown by AppAccessService while the trial switch blocks the app. The user can't close it:
/// no close button, no barrier tap, back does nothing. Only the service removes it, once the Gist allows the app again.
class TrialExpiredDialog extends StatelessWidget {
  const TrialExpiredDialog({super.key});

  static const message = 'Your trial has expired; please contact the developer.';
  static const notActivatedMessage = 'This app is not activated for your arena; please contact the developer.';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Obx(() {
        final notActivated = AppAccessService.to.notActivated.value; // bad Gist or client not listed
        return ArenaDialog(
          title: notActivated ? 'App Not Activated' : 'Trial Expired',
          icon: notActivated ? Icons.lock_rounded : Icons.lock_clock_rounded,
          iconColor: context.arena.dangerText,
          closable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(notActivated ? notActivatedMessage : message, textAlign: TextAlign.center, style: context.text.bodyMedium),
              const SizedBox(height: 14),
              const SupportContacts(),
            ],
          ),
        );
      }),
    );
  }
}
