import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';

enum Timeline { future, past, all }

class BookingsController extends GetxController {
  final query = ''.obs;
  final sportFilter = Rxn<Sport>();
  final timeline = Timeline.future.obs; // spec default
  final dateRange = Rxn<DateTimeRange>();
  final searchCtrl = TextEditingController();

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  void clearSearch() {
    searchCtrl.clear();
    query.value = '';
  }

  void setRange(DateTimeRange? range) => dateRange.value = range == null ? null : DateTimeRange(start: dateOnly(range.start), end: dateOnly(range.end));

  List<Booking> get filtered {
    final now = BookingService.to.now();
    final q = query.value.trim().toLowerCase();
    final range = dateRange.value;

    final result = BookingService.to.bookings.where((b) {
      if (q.isNotEmpty && !(b.customerName.toLowerCase().contains(q) || b.phone.contains(q) || b.id.toLowerCase().contains(q))) return false;
      if (sportFilter.value != null && b.sport != sportFilter.value) return false;
      if (range != null && (b.date.isBefore(range.start) || b.date.isAfter(range.end))) return false;
      return switch (timeline.value) {
        Timeline.future => b.isUpcoming(now),
        Timeline.past => !b.isUpcoming(now),
        Timeline.all => true,
      };
    }).toList();

    // Upcoming: soonest first. Past / all: most recent first.
    return timeline.value == Timeline.future ? result : result.reversed.toList();
  }
}
