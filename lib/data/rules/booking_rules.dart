import 'dart:math' as math;

import '../../app/config/app_client_config.dart';
import '../models/booking.dart';
import '../models/booking_policy.dart';
import '../models/pricing.dart';
import '../models/time_range.dart';

enum SlotState { available, selected, booked, past }

/// The day in four 6-hour blocks; the form shows one block's start times at a time.
enum DayPart {
  night('Night', 0),
  morning('Morning', 6 * 60),
  afternoon('Afternoon', 12 * 60),
  evening('Evening', 18 * 60);

  const DayPart(this.label, this.startMinute);

  final String label;
  final int startMinute;
  int get endMinute => startMinute + 6 * 60;

  /// The period's start times, every [step] minutes.
  List<int> starts(int step) => [for (var m = startMinute; m < endMinute; m += step) m];

  static DayPart of(int minute) => values.lastWhere((p) => minute >= p.startMinute, orElse: () => night);
}

/// Pure booking rules (no Flutter, no GetX), so every rule is unit tested in test/booking_rules_test.dart.
/// Time rules follow a [BookingPolicy]: the client's ([AppClientConfig.policy]) unless one is passed in.
class BookingRules {
  BookingRules._();

  static const maxNotesLength = 120;
  static const maxPhoneLength = 11;
  static const minPhoneLength = 10;

  /// Ranges already taken on [resourceId] for [date], in that day's minutes (cancelled bookings free their slots).
  /// Includes the previous day's bookings that run past midnight and the next day's, so late-night
  /// bookings conflict correctly from either date. [excludeBookingId] is the booking being edited.
  static List<TimeRange> occupied(Iterable<Booking> bookings, {required DateTime date, required String resourceId, String? excludeBookingId}) {
    final day = dateOnly(date);
    final result = <TimeRange>[];
    for (final b in bookings) {
      if (b.isCancelled || b.resourceId != resourceId || b.id == excludeBookingId) continue;
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

  /// Start times in [part] where a booking can begin: on a step and inside opening hours.
  static List<int> startsIn(DayPart part, {BookingPolicy? policy}) {
    final p = policy ?? AppClientConfig.policy;
    return part.starts(p.step).where(p.canStartAt).toList();
  }

  /// State of the one-step cell starting at [start] (selection is layered on by the form).
  /// A free start with no room for the shortest booking (next booking or closing too close) counts as booked.
  static SlotState cellState(int start, {required DateTime date, required DateTime now, required List<TimeRange> occupied, BookingPolicy? policy}) {
    final p = policy ?? AppClientConfig.policy;
    final cell = TimeRange(start, start + p.step);
    if (occupied.any(cell.overlaps)) return SlotState.booked;
    if (isPast(cell, date, now)) return SlotState.past;
    if (maxDuration(start, occupied: occupied, policy: p) < p.minDuration) return SlotState.booked;
    return SlotState.available;
  }

  /// State of a fixed session on [date]: booked when any part of it is taken, past once it has started.
  static SlotState sessionState(BookingSession session, {required DateTime date, required DateTime now, required List<TimeRange> occupied}) {
    if (occupied.any(session.time.overlaps)) return SlotState.booked;
    if (isPast(session.time, date, now)) return SlotState.past;
    return SlotState.available;
  }

  /// Longest booking from [start] before the next booking, closing time or the policy's maximum, in whole steps; 0 when taken.
  static int maxDuration(int start, {required List<TimeRange> occupied, BookingPolicy? policy}) {
    final p = policy ?? AppClientConfig.policy;
    final closes = p.closingFor(start);
    if (closes == null) return 0;
    var limit = math.min(math.min(start + p.maxDuration, closes), TimeRange.maxMinute);
    for (final r in occupied) {
      if (r.endMinute <= start) continue;
      if (r.startMinute <= start) return 0;
      if (r.startMinute < limit) limit = r.startMinute;
    }
    return (limit - start) ~/ p.step * p.step; // an off-step neighbour (older booking) must not leave an off-step duration
  }

  /// Returns a user-facing error, or null when [slots] can be booked.
  /// [keepPastSlots] are slots the edited booking already had: keeping them must not fail because they started,
  /// or because the policy changed since they were booked.
  static String? validateSlots(
    List<TimeRange> slots, {
    required DateTime date,
    required DateTime now,
    required List<TimeRange> occupied,
    Set<TimeRange> keepPastSlots = const {},
    BookingPolicy? policy,
  }) {
    final p = policy ?? AppClientConfig.policy;
    if (slots.isEmpty) return 'Please select at least 1 time slot';
    final sorted = [...slots]..sort();
    for (var i = 0; i < sorted.length; i++) {
      final slot = sorted[i];
      final kept = keepPastSlots.contains(slot);
      if (i > 0 && sorted[i - 1].overlaps(slot)) return 'Selected time slots overlap each other';
      if (slot.startMinute >= TimeRange.minutesPerDay) return 'A booking must start on its booking date';
      if (slot.durationMinutes > TimeRange.minutesPerDay) return 'A booking can be at most 24 hours';
      final broken = kept ? null : policyError(slot, p);
      if (broken != null) return broken;
      if (isPast(slot, date, now) && !kept) return '${slot.label} has already started';
      final clash = occupied.where(slot.overlaps).firstOrNull;
      if (clash != null) return '${slot.label} clashes with an existing booking (${clash.label})';
    }
    return null;
  }

  /// Why [slot] breaks [policy] (steps, length, opening hours, sessions), or null.
  static String? policyError(TimeRange slot, BookingPolicy policy) {
    if (policy.usesSessions) return policy.sessions.any((s) => s.time == slot) ? null : 'Please pick one of the sessions';
    if (slot.startMinute % policy.step != 0 || slot.durationMinutes % policy.step != 0) return 'Times move in ${policy.step}-minute steps';
    if (slot.durationMinutes < policy.minDuration) return 'A booking must be at least ${durationLabel(policy.minDuration)}';
    if (slot.durationMinutes > policy.maxDuration) return 'A booking can be at most ${durationLabel(policy.maxDuration)}';
    if (!policy.isOpenFor(slot)) return '${slot.label} is outside opening hours (${policy.openHours!.label})';
    return null;
  }

  /// "1 h 30 m", "2 h", "45 m".
  static String durationLabel(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    return [if (h > 0) '$h h', if (m > 0) '$m m'].join(' ');
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
  /// [countryCode] defaults to the client's.
  static String toWhatsAppNumber(String phone, {String? countryCode}) {
    final code = countryCode ?? AppClientConfig.client.countryCode;
    final digits = digitsOnly(phone);
    if (digits.isEmpty) return '';
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith(code) && digits.length > 10) return digits;
    if (digits.startsWith('0')) return '$code${digits.substring(1)}';
    return '$code$digits';
  }

  /// Advance is clamped to 0..[totalFee] (the prototype allowed paying more than the fee).
  static int clampAdvance(int advance, int totalFee) => advance.clamp(0, totalFee < 0 ? 0 : totalFee);

  /// Discount is clamped to 0..[totalFee]: it can never make a booking negative.
  static int clampDiscount(int discount, int totalFee) => clampAdvance(discount, totalFee);

  /// Hourly needs a rate above 0 (a 0 rate would silently create free bookings); manual needs a typed price above 0.
  static String? validatePrice(PricingMode pricing, {required int hourlyRate, required int price}) => switch (pricing) {
    PricingMode.hourly => hourlyRate <= 0 ? 'Hourly rate must be greater than 0' : null,
    PricingMode.manual => price <= 0 ? 'Please enter the ${AppClientConfig.terms.fee.toLowerCase()}' : null,
  };

  static String? validateDiscount(int discount, int totalFee) {
    if (discount < 0) return 'Discount cannot be negative';
    if (discount > totalFee) return 'Discount cannot be more than the ${AppClientConfig.terms.fee.toLowerCase()}';
    return null;
  }
}
