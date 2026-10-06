import 'dart:math' as math;

import '../models/booking.dart';
import '../models/time_range.dart';

enum SlotState { available, selected, booked, past }

/// The day in four 6-hour blocks; the form shows one block's 12 start times at a time.
enum DayPart {
  night('Night', 0),
  morning('Morning', 6 * 60),
  afternoon('Afternoon', 12 * 60),
  evening('Evening', 18 * 60);

  const DayPart(this.label, this.startMinute);

  final String label;
  final int startMinute;
  int get endMinute => startMinute + 6 * 60;

  /// The period's start times, every [BookingRules.slotStep] minutes.
  List<int> get starts => [for (var m = startMinute; m < endMinute; m += BookingRules.slotStep) m];

  static DayPart of(int minute) => values.lastWhere((p) => minute >= p.startMinute, orElse: () => night);
}

/// Pure booking rules (no Flutter, no GetX), so every rule is unit tested in test/booking_rules_test.dart.
class BookingRules {
  BookingRules._();

  /// Booking granularity: starts and durations move in 30-minute steps.
  static const slotStep = 30;

  static const maxNotesLength = 120;
  static const maxPhoneLength = 11;
  static const minPhoneLength = 10;

  /// Ranges already taken on [courtId] for [date], in that day's minutes (cancelled bookings free their slots).
  /// Includes the previous day's bookings that run past midnight and the next day's, so late-night
  /// bookings conflict correctly from either date. [excludeBookingId] is the booking being edited.
  static List<TimeRange> occupied(Iterable<Booking> bookings, {required DateTime date, required String courtId, String? excludeBookingId}) {
    final day = dateOnly(date);
    final result = <TimeRange>[];
    for (final b in bookings) {
      if (b.isCancelled || b.courtId != courtId || b.id == excludeBookingId) continue;
      final offset = DateTime.utc(b.date.year, b.date.month, b.date.day).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
      if (offset.abs() > 1) continue;
      for (final s in b.slots) {
        final seen = s.shift(-offset); // move the slot onto this day's timeline
        if (seen != null) result.add(seen);
      }
    }
    return result..sort();
  }

  /// A slot is past once it has started (at 9:00 or 9:05, the 9AM slot can no longer be booked).
  static bool isPast(TimeRange slot, DateTime date, DateTime now) => !slot.startOn(date).isAfter(now);

  /// State of the 30-minute cell starting at [start] (selection is layered on by the form).
  static SlotState cellState(int start, {required DateTime date, required DateTime now, required List<TimeRange> occupied}) {
    final cell = TimeRange(start, start + slotStep);
    if (occupied.any(cell.overlaps)) return SlotState.booked;
    if (isPast(cell, date, now)) return SlotState.past;
    return SlotState.available;
  }

  /// Longest booking from [start] (24 h max, may run past midnight) before the next booking; 0 when taken.
  static int maxDuration(int start, {required List<TimeRange> occupied}) {
    var limit = math.min(start + TimeRange.minutesPerDay, TimeRange.maxMinute);
    for (final r in occupied) {
      if (r.endMinute <= start) continue;
      if (r.startMinute <= start) return 0;
      if (r.startMinute < limit) limit = r.startMinute;
    }
    return limit - start;
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
      if (slot.startMinute >= TimeRange.minutesPerDay) return 'A booking must start on its booking date';
      if (slot.durationMinutes > TimeRange.minutesPerDay) return 'A booking can be at most 24 hours';
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

  /// Discount is clamped to 0..[totalFee]: it can never make a booking negative.
  static int clampDiscount(int discount, int totalFee) => clampAdvance(discount, totalFee);

  static String? validateDiscount(int discount, int totalFee) {
    if (discount < 0) return 'Discount cannot be negative';
    if (discount > totalFee) return 'Discount cannot be more than the ground fee';
    return null;
  }
}
