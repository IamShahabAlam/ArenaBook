import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../../../data/rules/booking_rules.dart';
import '../../../data/rules/invoice_text.dart';
import '../shell/booking_actions.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/booking_card.dart';
import '../widgets/motion.dart';

/// Digital receipt. Reads the booking reactively, so "Mark Paid" updates it in place.
class InvoiceSheet extends StatelessWidget {
  const InvoiceSheet({super.key, required this.bookingId});

  final String bookingId;

  static Future<void> show(String bookingId) async {
    final context = Get.context;
    if (context == null || BookingService.to.byId(bookingId) == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InvoiceSheet(bookingId: bookingId),
    );
  }

  Future<void> _shareWhatsApp(Booking b) async {
    final text = InvoiceText.whatsApp(b, currency: SettingsStore.to.currencySymbol.value);
    final number = BookingRules.toWhatsAppNumber(b.phone);
    final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) ArenaToast.error('Could not open WhatsApp');
    } catch (_) {
      ArenaToast.error('Could not open WhatsApp');
    }
  }

  Future<void> _copy(Booking b) async {
    await Clipboard.setData(ClipboardData(text: InvoiceText.plain(b, currency: SettingsStore.to.currencySymbol.value)));
    ArenaToast.success('Invoice details copied!');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Obx(() {
      final b = BookingService.to.byId(bookingId);
      if (b == null) return const SizedBox(height: 120);
      final badge = bookingBadge(b, c);
      final badgeLabel = switch (b.status) {
        BookingStatus.paid => 'Paid In Full',
        BookingStatus.pending => 'Balance Due: ${ArenaFormat.money(b.balanceDue)}',
        BookingStatus.cancelled => 'Cancelled',
      };

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(gradient: ArenaColors.ctaGradient, borderRadius: BorderRadius.circular(16)),
              child: Icon(b.sport.icon, color: c.onAccent, size: 26),
            ).popIn(context, delay: const Duration(milliseconds: 120)),
            const SizedBox(height: 10),
            // Crossfades when the status changes (e.g. "Balance Due" -> "Paid In Full" after Mark Paid).
            AnimatedSwitcher(
              duration: context.motion(const Duration(milliseconds: 280)),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(animation), child: child),
              ),
              child: ArenaBadge(key: ValueKey(badgeLabel), label: badgeLabel.toUpperCase(), color: badge.color),
            ),
            const SizedBox(height: 6),
            Text('#${b.id}', style: context.text.headlineSmall),
            Text('ARENABOOK · Official Ground Booking Receipt', style: context.text.bodySmall),
            const SizedBox(height: 14),
            _ReceiptBody(booking: b),
            const SizedBox(height: 14),
            if (b.phone.isNotEmpty) GradientButton(label: 'Share via WhatsApp', icon: Icons.chat_rounded, onPressed: () => _shareWhatsApp(b)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SoftButton(label: 'Copy Text', icon: Icons.copy_rounded, onPressed: () => _copy(b)),
                ),
                if (b.balanceDue > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoftButton(label: 'Mark Paid', icon: Icons.done_all_rounded, tone: SoftTone.warning, onPressed: () => BookingActions.markPaid(b.id)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final b = booking;

    Widget line(String label, String value, {Color? color, bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (bold ? context.text.titleSmall : context.text.labelMedium)?.copyWith(color: color ?? c.textPrimary),
            ),
          ),
        ],
      ),
    );

    Widget caption(String text) => Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(color: c.textMuted, letterSpacing: 0.5));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    caption('Customer'),
                    const SizedBox(height: 2),
                    Text(b.customerName, style: context.text.titleSmall),
                    Text(b.phone.isEmpty ? 'N/A' : b.phone, style: context.text.bodySmall),
                    if (b.email.isNotEmpty) Text(b.email, style: context.text.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  caption('Booking Date'),
                  const SizedBox(height: 2),
                  Text(ArenaFormat.longDate(b.date), style: context.text.labelMedium?.copyWith(color: c.textPrimary)),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.border),
          ),
          line('Ground/Court:', b.court.name, color: b.sport.text(c)),
          line('Time Slot(s):', b.slotsLabel),
          line('Duration:', '${ArenaFormat.hours(b.totalMinutes)} @ ${ArenaFormat.money(b.hourlyRate)}/hr'),
          if (b.notes.isNotEmpty) line('Notes:', b.notes),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.border),
          ),
          line('Total Fee:', ArenaFormat.money(b.totalFee)),
          line('Advance Paid:', ArenaFormat.money(b.advancePaid), color: c.cricketText),
          if (b.balanceSettledAt != null && !b.isCancelled)
            line('Balance Paid (${ArenaFormat.longDate(b.balanceSettledAt!)}):', ArenaFormat.money(b.totalFee - b.advancePaid), color: c.cricketText),
          if (b.isCancelled) ...[
            line('Advance:', b.advanceReturned ? 'Returned to player' : 'Kept (non-refundable)', color: c.dangerText),
            line('Reason:', b.cancelReason, color: c.dangerText),
          ],
          const SizedBox(height: 4),
          Divider(color: c.border),
          const SizedBox(height: 4),
          line('Remaining Balance:', ArenaFormat.money(b.balanceDue), color: b.balanceDue > 0 ? c.warningText : c.textPrimary, bold: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VERIFIED ARENABOOK PASS', style: context.text.labelSmall?.copyWith(color: c.textMuted, letterSpacing: 0.6)),
                    Text(
                      'Show at arena entry',
                      style: context.text.labelSmall?.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: QrImageView(
                  data: InvoiceText.qrData(b),
                  size: 64,
                  padding: EdgeInsets.zero,
                  semanticsLabel: 'Booking QR code for ${b.id}',
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF020617)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF020617)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
