import '../models/booking.dart';
import '../models/sport.dart';

/// Dashboard numbers. Cancelled bookings are excluded, as in the spec.
class BookingStats {
  const BookingStats({
    required this.totalBookings,
    required this.pendingAmount,
    required this.pendingCount,
    required this.collectedAmount,
    required this.totalValue,
  });

  final int totalBookings;
  final int pendingAmount;
  final int pendingCount;
  final int collectedAmount;
  final int totalValue;

  /// [sport] null = all courts.
  factory BookingStats.from(Iterable<Booking> bookings, {Sport? sport}) {
    var total = 0, pending = 0, pendingCount = 0, collected = 0, value = 0;
    for (final b in bookings) {
      if (b.isCancelled || (sport != null && b.sport != sport)) continue;
      total++;
      value += b.totalFee;
      collected += b.amountCollected;
      if (b.balanceDue > 0) {
        pending += b.balanceDue;
        pendingCount++;
      }
    }
    return BookingStats(totalBookings: total, pendingAmount: pending, pendingCount: pendingCount, collectedAmount: collected, totalValue: value);
  }
}
