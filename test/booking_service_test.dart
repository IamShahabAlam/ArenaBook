import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/temp_dir.dart';
import 'package:hive_ce/hive.dart';

import 'package:arenabook/app/service/getx_service/booking_service.dart';
import 'package:arenabook/data/models/sport.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/repositories/booking/booking_repository.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);

  BookingDraft draft({
    List<TimeRange>? slots,
    int advance = 500,
    int discount = 0,
    String courtId = 'cricket-1',
    DateTime? date,
    String phone = '03001234567',
  }) => BookingDraft(
    customerName: '  Zain Malik ',
    phone: phone,
    sport: Sport.cricket,
    courtId: courtId,
    date: date ?? DateTime(2026, 10, 1),
    slots: slots ?? [TimeRange.hour(20)],
    hourlyRate: 1500,
    discount: discount,
    advancePaid: advance,
  );

  Future<BookingService> service([BookingRepository? repo]) => BookingService(repo ?? InMemoryBookingRepository(), clock: () => now).init();

  group('BookingService', () {
    test('create assigns sequential ids, fee and trims input', () async {
      final s = await service();
      final a = await s.create(draft());
      final b = await s.create(draft(slots: [TimeRange.hour(21)]));
      expect(a.id, 'TRF-1001');
      expect(b.id, 'TRF-1002');
      expect(a.customerName, 'Zain Malik');
      expect(a.totalFee, 1500);
      expect(s.bookings.length, 2);
    });

    test('late-night booking past midnight blocks the next day, both ways', () async {
      final s = await service();
      final sat = DateTime(2026, 10, 3), sun = DateTime(2026, 10, 4);
      final late = await s.create(draft(date: sat, slots: [const TimeRange(23 * 60, 25 * 60)])); // 11PM - 1AM
      expect(late.totalFee, 3000);
      expect(late.slotsLabel, '11PM - 1AM (next day)');
      // Sunday 12:30AM is taken by Saturday's booking...
      expect(() => s.create(draft(date: sun, slots: [const TimeRange(30, 90)])), throwsA(isA<BookingException>()));
      // ...but 1AM onwards is free.
      expect((await s.create(draft(date: sun, slots: [TimeRange.hour(1)]))).id, 'TRF-1002');
      // And a Sunday early booking stops a new Saturday late one on another court only where they meet.
      await s.create(draft(date: sun, courtId: 'cricket-2', slots: [const TimeRange(0, 60)]));
      expect(() => s.create(draft(date: sat, courtId: 'cricket-2', slots: [const TimeRange(23 * 60, 25 * 60)])), throwsA(isA<BookingException>()));
    });

    test('rejects double booking, including custom ranges', () async {
      final s = await service();
      await s.create(draft());
      expect(() => s.create(draft()), throwsA(isA<BookingException>()));
      expect(() => s.create(draft(slots: [const TimeRange(20 * 60 + 30, 21 * 60 + 30)])), throwsA(isA<BookingException>()));
      // a different court is fine
      expect((await s.create(draft(courtId: 'cricket-2'))).id, 'TRF-1002');
    });

    test('rejects past slots and bad phone', () async {
      final s = await service();
      expect(() => s.create(draft(slots: [TimeRange.hour(10)])), throwsA(isA<BookingException>()));
      expect(() => s.create(draft(phone: '123')), throwsA(isA<BookingException>()));
    });

    test('advance is clamped to the fee', () async {
      final s = await service();
      final b = await s.create(draft(advance: 99999));
      expect(b.advancePaid, 1500);
      expect(b.balanceDue, 0);
    });

    test('edit does not conflict with itself and keeps id', () async {
      final s = await service();
      final a = await s.create(draft());
      final edited = await s.update(a.id, draft(slots: [TimeRange.hour(20), TimeRange.hour(21)]));
      expect(edited.id, a.id);
      expect(edited.totalFee, 3000);
      expect(s.bookings.length, 1);
    });

    test('cancel frees the slot and requires a reason', () async {
      final s = await service();
      final a = await s.create(draft());
      expect(() => s.cancel(a.id, reason: ' ', advanceReturned: true), throwsA(isA<BookingException>()));
      await s.cancel(a.id, reason: 'Rain', advanceReturned: true);
      expect((await s.create(draft())).id, 'TRF-1002');
    });

    test('mark paid settles the balance', () async {
      final s = await service();
      final a = await s.create(draft());
      final paid = await s.markPaid(a.id);
      expect(paid.balanceDue, 0);
      expect(paid.advancePaid, 500);
      expect(() => s.markPaid('TRF-9999'), throwsA(isA<BookingException>()));
    });

    test('discount: saved, capped advance, rejected when above the fee', () async {
      final s = await service();
      final b = await s.create(draft(discount: 300, advance: 99999));
      expect(b.discount, 300);
      expect(b.advancePaid, 1200); // capped to payable, not to the 1500 fee
      expect(b.balanceDue, 0);
      expect(() => s.create(draft(slots: [TimeRange.hour(21)], discount: 1600)), throwsA(isA<BookingException>()));
    });

    test('editing can change the discount', () async {
      final s = await service();
      final a = await s.create(draft(discount: 100));
      final edited = await s.update(a.id, draft(discount: 0));
      expect(edited.discount, 0);
      expect(edited.balanceDue, 1000);
    });
  });

  group('HiveBookingRepository', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('arenabook_test');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await deleteTempDir(dir);
    });

    test('persists bookings and the id counter across restarts', () async {
      final s1 = await service(await HiveBookingRepository.open());
      await s1.create(draft());
      await s1.create(draft(slots: [TimeRange.hour(21)]));
      await Hive.close();

      Hive.init(dir.path);
      final s2 = await service(await HiveBookingRepository.open());
      expect(s2.bookings.map((b) => b.id), ['TRF-1001', 'TRF-1002']);
      expect((await s2.create(draft(slots: [TimeRange.hour(22)]))).id, 'TRF-1003');
    });

    test('skips a corrupt record instead of crashing', () async {
      final repo = await HiveBookingRepository.open();
      await Hive.box<Map>(HiveBookingRepository.bookingsBoxName).put('bad', {'id': 'bad'});
      final s = await service(repo);
      await s.create(draft());
      expect((await repo.loadAll()).length, 1);
    });
  });
}
