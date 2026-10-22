import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/config/app_client_config.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/pricing.dart';
import '../../../data/rules/invoice_text.dart';
import '../shell/booking_actions.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/booking_card.dart';
import '../widgets/motion.dart';
import '../widgets/whatsapp_logo.dart';
import 'contact_customer_sheet.dart';

/// Digital receipt. Reads the booking reactively, so "Mark Paid" updates it in place.
class InvoiceSheet extends StatefulWidget {
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

  /// Hands the receipt picture to the phone's share sheet. Swappable so tests can check the image.
  static Future<void> Function(Uint8List png, Booking booking, Rect? origin) shareImage = _systemShare;

  static Future<void> _systemShare(Uint8List png, Booking b, Rect? origin) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: ['ArenaBook-${b.id}.png'],
        text: '${AppStrings.appName} booking receipt #${b.id}', // caption under the picture
        sharePositionOrigin: origin, // iPad: where the share popover points
      ),
    );
  }

  @override
  State<InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends State<InvoiceSheet> {
  final _receiptKey = GlobalKey(); // the region that becomes the shared picture
  var _sharing = false;

  /// Renders the receipt region to a PNG (like fintech "share receipt") and shares it.
  Future<void> _shareImage(Booking b) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0));
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null || !mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      await InvoiceSheet.shareImage(data.buffer.asUint8List(), b, origin);
    } catch (_) {
      ArenaToast.error('Could not share the invoice');
    } finally {
      if (mounted) setState(() => _sharing = false);
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
      final b = BookingService.to.byId(widget.bookingId);
      if (b == null) return const SizedBox(height: 120);
      final badge = bookingBadge(b, c);
      final badgeLabel = switch (b.status) {
        BookingStatus.paid => 'Paid In Full',
        BookingStatus.pending => 'Balance Due: ${ArenaFormat.money(b.balanceDue)}',
        BookingStatus.cancelled => 'Cancelled',
      };

      return SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 18 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          children: [
            Stack(
              children: [
                // Shared picture: tile, status, number and receipt. Own background and margins, so the image looks finished.
                RepaintBoundary(
                  key: _receiptKey,
                  child: ColoredBox(
                    color: c.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(gradient: ArenaColors.ctaGradient, borderRadius: BorderRadius.circular(16)),
                            child: Icon(b.resourceType.symbol, color: c.onAccent, size: 26),
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
                          Text('ARENABOOK · Official ${AppClientConfig.terms.booking} Receipt', style: context.text.bodySmall),
                          const SizedBox(height: 14),
                          _ReceiptBody(booking: b),
                        ],
                      ),
                    ),
                  ),
                ),
                // Outside the picture. Top-right,
                if (b.phone.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 18,
                    child: SoftButton(
                      label: 'Contact',
                      icon: Icons.contact_phone_rounded,
                      tooltip: 'Contact customer',
                      onPressed: () => ContactCustomerSheet.show(b),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  GradientButton(label: 'Share via WhatsApp', leading: const WhatsAppLogo(), loading: _sharing, onPressed: () => _shareImage(b)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SoftButton(label: 'Copy Text', icon: Icons.copy_rounded, onPressed: () => _copy(b)),
                      ),
                      if (b.balanceDue > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SoftButton(
                            label: 'Mark Paid',
                            icon: Icons.done_all_rounded,
                            tone: SoftTone.warning,
                            onPressed: () => BookingActions.markPaid(b.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
          line('${AppClientConfig.terms.resource}:', b.resource.name, color: b.resourceType.text(c)),
          line('Time Slot(s):', b.slotsLabel),
          // A typed price has no rate behind it, so only the length is shown.
          line(
            'Duration:',
            b.pricing == PricingMode.hourly
                ? '${ArenaFormat.hours(b.totalMinutes)} @ ${ArenaFormat.money(b.hourlyRate)}/hr'
                : ArenaFormat.hours(b.totalMinutes),
          ),
          if (b.notes.isNotEmpty) line('Notes:', b.notes),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.border),
          ),
          if (InvoiceText.showDiscount(b)) ...[
            line('${AppClientConfig.terms.fee}:', ArenaFormat.money(b.totalFee)),
            line('Discount:', '-${ArenaFormat.money(b.discount)}', color: c.limeText),
          ],
          line('Total Fee:', ArenaFormat.money(b.payable)),
          line('Advance Paid:', ArenaFormat.money(b.advancePaid), color: c.cricketText),
          if (b.balanceSettledAt != null && !b.isCancelled)
            line('Balance Paid (${ArenaFormat.longDate(b.balanceSettledAt!)}):', ArenaFormat.money(b.payable - b.advancePaid), color: c.cricketText),
          if (b.isCancelled) ...[
            line('Advance:', b.advanceReturned ? 'Returned to ${AppClientConfig.terms.customer.toLowerCase()}' : 'Kept (non-refundable)', color: c.dangerText),
            line('Reason:', b.cancelReason, color: c.dangerText),
          ],
          const SizedBox(height: 4),
          Divider(color: c.border),
          const SizedBox(height: 4),
          line('Remaining Balance:', ArenaFormat.money(b.balanceDue), color: b.balanceDue > 0 ? c.warningText : c.textPrimary, bold: true),
          // QR entry pass only for businesses that check customers in (Features.entryPass).
          if (AppClientConfig.features.entryPass) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VERIFIED ARENABOOK PASS', style: context.text.labelSmall?.copyWith(color: c.textMuted, letterSpacing: 0.6)),
                      Text(
                        AppClientConfig.terms.passHint,
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
        ],
      ),
    );
  }
}
