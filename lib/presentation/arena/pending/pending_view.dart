import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../shell/booking_actions.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/motion.dart';

class PendingView extends StatelessWidget {
  const PendingView({super.key});

  /// Unpaid / partly paid active bookings, soonest first.
  static List<Booking> pending() => BookingService.to.bookings.where((b) => b.balanceDue > 0).toList();

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Obx(() {
      final list = pending();
      final total = list.fold(0, (sum, b) => sum + b.balanceDue);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          ArenaCard(
            gradient: ArenaCard.tint(context, c.warning),
            borderColor: c.warning.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNSETTLED GROUND FEES',
                        style: context.text.labelSmall?.copyWith(color: c.warningText, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedNumber(value: total, format: ArenaFormat.money, style: context.text.displaySmall),
                      ),
                      const SizedBox(height: 2),
                      Text('Total balance due from ${list.length} ${list.length == 1 ? 'booking' : 'bookings'}', style: context.text.bodySmall),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: c.warning.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.payments_rounded, color: c.warningText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(title: 'Bookings Requiring Balance', icon: Icons.warning_amber_rounded, iconColor: c.warningText),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const EmptyState(icon: Icons.check_circle_rounded, title: 'All Payments Settled!', message: 'There are no outstanding balances due.').popIn(context)
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              KeyedSubtree(
                key: ValueKey(list[i].id),
                child: _PendingCard(booking: list[i]).entrance(context, index: i),
              ),
            ],
        ],
      );
    });
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final b = booking;
    return ArenaCard(
      borderColor: c.warning.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: #${b.id}',
                      style: context.text.labelSmall?.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(b.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                    const SizedBox(height: 2),
                    Text('${b.court.name} · ${ArenaFormat.shortDay(b.date)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                    Text(b.phone, style: context.text.bodySmall?.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'DUE',
                    style: context.text.labelSmall?.copyWith(color: c.warningText, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    ArenaFormat.money(b.balanceDue),
                    style: context.text.titleMedium?.copyWith(color: c.warningText, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.border),
          ),
          Row(
            children: [
              Expanded(
                child: SoftButton(label: 'Invoice', icon: Icons.receipt_long_rounded, onPressed: () => BookingActions.openInvoice(b.id)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SoftButton(
                  label: 'Mark Paid',
                  icon: Icons.check_rounded,
                  tone: SoftTone.success,
                  solid: true,
                  onPressed: () => BookingActions.markPaid(b.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
