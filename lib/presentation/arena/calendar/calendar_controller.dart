import 'package:get/get.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';

class CalendarController extends GetxController {
  late final month = _firstOfMonth(BookingService.to.now()).obs;
  late final selected = dateOnly(BookingService.to.now()).obs;

  /// +1 when the last month change went forward, -1 when back; the grid slides in from that side.
  int lastDirection = 1;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  /// [offset] months forward/back; DateTime normalises month 0 / 13 into the right year.
  void shiftMonth(int offset) {
    lastDirection = offset >= 0 ? 1 : -1;
    month.value = DateTime(month.value.year, month.value.month + offset);
  }

  void goToday() {
    final now = BookingService.to.now();
    final target = _firstOfMonth(now);
    lastDirection = target.isBefore(month.value) ? -1 : 1;
    month.value = target;
    selected.value = dateOnly(now);
  }

  void select(DateTime day) => selected.value = dateOnly(day);

  /// Distinct sports with active bookings, per day of the visible month: one dot each, however many bookings.
  /// Config order, so a sport's dot always sits in the same place.
  Map<String, List<Sport>> get sportsByDay {
    final byDay = <String, Set<Sport>>{};
    for (final b in BookingService.to.bookings) {
      if (b.isCancelled || b.date.year != month.value.year || b.date.month != month.value.month) continue;
      (byDay[dateKey(b.date)] ??= {}).add(b.sport);
    }
    int rank(Sport s) => switch (Sport.all.indexOf(s)) {
      -1 => Sport.all.length, // removed from config: last
      final i => i,
    };
    return {for (final e in byDay.entries) e.key: e.value.toList()..sort((a, b) => rank(a).compareTo(rank(b)))};
  }

  List<Booking> get selectedDayBookings => BookingService.to.bookings.where((b) => !b.isCancelled && isSameDay(b.date, selected.value)).toList();
}
