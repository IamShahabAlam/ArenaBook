import '../../app/config/app_client_config.dart';
import '../../app/utils/formatters/arena_format.dart';
import '../models/booking.dart';

/// Shareable receipt text. Pure functions of the booking, so they are unit tested.
class InvoiceText {
  InvoiceText._();

  static String statusLabel(Booking b) => switch (b.status) {
    BookingStatus.paid => 'PAID IN FULL',
    BookingStatus.pending => 'BALANCE DUE',
    BookingStatus.cancelled => 'CANCELLED',
  };

  /// Itemise the discount only when the feature is on and this booking has one.
  /// When hidden, totals still use [Booking.payable], so the numbers always add up.
  static bool showDiscount(Booking b, {bool? enabled}) => (enabled ?? AppClientConfig.enableDiscount) && b.discount > 0;

  /// WhatsApp message (*bold* is WhatsApp markdown).
  static String whatsApp(Booking b, {required String currency, bool? discountEnabled}) {
    String m(int v) => ArenaFormat.money(v, symbol: currency);
    final emoji = b.sport.emoji;
    final itemise = showDiscount(b, enabled: discountEnabled);
    return [
      '$emoji *ARENABOOK GROUND RECEIPT*',
      '---------------------------------------',
      '*Ref ID:* #${b.id}',
      '*Customer:* ${b.customerName}',
      '*Court:* ${b.court.name}',
      '*Date:* ${ArenaFormat.longDate(b.date)}',
      '*Slots:* ${b.slotsLabel}',
      '',
      if (itemise) ...['*Ground Fee:* ${m(b.totalFee)}', '*Discount:* -${m(b.discount)}'],
      '*Total Fee:* ${m(b.payable)}',
      '*Advance Paid:* ${m(b.advancePaid)}',
      if (b.balanceSettledAt != null && !b.isCancelled) '*Balance Paid:* ${m(b.payable - b.advancePaid)}',
      '*Balance Due:* ${m(b.balanceDue)}',
      '*Status:* ${statusLabel(b)}',
      if (b.isCancelled) '*Cancellation:* ${b.cancelReason} (advance ${b.advanceReturned ? 'returned' : 'not refunded'})',
      '',
      b.isCancelled ? 'This booking has been cancelled.' : 'Thank you for playing at ArenaBook grounds! Present this receipt at entry.',
    ].join('\n');
  }

  static String plain(Booking b, {required String currency, bool? discountEnabled}) {
    String m(int v) => ArenaFormat.money(v, symbol: currency);
    final discount = showDiscount(b, enabled: discountEnabled) ? ' (after ${m(b.discount)} discount)' : '';
    return 'ARENABOOK INVOICE #${b.id} (${statusLabel(b)})\n'
        'Customer: ${b.customerName} (${b.phone})\n'
        'Court: ${b.court.name}\n'
        'Date: ${ArenaFormat.longDate(b.date)} (${b.slotsLabel})\n'
        'Total: ${m(b.payable)}$discount | Paid: ${m(b.amountCollected)} | Due: ${m(b.balanceDue)}';
  }

  /// QR payload: enough to look the booking up at the gate.
  static String qrData(Booking b) => 'ARENABOOK|${b.id}|${dateKey(b.date)}|${b.courtId}|${b.slots.map((s) => '${s.startMinute}-${s.endMinute}').join(',')}';
}
