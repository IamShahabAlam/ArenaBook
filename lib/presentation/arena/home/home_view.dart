import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../shell/booking_actions.dart';
import '../shell/shell_controller.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/booking_card.dart';
import '../widgets/motion.dart';
import '../widgets/sport_filter.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Obx(() => SportFilter(selected: controller.sportFilter.value, onChanged: controller.setFilter, withAvatars: true)),
        const SizedBox(height: 14),
        Obx(() {
          final s = controller.stats;
          return GridView.count(
            crossAxisCount: 2,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _MetricCard(
                title: 'Total Slots',
                value: s.totalBookings,
                format: ArenaFormat.number,
                index: 0,
                caption: 'Booked entries',
                icon: Icons.event_available_rounded,
                accent: c.cricketText,
              ),
              _MetricCard(
                title: 'Pending Dues',
                value: s.pendingAmount,
                format: ArenaFormat.money,
                index: 1,
                caption: '${s.pendingCount} ${s.pendingCount == 1 ? 'booking' : 'bookings'} with dues',
                icon: Icons.history_rounded,
                accent: c.warningText,
                highlight: true,
                onTap: () => ShellController.to.go(ArenaTab.pending),
              ),
              _MetricCard(
                title: 'Collected',
                value: s.collectedAmount,
                format: ArenaFormat.money,
                index: 2,
                caption: 'Advance & settled payments',
                icon: Icons.account_balance_wallet_rounded,
                accent: c.limeText,
              ),
              _MetricCard(
                title: 'Total Value',
                value: s.totalValue,
                format: ArenaFormat.money,
                index: 3,
                caption: 'Gross booking revenue',
                icon: Icons.receipt_long_rounded,
                accent: c.padelText,
              ),
            ],
          );
        }),
        const SizedBox(height: 14),
        ArenaCard(
          gradient: ArenaCard.tint(context, c.cricket),
          borderColor: c.cricket.withValues(alpha: 0.35),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 17, color: c.limeText),
                        const SizedBox(width: 4),
                        Flexible(child: Text('Direct Ground Booking', style: context.text.titleSmall)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('Reserve turf pitch or padel court slot', style: context.text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GradientButton(label: 'Book Slot', icon: Icons.arrow_forward_rounded, expanded: false, compact: true, onPressed: BookingActions.newBooking),
            ],
          ),
        ).entrance(context, index: 4),
        const SizedBox(height: 18),
        SectionTitle(
          title: 'Upcoming & Active Slots',
          icon: Icons.checklist_rounded,
          trailing: TextButton(onPressed: () => ShellController.to.go(ArenaTab.bookings), child: const Text('View All')),
        ),
        const SizedBox(height: 6),
        Obx(
          () => BookingList(
            bookings: controller.upcoming,
            empty: EmptyState(
              icon: Icons.event_busy_rounded,
              message: controller.sportFilter.value == null
                  ? 'No upcoming bookings yet.'
                  : 'No upcoming ${controller.sportFilter.value!.shortLabel.toLowerCase()} bookings.',
              action: GradientButton(label: 'Create a booking', icon: Icons.add_rounded, expanded: false, compact: true, onPressed: BookingActions.newBooking),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.format,
    required this.index,
    required this.caption,
    required this.icon,
    required this.accent,
    this.highlight = false,
    this.onTap,
  });

  final String title;
  final int value;
  final String Function(int value) format;
  final int index; // stagger position
  final String caption;
  final IconData icon;
  final Color accent;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Semantics(
      button: onTap != null,
      label: '$title: ${format(value)}. $caption',
      excludeSemantics: true,
      child: ArenaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        borderColor: highlight ? c.warning.withValues(alpha: 0.4) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(color: highlight ? c.warningText : c.textSecondary, letterSpacing: 0.6),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: accent),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedNumber(
                value: value,
                format: format,
                style: context.text.headlineSmall?.copyWith(color: highlight ? c.warningText : c.textPrimary),
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ).entrance(context, index: index);
  }
}
