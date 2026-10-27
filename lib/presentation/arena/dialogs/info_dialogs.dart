import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/app_client_config.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/arena_theme.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../app/utils/custom_widgets/arena_logo.dart';
import '../../../data/rules/booking_rules.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/whatsapp_logo.dart';
import 'arena_dialog.dart';

class AboutArenaDialog extends StatelessWidget {
  const AboutArenaDialog({super.key});

  static Future<void> show() => ArenaDialog.show(const AboutArenaDialog());

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final client = AppClientConfig.client;
    final address = client.address?.trim() ?? '';
    final phone = client.phone?.trim() ?? '';

    BoxDecoration panel() => BoxDecoration(
      color: c.surfaceSunken,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.border),
    );

    // Icon + text that wraps under itself, so any length of address lines up.
    Widget contact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: c.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(text, style: context.text.bodySmall?.copyWith(color: c.textSecondary)),
          ),
        ],
      ),
    );

    // Label hugs the left, value takes the rest and right-aligns, so every value ends on the same edge.
    Widget detail(String label, String value, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.text.bodySmall),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: context.text.labelMedium?.copyWith(color: c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );

    return ArenaDialog(
      title: 'About ArenaBook',
      icon: Icons.info_rounded,
      iconColor: c.padelText,
      actions: [SoftButton(label: 'Close', onPressed: () => Navigator.of(context).pop())],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ArenaBook brand
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: ArenaColors.ctaGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: ArenaColors.emerald.withValues(alpha: 0.28), blurRadius: 18)],
              ),
              alignment: Alignment.center,
              child: ArenaLogo(size: 44, color: c.onAccent, semanticLabel: null), // name is right below
            ).popIn(context),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.appName.toUpperCase(), textAlign: TextAlign.center, style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(AppStrings.appTagline, textAlign: TextAlign.center, style: context.text.bodySmall),
          const SizedBox(height: 8),
          Center(
            child: ArenaBadge(label: '${AppStrings.kappVersionWithDate} · build ${AppStrings.kappBuildNumber}', color: c.cricket, textColor: c.cricketText),
          ),
          const SizedBox(height: 18),

          // The client this build is made for
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('LICENSED TO', style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ClientLogo(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name, style: context.text.titleSmall?.copyWith(color: c.textPrimary)),
                          Text('${AppClientConfig.terms.subject} Management', style: context.text.labelSmall?.copyWith(color: c.cricketText)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (address.isNotEmpty || phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: c.border),
                  const SizedBox(height: 2),
                  if (address.isNotEmpty) contact(Icons.location_on_outlined, address),
                  if (phone.isNotEmpty) contact(Icons.call_outlined, phone),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Who built the app
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: panel(),
            child: Column(
              children: [
                detail(
                  'Developer',
                  AppStrings.developerName,
                  onTap: AppStrings.websiteURL.isEmpty ? null : () => launchUrl(Uri.parse(AppStrings.websiteURL), mode: LaunchMode.externalApplication),
                ),
                detail('Built with', 'Flutter'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => showLicensePage(context: context, applicationName: AppStrings.appName),
              child: const Text('Open-source licences'),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportDialog extends StatelessWidget {
  const SupportDialog({super.key});

  static Future<void> show() => ArenaDialog.show(const SupportDialog());

  @override
  Widget build(BuildContext context) {
    return ArenaDialog(
      title: 'Contact Arena Support',
      icon: Icons.support_agent_rounded,
      iconColor: context.arena.warningText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Need help with ${AppClientConfig.terms.bookings.toLowerCase()} or technical assistance?',
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const SupportContacts(),
        ],
      ),
    );
  }
}

/// WhatsApp, call and email buttons from [AppStrings]; shared by the support and trial-expired dialogs.
class SupportContacts extends StatelessWidget {
  const SupportContacts({super.key});

  static Future<void> _open(Uri uri) async {
    final app = switch (uri.scheme) {
      'tel' => 'the dialer',
      'mailto' => 'your email app',
      _ => 'WhatsApp',
    };
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) ArenaToast.error('Could not open $app');
    } catch (_) {
      ArenaToast.error('Could not open $app');
    }
  }

  /// Pre-addressed email; the subject carries the app version for faster support.
  static Uri _emailUri(String email) =>
      Uri(scheme: 'mailto', path: email, query: 'subject=${Uri.encodeComponent('${AppStrings.appName} support (${AppStrings.kappVersionWithDate})')}');

  @override
  Widget build(BuildContext context) {
    final phone = AppStrings.supportPhone.trim();
    final email = AppStrings.supportEmail.trim();
    if (phone.isEmpty && email.isEmpty) {
      return Text(
        'Support contact is not configured yet.',
        textAlign: TextAlign.center,
        style: context.text.labelMedium?.copyWith(color: context.arena.warningText),
      );
    }
    Widget caption(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.labelSmall?.copyWith(color: context.arena.textMuted),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phone.isNotEmpty) ...[
          GradientButton(
            label: 'WhatsApp Support',
            leading: const WhatsAppLogo(),
            // icon: Icons.chat_rounded,
            compact: true,
            onPressed: () => _open(Uri.parse('https://wa.me/${BookingRules.toWhatsAppNumber(phone)}')),
          ),
          const SizedBox(height: 8),
          SoftButton(
            label: 'Call Helpline',
            icon: Icons.call_rounded,
            onPressed: () => _open(Uri(scheme: 'tel', path: '+${BookingRules.toWhatsAppNumber(phone)}')),
          ),
          // caption(phone),
        ],
        if (email.isNotEmpty) ...[
          if (phone.isNotEmpty) const SizedBox(height: 8),
          SoftButton(label: 'Email Support', icon: Icons.email_rounded, onPressed: () => _open(_emailUri(email))),
          // caption(email),
        ],
      ],
    );
  }
}
