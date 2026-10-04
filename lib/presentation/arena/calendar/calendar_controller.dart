import 'package:get/get.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../data/models/booking.dart';

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

  /// Active bookings per day of the visible month (for the dots).
  Set<String> get daysWithBookings => {
    for (final b in BookingService.to.bookings)
      if (!b.isCancelled && b.date.year == month.value.year && b.date.month == month.value.month) dateKey(b.date),
  };

  List<Booking> get selectedDayBookings => BookingService.to.bookings.where((b) => !b.isCancelled && isSameDay(b.date, selected.value)).toList();
}
