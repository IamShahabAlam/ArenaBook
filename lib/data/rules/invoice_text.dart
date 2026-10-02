import '../../app/utils/formatters/arena_format.dart';
import '../models/booking.dart';
import '../models/sport.dart';

/// Shareable receipt text. Pure functions of the booking, so they are unit tested.
class InvoiceText {
  InvoiceText._();

  static String statusLabel(Booking b) => switch (b.status) {
    BookingStatus.paid => 'PAID IN FULL',
    BookingStatus.pending => 'BALANCE DUE',
    BookingStatus.cancelled => 'CANCELLED',
  };

  /// WhatsApp message (*bold* is WhatsApp markdown).
  static String whatsApp(Booking b, {required String currency}) {
    String m(int v) => ArenaFormat.money(v, symbol: currency);
    final emoji = b.sport == Sport.cricket ? '🏏' : '🎾';
    return [
      '$emoji *ARENABOOK GROUND RECEIPT*',
      '---------------------------------------',
      '*Ref ID:* #${b.id}',
      '*Customer:* ${b.customerName}',
      '*Court:* ${b.court.name}',
      '*Date:* ${ArenaFormat.longDate(b.date)}',
      '*Slots:* ${b.slotsLabel}',
      '',
      '*Total Fee:* ${m(b.totalFee)}',
      '*Advance Paid:* ${m(b.advancePaid)}',
      if (b.balanceSettledAt != null && !b.isCancelled) '*Balance Paid:* ${m(b.totalFee - b.advancePaid)}',
      '*Balance Due:* ${m(b.balanceDue)}',
      '*Status:* ${statusLabel(b)}',
      if (b.isCancelled) '*Cancellation:* ${b.cancelReason} (advance ${b.advanceReturned ? 'returned' : 'not refunded'})',
      '',
      b.isCancelled ? 'This booking has been cancelled.' : 'Thank you for playing at ArenaBook grounds! Present this receipt at entry.',
    ].join('\n');
  }

  static String plain(Booking b, {required String currency}) {
    String m(int v) => ArenaFormat.money(v, symbol: currency);
    return 'ARENABOOK INVOICE #${b.id} (${statusLabel(b)})\n'
        'Customer: ${b.customerName} (${b.phone})\n'
        'Court: ${b.court.name}\n'
        'Date: ${ArenaFormat.longDate(b.date)} (${b.slotsLabel})\n'
        'Total: ${m(b.totalFee)} | Paid: ${m(b.amountCollected)} | Due: ${m(b.balanceDue)}';
  }

  /// QR payload: enough to look the booking up at the gate.
  static String qrData(Booking b) => 'ARENABOOK|${b.id}|${dateKey(b.date)}|${b.courtId}|${b.slots.map((s) => '${s.startMinute}-${s.endMinute}').join(',')}';
}
