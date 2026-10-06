import 'package:flutter_test/flutter_test.dart';

import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/sport.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/rules/booking_rules.dart';
import 'package:arenabook/data/rules/booking_stats.dart';

Booking booking({
  String id = 'TRF-1001',
  String courtId = 'cricket-1',
  Sport sport = Sport.cricket,
  DateTime? date,
  List<TimeRange>? slots,
  int totalFee = 1500,
  int discount = 0,
  int advancePaid = 500,
  DateTime? settledAt,
  DateTime? cancelledAt,
  bool advanceReturned = false,
}) {
  final created = DateTime(2026, 10, 1, 8);
  return Booking(
    id: id,
    customerName: 'Zain Malik',
    phone: '03001234567',
    sport: sport,
    courtId: courtId,
    date: date ?? DateTime(2026, 10, 1),
    slots: slots ?? [TimeRange.hour(20)],
    hourlyRate: 1500,
    totalFee: totalFee,
    discount: discount,
    advancePaid: advancePaid,
    balanceSettledAt: settledAt,
    cancelledAt: cancelledAt,
    advanceReturned: advanceReturned,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  group('TimeRange', () {
    test('overlap uses real time, not labels', () {
      const custom = TimeRange(20 * 60 + 30, 21 * 60 + 30); // 8:30PM - 9:30PM
      expect(custom.overlaps(TimeRange.hour(20)), isTrue);
      expect(custom.overlaps(TimeRange.hour(21)), isTrue);
      expect(custom.overlaps(TimeRange.hour(22)), isFalse);
    });

    test('touching ranges do not overlap', () {
      expect(TimeRange.hour(9).overlaps(TimeRange.hour(10)), isFalse);
    });

    test('concise labels', () {
      expect(TimeRange.hour(9).label, '9AM - 10AM');
      expect(TimeRange.hour(11).label, '11AM - 12PM');
      expect(TimeRange.hour(23).label, '11PM - 12AM');
      expect(const TimeRange(13 * 60 + 30, 14 * 60 + 30).label, '1:30PM - 2:30PM');
    });

    test('tryCreate rejects invalid ranges', () {
      expect(TimeRange.tryCreate(600, 600), isNull);
      expect(TimeRange.tryCreate(700, 600), isNull);
      expect(TimeRange.tryCreate(-1, 60), isNull);
      expect(TimeRange.tryCreate(0, 1440), isNotNull);
      expect(TimeRange.tryCreate(1380, 1500), isNotNull); // 11PM - 1AM next day
      expect(TimeRange.tryCreate(0, TimeRange.maxMinute + 1), isNull);
    });

    test('next-day label and shifting between days', () {
      const late = TimeRange(23 * 60, 25 * 60);
      expect(late.label, '11PM - 1AM (next day)');
      expect(late.endsNextDay, isTrue);
      expect(late.shift(1), const TimeRange(0, 60)); // seen from the next day: 12-1 AM
      expect(TimeRange.hour(20).shift(1), isNull); // ends before midnight: nothing the next day
      expect(TimeRange.hour(0).shift(-1), const TimeRange(1440, 1500)); // seen from the previous day
    });
  });

  group('Booking money', () {
    test('fee is rounded to whole rupees', () {
      expect(Booking.feeFor(60, 1500), 1500);
      expect(Booking.feeFor(90, 1500), 2250);
      expect(Booking.feeFor(50, 1000), 833); // 833.33
    });

    test('pending booking', () {
      final b = booking();
      expect(b.status, BookingStatus.pending);
      expect(b.balanceDue, 1000);
      expect(b.amountCollected, 500);
    });

    test('mark paid keeps the original advance', () {
      final b = booking().settle(DateTime(2026, 10, 1, 21));
      expect(b.status, BookingStatus.paid);
      expect(b.balanceDue, 0);
      expect(b.amountCollected, 1500);
      expect(b.advancePaid, 500); // the prototype overwrote this
    });

    test('cancelled booking: returned advance is not collected', () {
      final now = DateTime(2026, 10, 1, 10);
      expect(booking().cancel(reason: 'rain', advanceReturned: true, now: now).amountCollected, 0);
      expect(booking().cancel(reason: 'rain', advanceReturned: false, now: now).amountCollected, 500);
      expect(booking().cancel(reason: 'rain', advanceReturned: false, now: now).balanceDue, 0);
    });

    test('editable only when active and today or later', () {
      final now = DateTime(2026, 10, 1, 23, 30);
      expect(booking().canEdit(now), isTrue);
      expect(booking(date: DateTime(2026, 9, 30)).canEdit(now), isFalse);
      expect(booking(cancelledAt: now).canEdit(now), isFalse);
    });
  });

  group('Booking JSON', () {
    test('round trip keeps every field', () {
      final original = booking(slots: [const TimeRange(810, 870), TimeRange.hour(20)], settledAt: DateTime(2026, 10, 1, 22));
      final copy = Booking.fromJson(original.toJson());
      expect(copy.toJson(), original.toJson());
    });

    test('date key is local, never shifted by UTC', () {
      final justAfterMidnight = DateTime(2026, 10, 2, 0, 30);
      expect(dateKey(justAfterMidnight), '2026-10-02');
      expect(parseDateKey('2026-10-02'), DateTime(2026, 10, 2));
    });

    test('corrupt record throws FormatException', () {
      final json = booking().toJson()..['slots'] = [];
      expect(() => Booking.fromJson(json), throwsFormatException);
    });
  });

  group('Slot availability', () {
    final day = DateTime(2026, 10, 1);

    test('cancelled bookings free their slots', () {
      final list = [
        booking(),
        booking(id: 'TRF-1002', slots: [TimeRange.hour(18)], cancelledAt: day),
      ];
      expect(BookingRules.occupied(list, date: day, courtId: 'cricket-1'), [TimeRange.hour(20)]);
    });

    test('other courts and far days are ignored, edited booking excluded', () {
      final list = [booking(), booking(id: 'TRF-1002', courtId: 'cricket-2'), booking(id: 'TRF-1003', date: DateTime(2026, 10, 3))];
      expect(BookingRules.occupied(list, date: day, courtId: 'cricket-1'), [TimeRange.hour(20)]);
      expect(BookingRules.occupied(list, date: day, courtId: 'cricket-1', excludeBookingId: 'TRF-1001'), isEmpty);
    });

    test("the next day's bookings count, on this day's timeline (a late booking could reach them)", () {
      final tomorrow = booking(id: 'TRF-1003', date: DateTime(2026, 10, 2)); // 8-9 PM tomorrow
      expect(BookingRules.occupied([tomorrow], date: day, courtId: 'cricket-1'), [const TimeRange(20 * 60 + 1440, 21 * 60 + 1440)]);
    });

    test('30-minute cell states', () {
      final now = DateTime(2026, 10, 1, 9, 5);
      final occupied = [const TimeRange(20 * 60 + 30, 21 * 60 + 30)]; // 8:30-9:30 PM
      SlotState state(int minute) => BookingRules.cellState(minute, date: day, now: now, occupied: occupied);

      expect(state(9 * 60), SlotState.past); // started at 9:00
      expect(state(9 * 60 + 30), SlotState.available);
      expect(state(20 * 60), SlotState.available); // 8:00-8:30 is free
      expect(state(20 * 60 + 30), SlotState.booked);
      expect(state(21 * 60), SlotState.booked);
      expect(state(21 * 60 + 30), SlotState.available);
      expect(state(0), SlotState.past); // midnight-to-6AM is bookable on future days (see next test)
    });

    test('max duration stops at the next booking (or 24 h)', () {
      final occupied = [const TimeRange(20 * 60 + 30, 21 * 60 + 30)];
      expect(BookingRules.maxDuration(19 * 60, occupied: occupied), 90); // 7:00 -> 8:30
      expect(BookingRules.maxDuration(20 * 60 + 30, occupied: occupied), 0); // taken
      expect(BookingRules.maxDuration(21 * 60 + 30, occupied: occupied), 24 * 60); // free: may run past midnight, 24 h max
      expect(BookingRules.maxDuration(0, occupied: const []), TimeRange.minutesPerDay);
    });

    test('day parts cover the whole day in 30-minute starts', () {
      expect(DayPart.values.expand((p) => p.starts).length, 48);
      expect(DayPart.evening.starts.first, 18 * 60);
      expect(DayPart.evening.starts.last, 23 * 60 + 30);
      expect(DayPart.of(0), DayPart.night);
      expect(DayPart.of(5 * 60 + 59), DayPart.night);
      expect(DayPart.of(6 * 60), DayPart.morning);
      expect(DayPart.of(23 * 60 + 59), DayPart.evening);
    });

    test('future days have no past slots', () {
      expect(BookingRules.isPast(TimeRange.hour(9), DateTime(2026, 10, 2), DateTime(2026, 10, 1, 23)), isFalse);
    });

    test('validateSlots', () {
      final now = DateTime(2026, 10, 1, 12);
      final occupied = [TimeRange.hour(20)];
      String? check(List<TimeRange> slots, {Set<TimeRange> keep = const {}}) =>
          BookingRules.validateSlots(slots, date: day, now: now, occupied: occupied, keepPastSlots: keep);

      expect(check([]), isNotNull);
      expect(check([TimeRange.hour(14)]), isNull);
      expect(check([TimeRange.hour(10)]), contains('already started'));
      expect(check([TimeRange.hour(10)], keep: {TimeRange.hour(10)}), isNull);
      expect(check([const TimeRange(19 * 60 + 30, 20 * 60 + 30)]), contains('clashes'));
      expect(check([TimeRange.hour(14), const TimeRange(14 * 60 + 30, 15 * 60 + 30)]), contains('overlap'));
    });
  });

  group('Customer input', () {
    test('phone', () {
      expect(BookingRules.validatePhone(''), isNotNull);
      expect(BookingRules.validatePhone('0300123'), isNotNull);
      expect(BookingRules.validatePhone('03001234567'), isNull);
      expect(BookingRules.validatePhone('030012345678'), isNotNull);
    });

    test('email is optional but must be valid when given', () {
      expect(BookingRules.validateEmail(''), isNull);
      expect(BookingRules.validateEmail('zain@example.com'), isNull);
      expect(BookingRules.validateEmail('zain@'), isNotNull);
    });

    test('WhatsApp number is international', () {
      expect(BookingRules.toWhatsAppNumber('03001234567'), '923001234567');
      expect(BookingRules.toWhatsAppNumber('923001234567'), '923001234567');
      expect(BookingRules.toWhatsAppNumber('00923001234567'), '923001234567');
      expect(BookingRules.toWhatsAppNumber(''), '');
    });

    test('advance is clamped to the fee', () {
      expect(BookingRules.clampAdvance(5000, 1500), 1500);
      expect(BookingRules.clampAdvance(-5, 1500), 0);
    });
  });

  group('BookingStats', () {
    test('excludes cancelled and filters by sport', () {
      final day = DateTime(2026, 10, 1);
      final list = [
        booking(),
        booking(id: 'TRF-1002', sport: Sport.padel, courtId: 'padel-a', totalFee: 2000, advancePaid: 2000),
        booking(id: 'TRF-1003', cancelledAt: day),
      ];
      final all = BookingStats.from(list);
      expect(all.totalBookings, 2);
      expect(all.totalValue, 3500);
      expect(all.collectedAmount, 2500);
      expect(all.pendingAmount, 1000);
      expect(all.pendingCount, 1);

      final padel = BookingStats.from(list, sport: Sport.padel);
      expect(padel.totalBookings, 1);
      expect(padel.pendingAmount, 0);
    });

    test('total value is revenue after discount', () {
      expect(BookingStats.from([booking(discount: 200)]).totalValue, 1300);
    });
  });

  group('Discount', () {
    final now = DateTime(2026, 10, 1, 21);

    test('payable, balance and paid status use the discounted price', () {
      final b = booking(totalFee: 1500, discount: 200, advancePaid: 500);
      expect(b.payable, 1300);
      expect(b.balanceDue, 800);
      expect(b.status, BookingStatus.pending);
      expect(booking(discount: 200, advancePaid: 1300).status, BookingStatus.paid); // advance covers payable
    });

    test('mark paid collects the payable amount, not the full fee', () {
      final b = booking(discount: 200).settle(now);
      expect(b.amountCollected, 1300);
      expect(b.balanceDue, 0);
    });

    test('100% discount: nothing to pay', () {
      final b = booking(totalFee: 1500, discount: 1500, advancePaid: 0);
      expect(b.payable, 0);
      expect(b.balanceDue, 0);
      expect(b.status, BookingStatus.paid);
    });

    test('JSON keeps the discount; v1 records without it load as 0', () {
      expect(Booking.fromJson(booking(discount: 250).toJson()).discount, 250);
      final v1 = booking().toJson()..remove('discount');
      expect(Booking.fromJson(v1).discount, 0);
    });

    test('validate and clamp', () {
      expect(BookingRules.validateDiscount(0, 1500), isNull);
      expect(BookingRules.validateDiscount(1500, 1500), isNull);
      expect(BookingRules.validateDiscount(1501, 1500), isNotNull);
      expect(BookingRules.validateDiscount(-1, 1500), isNotNull);
      expect(BookingRules.clampDiscount(9999, 1500), 1500);
      expect(BookingRules.clampDiscount(-5, 1500), 0);
    });
  });

  group('Past midnight', () {
    final sat = DateTime(2026, 10, 3), sun = DateTime(2026, 10, 4);
    final now = DateTime(2026, 10, 3, 12);
    final lateSat = booking(id: 'TRF-1001', date: sat, slots: [const TimeRange(23 * 60, 25 * 60)]); // Sat 11PM - Sun 1AM

    test("a Saturday 11PM-1AM booking blocks Sunday's 12-1AM", () {
      expect(BookingRules.occupied([lateSat], date: sun, courtId: 'cricket-1'), [const TimeRange(0, 60)]);
      expect(BookingRules.cellState(0, date: sun, now: now, occupied: [const TimeRange(0, 60)]), SlotState.booked);
      expect(BookingRules.cellState(60, date: sun, now: now, occupied: [const TimeRange(0, 60)]), SlotState.available);
    });

    test("Sunday's early booking limits a Saturday late booking", () {
      final earlySun = booking(id: 'TRF-1002', date: sun, slots: [const TimeRange(30, 90)]); // Sun 12:30-1:30AM
      final seenFromSat = BookingRules.occupied([earlySun], date: sat, courtId: 'cricket-1');
      expect(seenFromSat, [const TimeRange(1470, 1530)]);
      expect(BookingRules.maxDuration(23 * 60, occupied: seenFromSat), 90); // 11PM -> 12:30AM
      expect(BookingRules.validateSlots([const TimeRange(23 * 60, 25 * 60)], date: sat, now: now, occupied: seenFromSat), contains('clashes'));
      expect(BookingRules.validateSlots([const TimeRange(23 * 60, 24 * 60 + 30)], date: sat, now: now, occupied: seenFromSat), isNull);
    });

    test('bookings two days away and other courts are ignored', () {
      expect(BookingRules.occupied([lateSat], date: DateTime(2026, 10, 5), courtId: 'cricket-1'), isEmpty);
      expect(BookingRules.occupied([lateSat], date: sun, courtId: 'cricket-2'), isEmpty);
    });

    test('limits: 24 hours max, must start on the booking date', () {
      expect(BookingRules.maxDuration(23 * 60, occupied: const []), 24 * 60);
      expect(BookingRules.validateSlots([const TimeRange(1440, 1500)], date: sat, now: now, occupied: const []), contains('start on'));
    });

    test('fee and JSON work past midnight', () {
      expect(lateSat.totalMinutes, 120);
      expect(Booking.fromJson(lateSat.toJson()).slots.single, const TimeRange(1380, 1500));
    });
  });
}
