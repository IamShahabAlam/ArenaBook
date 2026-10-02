import 'package:get/get.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/sport.dart';
import '../../../data/rules/booking_stats.dart';

class HomeController extends GetxController {
  /// null = All Courts.
  final sportFilter = Rxn<Sport>();

  void setFilter(Sport? sport) => sportFilter.value = sport;

  BookingStats get stats => BookingStats.from(BookingService.to.bookings, sport: sportFilter.value);

  /// Next active bookings, soonest first.
  List<Booking> get upcoming {
    final now = BookingService.to.now();
    return BookingService.to.bookings
        .where((b) => !b.isCancelled && b.isUpcoming(now) && (sportFilter.value == null || b.sport == sportFilter.value))
        .take(4)
        .toList();
  }
}
