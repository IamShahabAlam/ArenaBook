import 'package:get/get.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/resource.dart';
import '../../../data/rules/booking_stats.dart';

class HomeController extends GetxController {
  /// null = All Courts.
  final typeFilter = Rxn<ResourceType>();

  void setFilter(ResourceType? resourceType) => typeFilter.value = resourceType;

  BookingStats get stats => BookingStats.from(BookingService.to.bookings, resourceType: typeFilter.value);

  /// Next active bookings, soonest first.
  List<Booking> get upcoming {
    final now = BookingService.to.now();
    return BookingService.to.bookings
        .where((b) => !b.isCancelled && b.isUpcoming(now) && (typeFilter.value == null || b.resourceType == typeFilter.value))
        .take(4)
        .toList();
  }
}
