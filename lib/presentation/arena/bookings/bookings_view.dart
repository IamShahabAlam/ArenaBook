import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/arena_theme.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/utils/formatters/arena_format.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/booking_card.dart';
import '../widgets/sport_filter.dart';
import 'bookings_controller.dart';

class BookingsView extends GetView<BookingsController> {
  const BookingsView({super.key});

  Future<void> _pickRange(BuildContext context) async {
    final now = BookingService.to.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: controller.dateRange.value,
      helpText: 'Filter bookings by date range',
      saveText: 'Apply',
    );
    if (picked != null) {
      controller.setRange(picked);
      // A range in the past is useless under "Future" — show everything inside the range instead.
      controller.timeline.value = Timeline.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ground Bookings', style: context.text.titleLarge),
                  const SizedBox(height: 2),
                  Text('Filter, edit, repeat or cancel slot bookings', style: context.text.bodySmall),
                ],
              ),
            ),
            HeaderIconButton(icon: Icons.date_range_rounded, tooltip: 'Filter by date range', accent: true, onPressed: () => _pickRange(context)),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller.searchCtrl,
          onChanged: (v) => controller.query.value = v,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search name, phone, or ref...',
            prefixIcon: Icon(Icons.search_rounded, size: 19, color: c.textMuted),
            suffixIcon: Obx(
              () => controller.query.value.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                      onPressed: controller.clearSearch,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => SportFilter(selected: controller.sportFilter.value, onChanged: (s) => controller.sportFilter.value = s, longLabels: true, gap: 10)),
        Obx(
          () => ArenaSegmented<Timeline>(
            dense: true,
            selected: controller.timeline.value,
            onChanged: (t) => controller.timeline.value = t,
            options: const [SegmentOption(Timeline.future, 'Future Bookings'), SegmentOption(Timeline.past, 'Past'), SegmentOption(Timeline.all, 'All Time')],
          ),
        ),
        Obx(() {
          final range = controller.dateRange.value;
          if (range == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: c.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.warning.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded, size: 15, color: c.warningText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Range: ${ArenaFormat.longDate(range.start)} – ${ArenaFormat.longDate(range.end)}',
                      style: context.text.labelSmall?.copyWith(color: c.warningText),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.setRange(null),
                    style: TextButton.styleFrom(foregroundColor: c.warningText),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        Obx(() {
          final list = controller.filtered;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${list.length} ${list.length == 1 ? 'booking' : 'bookings'}', style: context.text.labelSmall),
                ),
              BookingList(
                bookings: list,
                empty: const EmptyState(icon: Icons.search_off_rounded, message: 'No matching ground bookings found.'),
              ),
            ],
          );
        }),
      ],
    );
  }
}
