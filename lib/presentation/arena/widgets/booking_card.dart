import 'package:flutter/material.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../shell/booking_actions.dart';
import 'arena_widgets.dart';

/// Status badge text + colour, shared by cards and the invoice.
({String label, Color color}) bookingBadge(Booking b, ArenaColors c) => switch (b.status) {
  BookingStatus.cancelled => (label: 'Cancelled', color: c.dangerText),
  BookingStatus.pending => (label: 'Due: ${ArenaFormat.money(b.balanceDue)}', color: c.warningText),
  BookingStatus.paid => (label: 'Paid', color: c.cricketText),
};

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final b = booking;
    final badge = bookingBadge(b, c);
    final canEdit = b.canEdit(BookingService.to.now());

    return ArenaCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SportAvatar(sport: b.sport),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '#${b.id}  ',
                            style: TextStyle(color: c.textMuted),
                          ),
                          TextSpan(text: b.court.name),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Capped so a long "Due: Rs 12,345" can never squeeze the name to nothing.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: ArenaBadge(label: badge.label, color: badge.color),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.border),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: c.cricketText),
              const SizedBox(width: 5),
              Text(ArenaFormat.shortDay(b.date), style: context.text.labelSmall),
              const SizedBox(width: 12),
              Icon(Icons.schedule_rounded, size: 14, color: c.cricketText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(b.slotsLabel, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
              ),
            ],
          ),
          if (b.isCancelled && b.cancelReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${b.cancelReason} · Advance ${b.advanceReturned ? 'returned' : 'kept'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: c.dangerText, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SoftButton(label: 'Invoice', icon: Icons.receipt_long_rounded, onPressed: () => BookingActions.openInvoice(b.id)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SoftButton(label: 'Repeat', icon: Icons.replay_rounded, tone: SoftTone.success, onPressed: () => BookingActions.repeat(b.id)),
              ),
              if (canEdit) ...[
                const SizedBox(width: 6),
                SoftButton(icon: Icons.edit_rounded, tone: SoftTone.info, tooltip: 'Edit booking', onPressed: () => BookingActions.edit(b.id)),
              ],
              if (!b.isCancelled) ...[
                const SizedBox(width: 6),
                SoftButton(icon: Icons.block_rounded, tone: SoftTone.danger, tooltip: 'Cancel booking', onPressed: () => BookingActions.cancel(b.id)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A list of booking cards (with spacing) or an empty message.
class BookingList extends StatelessWidget {
  const BookingList({super.key, required this.bookings, required this.empty});

  final List<Booking> bookings;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return empty;
    return Column(
      children: [
        for (var i = 0; i < bookings.length; i++) ...[if (i > 0) const SizedBox(height: 10), BookingCard(key: ValueKey(bookings[i].id), booking: bookings[i])],
      ],
    );
  }
}
