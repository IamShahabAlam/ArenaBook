import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';
import '../shell/booking_actions.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/booking_card.dart';
import '../widgets/motion.dart';
import 'calendar_controller.dart';

class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Obx(() {
          final count = controller.selectedDayBookings.length;
          final day = controller.selected.value;
          final today = isSameDay(day, BookingService.to.now());
          return ArenaCard(
            gradient: ArenaCard.tint(context, c.cricket),
            borderColor: c.cricket.withValues(alpha: 0.35),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATE SCHEDULE BREAKDOWN',
                        style: context.text.labelSmall?.copyWith(color: c.cricketText, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text('${ArenaFormat.longDate(day)}${today ? ' (Today)' : ''}', style: context.text.titleMedium),
                      const SizedBox(height: 3),
                      Text('$count ${count == 1 ? 'Booking' : 'Bookings'} Scheduled', style: context.text.bodySmall?.copyWith(color: c.textPrimary)),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: c.cricket.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.calendar_month_rounded, color: c.cricketText),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        ArenaCard(
          child: Obx(() {
            final month = controller.month.value;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(ArenaFormat.monthYear(month), style: context.text.titleSmall)),
                    _NavButton(icon: Icons.chevron_left_rounded, tooltip: 'Previous month', onTap: () => controller.shiftMonth(-1)),
                    const SizedBox(width: 4),
                    SoftButton(label: 'Today', onPressed: controller.goToday),
                    const SizedBox(width: 4),
                    _NavButton(icon: Icons.chevron_right_rounded, tooltip: 'Next month', onTap: () => controller.shiftMonth(1)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final d in const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
                      Expanded(
                        child: Text(
                          d.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: c.border),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: context.motion(const Duration(milliseconds: 260)),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    // The incoming month enters from the side we're moving to; the old one just fades.
                    final incoming = child.key == ValueKey(month);
                    final slide = Tween<Offset>(begin: Offset(0.12 * controller.lastDirection, 0), end: Offset.zero).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: incoming ? SlideTransition(position: slide, child: child) : child,
                    );
                  },
                  layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                  child: _MonthGrid(
                    key: ValueKey(month),
                    month: month,
                    selected: controller.selected.value,
                    sportsByDay: controller.sportsByDay,
                    onSelect: controller.select,
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
        const SectionTitle(title: 'Scheduled Slots', icon: Icons.checklist_rounded),
        const SizedBox(height: 8),
        Obx(() {
          final day = controller.selected.value;
          final canBook = !day.isBefore(dateOnly(BookingService.to.now()));
          return BookingList(
            bookings: controller.selectedDayBookings,
            empty: EmptyState(
              icon: Icons.event_available_rounded,
              message: 'No bookings scheduled on ${ArenaFormat.longDate(day)}',
              action: canBook
                  ? SoftButton(
                      label: 'Book This Date Slot',
                      icon: Icons.add_rounded,
                      tone: SoftTone.success,
                      onPressed: () => BookingActions.newBooking(onDate: day),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SoftButton(icon: icon, tooltip: tooltip, onPressed: onTap);
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({super.key, required this.month, required this.selected, required this.sportsByDay, required this.onSelect});

  final DateTime month;
  final DateTime selected;
  final Map<String, List<Sport>> sportsByDay; // dateKey -> distinct sports booked that day
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final leading = DateTime(month.year, month.month).weekday % 7; // Sunday-first grid
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = BookingService.to.now();
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final dayNumber = r * 7 + col - leading + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox(height: 44);
                        final day = DateTime(month.year, month.month, dayNumber);
                        final isSelected = isSameDay(day, selected);
                        final isToday = isSameDay(day, today);
                        final sports = sportsByDay[dateKey(day)] ?? const <Sport>[];
                        final bg = isSelected ? c.cricket : (isToday ? c.surfaceMuted : c.surface);
                        final fg = isSelected ? c.onAccent : (isToday ? c.cricketText : c.textPrimary);
                        final border = isSelected ? c.cricket : (isToday ? c.cricket.withValues(alpha: 0.6) : c.border);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Semantics(
                            button: true,
                            selected: isSelected,
                            label: '${ArenaFormat.longDate(day)}${sports.isEmpty ? '' : ', ${sports.map((s) => s.shortLabel).join(' and ')} bookings'}',
                            excludeSemantics: true,
                            child: Material(
                              color: bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                                side: BorderSide(color: border),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () => onSelect(day),
                                child: SizedBox(
                                  height: 44,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNumber',
                                        style: context.text.labelMedium?.copyWith(
                                          color: fg,
                                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      SizedBox(
                                        height: 6,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (final sport in sports)
                                              Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: sport.text(c),
                                                  // Ring keeps the emerald dot visible on the emerald selected cell.
                                                  border: isSelected ? Border.all(color: c.onAccent, width: 1) : null,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
