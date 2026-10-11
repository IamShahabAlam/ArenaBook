import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../data/models/booking.dart';
import '../../../data/rules/booking_rules.dart';
import '../widgets/whatsapp_logo.dart';

/// Call, SMS or WhatsApp the booking's customer. Opened from the invoice sheet.
class ContactCustomerSheet extends StatelessWidget {
  const ContactCustomerSheet({super.key, required this.booking});

  final Booking booking;

  static Future<void> show(Booking booking) async {
    final context = Get.context;
    if (context == null || booking.phone.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => ContactCustomerSheet(booking: booking),
    );
  }

  /// 03001234567 -> tel:+923001234567, sms:+923001234567, https://wa.me/923001234567 (wa.me wants no "+").
  static ({Uri call, Uri sms, Uri whatsApp}) links(String phone) {
    final number = BookingRules.toWhatsAppNumber(phone);
    return (call: Uri(scheme: 'tel', path: '+$number'), sms: Uri(scheme: 'sms', path: '+$number'), whatsApp: Uri.parse('https://wa.me/$number'));
  }

  static Future<void> _open(Uri uri, String app) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) ArenaToast.error('Could not open $app');
    } catch (_) {
      ArenaToast.error('Could not open $app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final to = links(booking.phone);
    // [icon] takes [color] and size from the IconTheme, so Material icons and WhatsAppLogo match.
    Widget option(Widget icon, Color color, String label, String app, Uri uri) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: IconTheme(
              data: IconThemeData(color: color, size: 20),
              child: icon,
            ),
          ),
          title: Text(label, style: context.text.labelLarge),
          trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
          onTap: () {
            Navigator.of(context).pop(); // close first, so returning from the other app lands on the invoice
            _open(uri, app);
          },
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contact ${booking.customerName}', textAlign: TextAlign.center, style: context.text.titleMedium),
          Text(booking.phone, textAlign: TextAlign.center, style: context.text.bodySmall),
          const SizedBox(height: 16),
          option(const Icon(Icons.call_rounded), c.cricketText, 'Call', 'the dialer', to.call),
          option(const Icon(Icons.sms_rounded), c.padelText, 'SMS', 'your messages app', to.sms),
          option(const WhatsAppLogo(), c.limeText, 'WhatsApp', 'WhatsApp', to.whatsApp),
        ],
      ),
    );
  }
}
