import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/config/arena_theme.dart';
import '../../../../app/service/getx_service/booking_service.dart';
import '../../../../app/utils/formatters/arena_format.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/time_range.dart';
import '../../../../data/rules/booking_rules.dart';
import '../../widgets/arena_widgets.dart';
import '../booking_form_controller.dart';

/// Pick a start (30-min steps, any time of day) + a duration. Compact: a day bar with every booking,
/// four 6-hour tabs, the tab's 12 start times, and a duration stepper.
class SlotPicker extends GetView<BookingFormController> {
  const SlotPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Obx(() {
      // Touch the inputs this view depends on, so it rebuilds when any of them change.
      controller.date.value;
      controller.courtId.value;
      BookingService.to.bookings.length;
      final chosen = controller.chosenSlots.firstOrNull;
      final error = controller.timeError;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Time', style: context.text.labelMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(width: 12),
              Expanded(
                // Wraps on small phones: "11:30PM - 1:30AM (next day) · 2 hrs" is long.
                child: Text(
                  chosen == null ? 'Pick a start time' : '${chosen.label} · ${ArenaFormat.hours(chosen.durationMinutes)}',
                  textAlign: TextAlign.end,
                  style: context.text.labelMedium?.copyWith(color: chosen == null ? c.textMuted : c.cricketText, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DayBar(occupied: controller.occupied, chosen: chosen, date: controller.date.value, onTapMinute: (m) => controller.selectPeriod(DayPart.of(m))),
          const SizedBox(height: 12),
          _PartTabs(selected: controller.period.value, onChanged: controller.selectPeriod),
          const SizedBox(height: 10),
          _StartGrid(part: controller.period.value),
          const SizedBox(height: 12),
          _DurationStepper(enabled: chosen != null),
          if (error != null) ...[const SizedBox(height: 8), Text(error, style: context.text.labelMedium?.copyWith(color: c.dangerText))],
        ],
      );
    });
  }
}

/// "8:00" / "8:30" (AM/PM is implied by the selected part of the day).
String _clock(int minute) {
  final h = (minute ~/ 60) % 12 == 0 ? 12 : (minute ~/ 60) % 12;
  return '$h:${(minute % 60).toString().padLeft(2, '0')}';
}

/// The whole day at a glance: booked (red), already passed today (grey), your selection (green).
class _DayBar extends StatelessWidget {
  const _DayBar({required this.occupied, required this.chosen, required this.date, required this.onTapMinute});

  final List<TimeRange> occupied;
  final TimeRange? chosen;
  final DateTime date;
  final ValueChanged<int> onTapMinute;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final now = BookingService.to.now();
    final pastUntil = isSameDay(date, now) ? now.hour * 60 + now.minute : 0;
    return Semantics(
      label: '${occupied.length} bookings on this court today',
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onTapMinute((d.localPosition.dx / box.maxWidth * TimeRange.minutesPerDay).clamp(0, TimeRange.minutesPerDay - 1).toInt()),
          child: Column(
            children: [
              CustomPaint(
                size: Size(box.maxWidth, 14),
                painter: _DayBarPainter(occupied: occupied, chosen: chosen, pastUntil: pastUntil, c: c),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in const ['12AM', '6AM', '12PM', '6PM', '12AM'])
                    Text(t, style: context.text.labelSmall?.copyWith(fontSize: 10, color: c.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBarPainter extends CustomPainter {
  _DayBarPainter({required this.occupied, required this.chosen, required this.pastUntil, required this.c});

  final List<TimeRange> occupied;
  final TimeRange? chosen;
  final int pastUntil;
  final ArenaColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(track, Paint()..color = c.surfaceMuted);
    canvas.save();
    canvas.clipRRect(track);
    double x(int m) => m / TimeRange.minutesPerDay * size.width;
    void band(int from, int to, Color color) => canvas.drawRect(Rect.fromLTRB(x(from), 0, x(to), size.height), Paint()..color = color);

    if (pastUntil > 0) band(0, pastUntil, c.textMuted.withValues(alpha: 0.25));
    for (final o in occupied) {
      band(o.startMinute, o.endMinute, c.danger.withValues(alpha: 0.8));
    }
    if (chosen != null) band(chosen!.startMinute, chosen!.endMinute, c.cricket);
    // 6-hour dividers
    for (final m in [360, 720, 1080]) {
      canvas.drawLine(
        Offset(x(m), 0),
        Offset(x(m), size.height),
        Paint()
          ..color = c.border
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = c.border,
    );
  }

  @override
  bool shouldRepaint(_DayBarPainter old) => old.occupied != occupied || old.chosen != chosen || old.pastUntil != pastUntil || old.c != c;
}

/// Night · Morning · Afternoon · Evening, each with its hours underneath.
class _PartTabs extends StatelessWidget {
  const _PartTabs({required this.selected, required this.onChanged});

  final DayPart selected;
  final ValueChanged<DayPart> onChanged;

  static const _hours = {DayPart.night: '12–6 AM', DayPart.morning: '6 AM–12 PM', DayPart.afternoon: '12–6 PM', DayPart.evening: '6 PM–12 AM'};

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return Row(
      children: [
        for (final p in DayPart.values) ...[
          if (p != DayPart.values.first) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: p == selected,
              child: AnimatedTile(
                color: p == selected ? c.cricket : c.surfaceMuted,
                borderColor: p == selected ? c.cricket : c.border,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(p);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      children: [
                        Text(
                          p.label,
                          style: context.text.labelMedium?.copyWith(color: p == selected ? c.onAccent : c.textPrimary, fontWeight: FontWeight.w800),
                        ),
                        Text(_hours[p]!, style: context.text.labelSmall?.copyWith(fontSize: 10, color: p == selected ? c.onAccent : c.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The part's 12 start times. Booked = struck through, past = dimmed, chosen range = green.
class _StartGrid extends GetView<BookingFormController> {
  const _StartGrid({required this.part});

  final DayPart part;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final chosenStart = controller.startMinute.value;
    return GridView.count(
      crossAxisCount: 4,
      padding: EdgeInsets.zero, // without it the grid inherits the nav bar inset
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.4,
      children: [
        for (final start in part.starts)
          Builder(
            builder: (context) {
              final state = controller.cellState(start);
              final isStart = start == chosenStart;
              final (bg, fg, border) = switch (state) {
                SlotState.selected =>
                  isStart ? (c.cricket, c.onAccent, c.cricket) : (c.cricket.withValues(alpha: 0.22), c.cricketText, c.cricket.withValues(alpha: 0.5)),
                SlotState.available => (c.surfaceMuted, c.textPrimary, c.border),
                SlotState.booked => (c.danger.withValues(alpha: 0.08), c.dangerText, c.danger.withValues(alpha: 0.3)),
                SlotState.past => (c.surfaceMuted.withValues(alpha: 0.5), c.textMuted, c.border.withValues(alpha: 0.5)),
              };
              final tappable = state == SlotState.available || state == SlotState.selected;
              final tag = switch (state) {
                SlotState.booked => ', booked',
                SlotState.past => ', past',
                SlotState.selected => ', selected',
                SlotState.available => '',
              };
              return Semantics(
                button: true,
                enabled: tappable,
                label: '${TimeRange.formatMinute(start)}$tag',
                excludeSemantics: true,
                child: Opacity(
                  opacity: state == SlotState.past ? 0.5 : 1,
                  child: AnimatedTile(
                    color: bg,
                    borderColor: border,
                    selected: isStart,
                    radius: 10,
                    onTap: tappable
                        ? () {
                            HapticFeedback.selectionClick();
                            controller.selectStart(start);
                          }
                        : null,
                    child: Center(
                      child: Text(
                        _clock(start),
                        style: context.text.labelMedium?.copyWith(
                          color: fg,
                          fontWeight: isStart ? FontWeight.w800 : FontWeight.w600,
                          decoration: state == SlotState.booked ? TextDecoration.lineThrough : null,
                          decorationColor: fg,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Duration − / + in 30-minute steps, never past the next booking.
class _DurationStepper extends GetView<BookingFormController> {
  const _DurationStepper({required this.enabled});

  final bool enabled;

  String _label(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    return [if (h > 0) '$h h', if (m > 0) '$m m'].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final d = controller.duration.value;
    final max = controller.maxDuration;
    return Row(
      children: [
        Expanded(
          child: Text('Duration', style: context.text.labelMedium?.copyWith(color: c.textSecondary)),
        ),
        SoftButton(
          icon: Icons.remove_rounded,
          tooltip: 'Shorter',
          onPressed: enabled && d > BookingRules.slotStep ? () => controller.changeDuration(-1) : null,
        ),
        SizedBox(
          width: 86,
          child: Text(
            _label(d),
            textAlign: TextAlign.center,
            style: context.text.titleSmall?.copyWith(color: enabled ? c.textPrimary : c.textMuted),
          ),
        ),
        SoftButton(
          icon: Icons.add_rounded,
          tooltip: 'Longer',
          onPressed: enabled && d + BookingRules.slotStep <= max ? () => controller.changeDuration(1) : null,
        ),
      ],
    );
  }
}
