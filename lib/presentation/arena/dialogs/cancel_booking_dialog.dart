import 'package:flutter/material.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/custom_functions/arena_toast.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../widgets/arena_widgets.dart';
import 'arena_dialog.dart';

/// Cancel flow: refund toggle + required reason.
class CancelBookingDialog extends StatefulWidget {
  const CancelBookingDialog({super.key, required this.booking});

  final Booking booking;

  static Future<void> show(Booking booking) => ArenaDialog.show(CancelBookingDialog(booking: booking));

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  final _reason = TextEditingController();
  var _returned = true;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a cancellation reason');
      return;
    }
    setState(() => _saving = true);
    try {
      await BookingService.to.cancel(widget.booking.id, reason: _reason.text, advanceReturned: _returned);
      if (!mounted) return;
      Navigator.of(context).pop();
      ArenaToast.show('Booking #${widget.booking.id} has been cancelled');
    } on BookingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not cancel. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final b = widget.booking;
    final hasAdvance = b.advancePaid > 0;

    Widget choice(String label, bool value, SoftTone tone) {
      final active = _returned == value;
      return SoftButton(label: label, tone: active ? tone : SoftTone.neutral, onPressed: () => setState(() => _returned = value));
    }

    return ArenaDialog(
      title: 'Cancel Ground Booking',
      icon: Icons.block_rounded,
      iconColor: c.dangerText,
      titleColor: c.dangerText,
      actions: [
        SoftButton(label: 'Keep Booking', onPressed: () => Navigator.of(context).pop()),
        SoftButton(label: _saving ? 'Cancelling…' : 'Confirm Cancellation', tone: SoftTone.danger, solid: true, onPressed: _saving ? null : _confirm),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking #${b.id} · ${b.customerName}', style: context.text.titleSmall),
          Text('${ArenaFormat.shortDay(b.date)} · ${b.slotsLabel} · ${ArenaFormat.money(b.advancePaid)} advance paid', style: context.text.bodySmall),
          if (hasAdvance) ...[
            const SizedBox(height: 14),
            const FieldLabel('Was advance payment returned to player?'),
            Row(
              children: [
                Expanded(child: choice('Yes, Returned', true, SoftTone.success)),
                const SizedBox(width: 8),
                Expanded(child: choice('No / Non-refundable', false, SoftTone.danger)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const FieldLabel('Cancellation Reason / Remarks *'),
          TextField(
            controller: _reason,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(hintText: 'e.g. Player requested cancellation due to rain', errorText: _error),
          ),
        ],
      ),
    );
  }
}
