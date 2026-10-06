import '../models/booking.dart';
import '../models/time_range.dart';

enum SlotState { available, selected, booked, past }

/// Pure booking rules (no Flutter, no GetX), so every rule is unit tested in test/booking_rules_test.dart.
class BookingRules {
  BookingRules._();

  /// Hourly preset slots shown in the form: 9AM-10AM ... 10PM-11PM.
  static final presetSlots = List<TimeRange>.unmodifiable([for (var h = 9; h <= 22; h++) TimeRange.hour(h)]);

  static const maxNotesLength = 120;
  static const maxPhoneLength = 11;
  static const minPhoneLength = 10;

  /// Ranges already taken on [courtId] for [date] (cancelled bookings free their slots).
  /// [excludeBookingId] is the booking being edited, so it doesn't conflict with itself.
  static List<TimeRange> occupied(Iterable<Booking> bookings, {required DateTime date, required String courtId, String? excludeBookingId}) {
    return [
      for (final b in bookings)
        if (!b.isCancelled && b.courtId == courtId && isSameDay(b.date, date) && b.id != excludeBookingId) ...b.slots,
    ]..sort();
  }

  /// A slot is past once it has started (at 9:00 or 9:05, the 9AM slot can no longer be booked).
  static bool isPast(TimeRange slot, DateTime date, DateTime now) => !slot.startOn(date).isAfter(now);

  static SlotState stateOf(
    TimeRange slot, {
    required DateTime date,
    required DateTime now,
    required List<TimeRange> occupied,
    required Set<TimeRange> selected,
  }) {
    if (selected.contains(slot)) return SlotState.selected;
    if (occupied.any(slot.overlaps)) return SlotState.booked;
    if (isPast(slot, date, now)) return SlotState.past;
    return SlotState.available;
  }

  /// Returns a user-facing error, or null when [slots] can be booked.
  /// [keepPastSlots] are slots the edited booking already had: keeping them must not fail just because they started.
  static String? validateSlots(
    List<TimeRange> slots, {
    required DateTime date,
    required DateTime now,
    required List<TimeRange> occupied,
    Set<TimeRange> keepPastSlots = const {},
  }) {
    if (slots.isEmpty) return 'Please select at least 1 time slot';
    final sorted = [...slots]..sort();
    for (var i = 0; i < sorted.length; i++) {
      final slot = sorted[i];
      if (i > 0 && sorted[i - 1].overlaps(slot)) return 'Selected time slots overlap each other';
      if (isPast(slot, date, now) && !keepPastSlots.contains(slot)) return '${slot.label} has already started';
      final clash = occupied.where(slot.overlaps).firstOrNull;
      if (clash != null) return '${slot.label} clashes with an existing booking (${clash.label})';
    }
    return null;
  }

  // ─────────────── Customer input ───────────────

  static String digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  static String? validateName(String name) => name.trim().isEmpty ? 'Please enter customer full name' : null;

  static String? validatePhone(String phone) {
    final digits = digitsOnly(phone);
    if (digits.isEmpty) return 'Please enter customer phone number';
    if (digits.length < minPhoneLength || digits.length > maxPhoneLength) {
      return 'Phone number must be $minPhoneLength-$maxPhoneLength digits';
    }
    return null;
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String email) => email.trim().isEmpty || _emailPattern.hasMatch(email.trim()) ? null : 'Please enter a valid email';

  /// wa.me needs the international number without '+' or the local leading 0: 03001234567 -> 923001234567.
  static String toWhatsAppNumber(String phone, {String countryCode = '92'}) {
    final digits = digitsOnly(phone);
    if (digits.isEmpty) return '';
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith(countryCode) && digits.length > 10) return digits;
    if (digits.startsWith('0')) return '$countryCode${digits.substring(1)}';
    return '$countryCode$digits';
  }

  /// Advance is clamped to 0..[totalFee] (the prototype allowed paying more than the fee).
  static int clampAdvance(int advance, int totalFee) => advance.clamp(0, totalFee < 0 ? 0 : totalFee);

  static int advanceForPercent(int totalFee, int percent) => (totalFee * percent / 100).round();

  /// Discount is clamped to 0..[totalFee]: it can never make a booking negative.
  static int clampDiscount(int discount, int totalFee) => clampAdvance(discount, totalFee);

  static String? validateDiscount(int discount, int totalFee) {
    if (discount < 0) return 'Discount cannot be negative';
    if (discount > totalFee) return 'Discount cannot be more than the ground fee';
    return null;
  }
}
