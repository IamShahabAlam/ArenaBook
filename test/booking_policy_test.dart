import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/app_client_config.dart';
import 'package:arenabook/app/config/business/business_profile.dart';
import 'package:arenabook/app/config/business/profiles.dart';
import 'package:arenabook/app/service/getx_service/booking_service.dart';
import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/booking_policy.dart';
import 'package:arenabook/data/models/pricing.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/repositories/booking/booking_repository.dart';
import 'package:arenabook/data/rules/booking_rules.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/shell/booking_actions.dart';
import 'arena_app_test.dart' as app;
import 'business_profile_test.dart' show photo, podcast;

int h(int hour, [int minute = 0]) => hour * 60 + minute;

/// A client's own daytime hours (9AM - 11PM): hourly, 1 h minimum, 2 h default, 12 h maximum.
const daytime = BookingPolicy(step: 60, minDuration: 60, defaultDuration: 120, maxDuration: 12 * 60, openHours: TimeRange(9 * 60, 23 * 60));

/// Office hours (8AM - 10PM): half-hour steps, 1 h minimum, 10 h maximum.
const office = BookingPolicy(minDuration: 60, maxDuration: 10 * 60, openHours: TimeRange(8 * 60, 22 * 60));

/// Open 4PM - 2AM, half-hour steps, 1 hour minimum.
const lateNight = BookingPolicy(minDuration: 60, openHours: TimeRange(16 * 60, 26 * 60));

void main() {
  final day = DateTime(2026, 10, 2); // tomorrow: nothing is past
  final now = DateTime(2026, 10, 1, 12);

  group('BookingPolicy', () {
    test('default (sports venue): open 24 hours in 30-minute steps, same as before', () {
      const p = BookingPolicy();
      expect(sportsVenue.policy.step, 30);
      expect(p.closedToday, isEmpty);
      expect(p.canStartAt(0), isTrue);
      expect(p.canStartAt(h(23, 30)), isTrue);
      expect(p.canStartAt(h(9, 15)), isFalse); // off-step
      expect(p.isOpenFor(TimeRange(h(23), h(25))), isTrue); // past midnight
    });

    test('daytime hours (9AM - 11PM)', () {
      final p = daytime;
      expect(p.closedToday, [TimeRange(0, h(9)), TimeRange(h(23), h(24))]);
      expect(p.closingFor(h(10)), h(23));
      expect(p.closingFor(h(23, 30)), isNull);
      expect(p.canStartAt(h(9)), isTrue);
      expect(p.canStartAt(h(8)), isFalse);
      expect(p.canStartAt(h(22)), isTrue); // 10PM + 1 h minimum = closing
      expect(p.canStartAt(h(23)), isFalse);
    });

    test('hours past midnight (4PM - 2AM) also open the early hours of each day', () {
      expect(lateNight.closedToday, [TimeRange(h(2), h(16))]);
      expect(lateNight.canStartAt(h(1)), isTrue); // 1AM, from the previous evening's hours
      expect(lateNight.canStartAt(h(1, 30)), isFalse); // 1 h minimum passes 2AM
      expect(lateNight.canStartAt(h(23)), isTrue);
      expect(lateNight.isOpenFor(TimeRange(h(23), h(26))), isTrue);
      expect(lateNight.isOpenFor(TimeRange(h(23), h(26, 30))), isFalse);
    });

    test('every profile has consistent rules', () {
      for (final p in allProfiles.map((p) => p.policy)) {
        expect(DayPart.values.expand((part) => BookingRules.startsIn(part, policy: p)), p.usesSessions ? anything : isNotEmpty);
        for (final s in p.sessions) {
          expect(s.time.startMinute, lessThan(TimeRange.minutesPerDay), reason: s.label);
          expect(s.time.durationMinutes, lessThanOrEqualTo(TimeRange.minutesPerDay), reason: s.label);
        }
      }
    });
  });

  group('BookingRules with a policy', () {
    test('start times follow the step and opening hours', () {
      expect(BookingRules.startsIn(DayPart.night, policy: daytime), isEmpty);
      expect(BookingRules.startsIn(DayPart.morning, policy: daytime), [h(9), h(10), h(11)]);
      expect(BookingRules.startsIn(DayPart.evening, policy: daytime), [h(18), h(19), h(20), h(21), h(22)]);
      expect(BookingRules.startsIn(DayPart.evening, policy: sportsVenue.policy).length, 12);
      expect(BookingRules.startsIn(DayPart.morning, policy: const BookingPolicy(step: 15, minDuration: 15)).length, 24);
    });

    test('longest duration stops at closing, the maximum and the next booking, in whole steps', () {
      expect(BookingRules.maxDuration(h(21), occupied: const [], policy: daytime), 2 * 60); // closes 11PM
      expect(BookingRules.maxDuration(h(9), occupied: const [], policy: daytime), 12 * 60); // 12 h maximum
      expect(BookingRules.maxDuration(h(9), occupied: [TimeRange(h(10, 30), h(11, 30))], policy: daytime), 60); // 90 min floored to 1 h
      expect(BookingRules.maxDuration(h(8), occupied: const [], policy: daytime), 0); // closed
    });

    test('a free start with no room for the minimum counts as booked', () {
      final occupied = [TimeRange(h(10), h(11))];
      final p = office; // 30-minute steps, 1 hour minimum
      expect(BookingRules.cellState(h(9, 30), date: day, now: now, occupied: occupied, policy: p), SlotState.booked);
      expect(BookingRules.cellState(h(9), date: day, now: now, occupied: occupied, policy: p), SlotState.available);
    });

    test('validation explains each broken rule', () {
      String? check(TimeRange slot, BookingPolicy p) => BookingRules.validateSlots([slot], date: day, now: now, occupied: const [], policy: p);
      expect(check(TimeRange(h(8), h(10)), daytime), '8AM - 10AM is outside opening hours (9AM - 11PM)');
      expect(check(TimeRange(h(9, 30), h(10, 30)), daytime), 'Times move in 60-minute steps');
      expect(check(TimeRange(h(10), h(10, 30)), office), 'A booking must be at least 1 h');
      expect(check(TimeRange(h(9), h(22)), daytime), 'A booking can be at most 12 h');
      expect(check(TimeRange(h(9), h(11)), daytime), isNull);
      expect(check(TimeRange(h(23), h(25)), lateNight), isNull);
      expect(check(TimeRange(h(10, 15), h(11, 15)), sportsVenue.policy), 'Times move in 30-minute steps');
    });

    test('sessions: only whole sessions can be booked', () {
      final p = eventVenue.policy;
      String? check(TimeRange slot) => BookingRules.validateSlots([slot], date: day, now: now, occupied: const [], policy: p);
      expect(check(TimeRange(h(12), h(18))), isNull); // Lunch 12PM - 6PM
      expect(check(TimeRange(h(19), h(24))), isNull); // Dinner 7PM - 12AM
      expect(check(TimeRange(h(19), h(23))), 'Please pick one of the sessions');
      final lunch = p.sessions.firstWhere((s) => s.label == 'Lunch');
      final fullDay = p.sessions.firstWhere((s) => s.label == 'Full Day');
      final dinner = p.sessions.firstWhere((s) => s.label == 'Dinner');
      final occupied = [lunch.time];
      expect(BookingRules.sessionState(fullDay, date: day, now: now, occupied: occupied), SlotState.booked); // overlaps lunch
      expect(BookingRules.sessionState(dinner, date: day, now: now, occupied: occupied), SlotState.available);
      expect(BookingRules.sessionState(lunch, date: DateTime(2026, 10, 1), now: now, occupied: const []), SlotState.past); // started at 12:00
    });

    test('an edited booking keeps its own time even if the policy changed since', () {
      final old = TimeRange(h(7), h(8)); // booked before the studio hours applied
      expect(BookingRules.validateSlots([old], date: day, now: now, occupied: const [], policy: daytime, keepPastSlots: {old}), isNull);
    });
  });

  group('BookingService follows the client policy', () {
    final original = AppClientConfig.policy;
    tearDown(() => AppClientConfig.policy = original);

    test('rejects a booking outside opening hours', () async {
      AppClientConfig.policy = daytime;
      final s = await BookingService(InMemoryBookingRepository(), clock: () => now).init();
      BookingDraft at(TimeRange slot) => BookingDraft(
        customerName: 'Sara Ahmed',
        phone: '03001234567',
        resourceType: photo,
        resourceId: 'photo-a',
        date: day,
        slots: [slot],
        hourlyRate: 4000,
        advancePaid: 0,
      );
      await expectLater(s.create(at(TimeRange(h(7), h(8)))), throwsA(isA<BookingException>()));
      final ok = await s.create(at(TimeRange(h(9), h(11))));
      expect(ok.totalFee, 8000);
    });
  });

  group('booking form', () {
    final originalProfile = AppClientConfig.profile;
    final originalPolicy = AppClientConfig.policy;
    final originalPricing = AppClientConfig.pricing;
    final originalTypes = AppClientConfig.resourceTypes;
    tearDown(() async {
      AppClientConfig.profile = originalProfile;
      AppClientConfig.policy = originalPolicy;
      AppClientConfig.pricing = originalPricing;
      AppClientConfig.resourceTypes = originalTypes;
      await Get.deleteAll(force: true);
    });

    void useProfile(BusinessProfile profile) {
      AppClientConfig.profile = profile;
      AppClientConfig.policy = profile.policy;
      AppClientConfig.pricing = profile.pricing;
      AppClientConfig.resourceTypes = [photo, podcast];
    }

    Future<BookingFormController> openForm(WidgetTester tester, {List<Booking> seed = const []}) async {
      await app.setUpServices(seed: seed);
      await app.pumpApp(tester, dark: false);
      BookingActions.newBooking();
      await tester.pumpAndSettle();
      final form = BookingFormController.to..selectDate(day);
      await tester.pumpAndSettle();
      return form;
    }

    testWidgets('client opening hours: closed hours hidden, hourly starts, 2 h default, stops at closing', (tester) async {
      final semantics = tester.ensureSemantics();
      useProfile(spaceRental);
      AppClientConfig.policy = daytime; // a client's own hours override the profile's (ClientConfig.policy)
      final form = await openForm(tester);

      expect(find.text('Night'), findsNothing); // 12-6AM is closed
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('2 h'), findsOneWidget); // default duration
      expect(find.bySemanticsLabel('10PM'), findsOneWidget); // evening tab (other days)
      expect(find.bySemanticsLabel('11PM'), findsNothing); // closing time
      expect(find.bySemanticsLabel('6:30PM'), findsNothing); // hourly steps

      final tenPm = find.bySemanticsLabel('10PM');
      await app.reveal(tester, tenPm);
      await tester.tap(tenPm);
      await tester.pump();
      expect(form.chosenSlots, [TimeRange(h(22), h(23))]); // 2 h default shrank to the hour before closing
      form.changeDuration(1);
      expect(form.duration.value, 60);
      expect(form.timeError, isNull);

      await app.disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('event venue: pick a whole session, type the required price; overlapping sessions show as booked', (tester) async {
      final semantics = tester.ensureSemantics();
      useProfile(eventVenue);
      final lunch = Booking(
        id: 'TRF-1001',
        customerName: 'Ali Raza',
        phone: '03001112223',
        resourceType: photo,
        resourceId: 'photo-a',
        date: day,
        slots: [TimeRange(h(12), h(18))],
        pricing: PricingMode.manual,
        hourlyRate: 0,
        totalFee: 120000,
        advancePaid: 50000,
        createdAt: now,
        updatedAt: now,
      );
      final form = await openForm(tester, seed: [lunch]);

      expect(find.text('Duration'), findsNothing); // sessions have a fixed length
      expect(find.bySemanticsLabel('Lunch, 12PM - 6PM, booked'), findsOneWidget);
      expect(find.bySemanticsLabel('Full Day, 10AM - 11PM, booked'), findsOneWidget);
      expect(find.textContaining('/ Hr'), findsNothing); // typed prices: no hourly rate on the cards

      final dinner = find.bySemanticsLabel('Dinner, 7PM - 12AM');
      await app.reveal(tester, dinner);
      await tester.tap(dinner);
      await tester.pump();
      expect(form.chosenSlots, [TimeRange(h(19), h(24))]);

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Zain Malik'), 'Hina Shah');
      await tester.enterText(find.widgetWithText(TextFormField, '03001234567'), '03004445556');
      final submit = find.text('Confirm & Generate Invoice');

      // No price yet: the field is required, nothing is saved.
      await tester.scrollUntilVisible(submit, 300, scrollable: app.formScrollable);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Please enter the venue fee'), findsOneWidget);
      expect(BookingService.to.bookings, hasLength(1));

      final priceField = find.byKey(const ValueKey('price-field'));
      await app.reveal(tester, priceField);
      await tester.enterText(priceField, '150000');
      await tester.pump();
      await tester.scrollUntilVisible(submit, 300, scrollable: app.formScrollable);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final saved = BookingService.to.bookings.firstWhere((b) => b.customerName == 'Hina Shah');
      expect(saved.slots, [TimeRange(h(19), h(24))]);
      expect(saved.pricing, PricingMode.manual);
      expect(saved.totalFee, 150000); // the typed price, not hours × rate
      expect(saved.hourlyRate, 0);

      await app.disposeApp(tester);
      semantics.dispose();
    });

    testWidgets('space rental: "Full day" books 24 hours from the start, priced by the hour', (tester) async {
      final semantics = tester.ensureSemantics();
      useProfile(spaceRental);
      final nextMorning = Booking(
        id: 'TRF-1001',
        customerName: 'Ali Raza',
        phone: '03001112223',
        resourceType: photo,
        resourceId: 'photo-a',
        date: DateTime(2026, 10, 3),
        slots: [TimeRange(h(10), h(11))],
        hourlyRate: 4000,
        totalFee: 4000,
        advancePaid: 0,
        createdAt: now,
        updatedAt: now,
      );
      final form = await openForm(tester, seed: [nextMorning]);
      expect(form.duration.value, 120); // 2 h default
      expect(find.bySemanticsLabel('Full day, 24 hours'), findsOneWidget);

      form.selectStart(h(8)); // 8AM: a full day ends 8AM tomorrow, before the 10AM booking
      await tester.pump();
      expect(form.canBookFullDay, isTrue);
      final fullDay = find.bySemanticsLabel('Full day, 24 hours');
      await app.reveal(tester, fullDay);
      await tester.tap(fullDay);
      await tester.pump();
      expect(form.chosenSlots, [TimeRange(h(8), h(32))]);
      expect(form.totalFee, 24 * 4000);
      expect(form.timeError, isNull);

      form.selectStart(h(8)); // clear
      form.selectStart(h(20)); // 8PM: only 14 hours before tomorrow's 10AM booking
      await tester.pump();
      expect(form.canBookFullDay, isFalse);
      form.selectFullDay();
      expect(form.isFullDay, isFalse);

      await app.disposeApp(tester);
      semantics.dispose();
    });
  });
}
