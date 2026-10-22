import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/app_client_config.dart';
import 'package:arenabook/app/service/getx_service/booking_service.dart';
import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/pricing.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/repositories/booking/booking_repository.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/dialogs/settings_dialog.dart';
import 'package:arenabook/presentation/arena/invoice/invoice_sheet.dart';
import 'arena_app_test.dart' as app;
import 'helpers/resource_types.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);
  final originalPricing = AppClientConfig.pricing;
  tearDown(() async {
    AppClientConfig.pricing = originalPricing;
    await Get.deleteAll(force: true);
  });

  BookingDraft draft({PricingMode pricing = PricingMode.manual, int price = 15000, int advance = 5000, int discount = 0, List<TimeRange>? slots}) =>
      BookingDraft(
        customerName: 'Zain Malik',
        phone: '03001234567',
        resourceType: cricket,
        resourceId: 'cricket-1',
        date: DateTime(2026, 10, 2),
        slots: slots ?? [TimeRange.hour(20)],
        pricing: pricing,
        hourlyRate: 1500,
        price: price,
        discount: discount,
        advancePaid: advance,
      );

  Future<BookingService> service() => BookingService(InMemoryBookingRepository(), clock: () => now).init();

  group('stored bookings', () {
    test('a v2 booking (saved before pricing modes) loads as hourly with its fee unchanged', () {
      final v2 = {
        'v': 2,
        'id': 'TRF-1001',
        'customerName': 'Ayesha Khan',
        'phone': '03219876543',
        'sport': 'cricket',
        'courtId': 'cricket-1',
        'date': '2026-10-01',
        'slots': [
          {'start': 1200, 'end': 1260},
        ],
        'hourlyRate': 1500,
        'totalFee': 1500,
        'discount': 0,
        'advancePaid': 500,
        'createdAt': '2026-10-01T10:00:00.000',
        'updatedAt': '2026-10-01T10:00:00.000',
      };
      final b = Booking.fromJson(v2);
      expect(b.pricing, PricingMode.hourly);
      expect(b.totalFee, 1500);
      expect(b.balanceDue, 1000);
    });

    test('a manual price survives a save and load (schema v3)', () async {
      final saved = await (await service()).create(draft());
      final json = saved.toJson();
      expect(json['v'], 3);
      expect(json['pricing'], 'manual');
      final loaded = Booking.fromJson(json);
      expect(loaded.pricing, PricingMode.manual);
      expect(loaded.totalFee, 15000);
      expect(loaded.hourlyRate, 0);
    });
  });

  group('BookingService', () {
    test('manual: the typed price is the fee, whatever the length or rate', () async {
      final b = await (await service()).create(draft(slots: [TimeRange(h(18), h(22))]));
      expect(b.pricing, PricingMode.manual);
      expect(b.totalFee, 15000);
      expect(b.hourlyRate, 0); // never shown as "@ rate/hr"
      expect(b.balanceDue, 10000);
    });

    test('manual: a price is required; discount and advance are capped by it', () async {
      final s = await service();
      await expectLater(s.create(draft(price: 0)), throwsA(isA<BookingException>().having((e) => e.message, 'message', 'Please enter the ground fee')));
      await expectLater(s.create(draft(discount: 20000)), throwsA(isA<BookingException>()));
      final b = await s.create(draft(advance: 99999));
      expect(b.advancePaid, 15000);
    });

    test('hourly is unchanged: minutes × rate, a typed price is ignored', () async {
      final b = await (await service()).create(draft(pricing: PricingMode.hourly, price: 99999));
      expect(b.totalFee, 1500);
      expect(b.hourlyRate, 1500);
    });

    test('editing a manual booking keeps the price the owner typed', () async {
      final s = await service();
      final b = await s.create(draft());
      final edited = await s.update(b.id, draft(price: 18000, slots: [TimeRange(h(20), h(23))]));
      expect(edited.totalFee, 18000);
      expect(edited.pricing, PricingMode.manual);
    });
  });

  group('screens', () {
    Booking manualBooking() => Booking(
      id: 'TRF-1001',
      customerName: 'Ayesha Khan',
      phone: '03219876543',
      resourceType: cricket,
      resourceId: 'cricket-1',
      date: DateTime(2026, 10, 2),
      slots: [TimeRange(h(19), h(23))],
      pricing: PricingMode.manual,
      hourlyRate: 0,
      totalFee: 150000,
      advancePaid: 50000,
      createdAt: now,
      updatedAt: now,
    );

    testWidgets('an hourly booking stays hourly when edited after the client switched to manual', (tester) async {
      final hourly = app.seeded(id: 'TRF-1001', hour: 20, date: DateTime(2026, 10, 2));
      await app.setUpServices(seed: [hourly]);
      await app.pumpApp(tester, dark: true);
      AppClientConfig.pricing = PricingMode.manual;

      final form = BookingFormController.to..loadForEdit(hourly);
      expect(form.isManualPrice, isFalse);
      expect(form.totalFee, 1500); // its frozen rate × 1 h
      form.discardEdit();
      expect(form.isManualPrice, isTrue); // a new booking follows the client

      await app.disposeApp(tester);
    });

    testWidgets('invoice of a manual booking shows the length but no hourly rate', (tester) async {
      await app.setUpServices(seed: [manualBooking()]);
      await app.pumpApp(tester, dark: true);
      InvoiceSheet.show('TRF-1001');
      await tester.pumpAndSettle();
      expect(find.text('4 hrs'), findsOneWidget);
      expect(find.textContaining('/hr'), findsNothing);
      await app.disposeApp(tester);
    });

    testWidgets('Settings hides the hourly rates when prices are typed', (tester) async {
      await app.setUpServices();
      await app.pumpApp(tester, dark: true);
      SettingsDialog.show();
      await tester.pumpAndSettle();
      expect(find.textContaining('Rate / Hr'), findsWidgets);
      Get.back();
      await tester.pumpAndSettle();

      AppClientConfig.pricing = PricingMode.manual;
      SettingsDialog.show();
      await tester.pumpAndSettle();
      expect(find.textContaining('Rate / Hr'), findsNothing);
      Get.back();
      await tester.pumpAndSettle();
      await app.disposeApp(tester);
    });
  });
}

int h(int hour) => hour * 60;
