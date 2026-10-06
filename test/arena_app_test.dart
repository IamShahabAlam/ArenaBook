import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arenabook/app/config/app_client_config.dart';
import 'package:arenabook/app/config/arena_theme.dart';
import 'package:arenabook/app/service/getx_service/booking_service.dart';
import 'package:arenabook/app/service/getx_service/storage_service.dart';
import 'package:arenabook/app/utils/custom_functions/arena_toast.dart';
import 'package:arenabook/app/service/service_handler.dart/settings_store.dart';
import 'package:arenabook/app/service/service_handler.dart/theme_store.dart';
import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/sport.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/repositories/booking/booking_repository.dart';
import 'package:arenabook/data/rules/invoice_text.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_view.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';
import 'package:arenabook/presentation/arena/widgets/arena_widgets.dart';
import 'package:arenabook/presentation/arena/shell/shell_view.dart';

final now = DateTime(2026, 10, 1, 12, 0);

Future<void> setUpServices({bool dark = true, List<Booking> seed = const []}) async {
  Get.testMode = true;
  SharedPreferences.setMockInitialValues({'isDarkMode': dark});
  await Get.putAsync(() => StorageService().init());
  Get.put(ThemeStore());
  Get.put(SettingsStore());
  await Get.putAsync(() => BookingService(InMemoryBookingRepository(seed), clock: () => now).init());
}

Future<void> pumpApp(WidgetTester tester, {required bool dark, Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ArenaTheme.light,
      darkTheme: ArenaTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      initialBinding: ShellBinding(),
      home: const ShellView(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Disposes the shell (cancels its clock timer) so no timer outlives the test.
Future<void> disposeApp(WidgetTester tester) async {
  // Remove any toast so its timer doesn't outlive the test.
  ArenaToast.dismiss(animate: false);
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpWidget(const SizedBox());
  await Get.deleteAll(force: true);
  await tester.pump(const Duration(seconds: 1));
}

Booking seeded({required String id, required int hour, int advance = 500, DateTime? date, Sport sport = Sport.cricket}) => Booking(
  id: id,
  customerName: 'Ayesha Khan',
  phone: '03219876543',
  sport: sport,
  courtId: sport == Sport.cricket ? 'cricket-1' : 'padel-a',
  date: date ?? DateTime(2026, 10, 1),
  slots: [TimeRange.hour(hour)],
  hourlyRate: 1500,
  totalFee: 1500,
  advancePaid: advance,
  createdAt: now,
  updatedAt: now,
);

/// The booking form's own list (IndexedStack builds every tab, so "the n-th Scrollable" is fragile).
final formScrollable = find.descendant(of: find.byType(BookingFormView), matching: find.byType(Scrollable)).first;

/// Scrolls [target] to the middle of the form, clear of the floating bottom nav (a tap there would miss).
Future<void> reveal(WidgetTester tester, Finder target, {double delta = 250}) async {
  await tester.scrollUntilVisible(target, delta, scrollable: formScrollable);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => Get.deleteAll(force: true));

  testWidgets('create a booking end to end, then the slot shows as booked', (tester) async {
    final semantics = tester.ensureSemantics();
    await setUpServices();
    await pumpApp(tester, dark: true);

    expect(find.text('No upcoming bookings yet.'), findsOneWidget);

    await tester.tap(find.byTooltip('New booking'));
    await tester.pumpAndSettle();
    expect(find.text('Create New Booking'), findsOneWidget);

    // 9AM .. 12PM have started at 12:00; 2PM is free.
    final slot2pm = find.bySemanticsLabel('2PM');
    await reveal(tester, slot2pm);
    await tester.tap(slot2pm);
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Zain Malik'), 'Zain Malik');
    await tester.enterText(find.widgetWithText(TextFormField, '03001234567'), '03001234567');

    final submit = find.text('Confirm & Generate Invoice');
    await tester.scrollUntilVisible(submit, 300, scrollable: formScrollable);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // Invoice sheet for the new booking
    expect(find.text('#TRF-1001'), findsWidgets);
    expect(BookingService.to.bookings.single.totalFee, 1500);

    // Close the invoice -> spec: back to Home, which now lists the booking
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(ShellController.to.tab.value, ArenaTab.home);
    expect(find.text('Zain Malik'), findsOneWidget);

    // The same slot is now blocked in the form (tapping "+" works even while the success toast is showing)
    await tester.tap(find.byTooltip('New booking'));
    await tester.pumpAndSettle();
    final booked = find.bySemanticsLabel('2PM, booked');
    await tester.scrollUntilVisible(booked, -300, scrollable: formScrollable); // form kept its scroll position
    expect(booked, findsOneWidget);

    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('submitting without a slot shows an error and saves nothing', (tester) async {
    await setUpServices();
    await pumpApp(tester, dark: false);
    await tester.tap(find.byTooltip('New booking'));
    await tester.pumpAndSettle();

    final name = find.widgetWithText(TextFormField, 'e.g. Zain Malik');
    await tester.scrollUntilVisible(name, 300, scrollable: formScrollable);
    await tester.enterText(name, 'Zain Malik');
    await tester.enterText(find.widgetWithText(TextFormField, '03001234567'), '03001234567');
    final submit = find.text('Confirm & Generate Invoice');
    await tester.scrollUntilVisible(submit, 300, scrollable: formScrollable);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Please select at least 1 time slot'), findsOneWidget);
    expect(BookingService.to.bookings, isEmpty);
    await disposeApp(tester);
  });

  // Every tab, both themes, a normal and a small phone: any overflow fails the test.
  for (final dark in [true, false]) {
    for (final size in const [Size(390, 844), Size(320, 640)]) {
      testWidgets('all tabs render without layout errors (${dark ? 'dark' : 'light'}, ${size.width.toInt()}w)', (tester) async {
        await setUpServices(
          dark: dark,
          seed: [
            seeded(id: 'TRF-1001', hour: 20),
            seeded(id: 'TRF-1002', hour: 21, advance: 1500, sport: Sport.padel),
            seeded(id: 'TRF-1003', hour: 18, date: DateTime(2026, 9, 28)),
          ],
        );
        await pumpApp(tester, dark: dark, size: size);
        for (final tab in ArenaTab.values) {
          ShellController.to.go(tab);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'tab $tab');
        }
        // Drawer
        await tester.tap(find.byTooltip('Menu'));
        await tester.pumpAndSettle();
        expect(find.text('Settings & Preferences'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  }

  testWidgets('time picker: 11PM booking runs past midnight, stopped by next-day booking', (tester) async {
    final semantics = tester.ensureSemantics();
    // Tomorrow 12:30-1:30 AM is already booked on cricket-1.
    final early = seeded(id: 'TRF-1001', hour: 0, date: DateTime(2026, 10, 2));
    await setUpServices(
      seed: [
        early.copyWith(slots: [const TimeRange(30, 90)]),
      ],
    );
    await pumpApp(tester, dark: true);
    await tester.tap(find.byTooltip('New booking'));
    await tester.pumpAndSettle();
    final form = BookingFormController.to;

    await reveal(tester, find.text('Evening'));
    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();
    final chip11 = find.bySemanticsLabel('11PM');
    await reveal(tester, chip11);
    await tester.tap(chip11);
    await tester.pump();
    expect(form.chosenSlots.single.label, '11PM - 12AM'); // default 1 h

    await tester.tap(find.byTooltip('Longer'));
    await tester.pump();
    expect(form.chosenSlots.single.label, '11PM - 12:30AM (next day)');
    expect(find.textContaining('(next day)'), findsOneWidget); // shown in the picker summary

    await tester.tap(find.byTooltip('Longer'));
    await tester.pump();
    expect(form.duration.value, 90); // capped: tomorrow 12:30 AM is taken

    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('time picker: duration stops at the next booking', (tester) async {
    final semantics = tester.ensureSemantics();
    await setUpServices(seed: [seeded(id: 'TRF-1001', hour: 15)]); // 3-4 PM taken on cricket-1
    await pumpApp(tester, dark: true);
    await tester.tap(find.byTooltip('New booking'));
    await tester.pumpAndSettle();
    final form = BookingFormController.to;

    final chip230 = find.bySemanticsLabel('2:30PM');
    await reveal(tester, chip230);
    expect(find.bySemanticsLabel('3PM, booked'), findsOneWidget);
    expect(find.bySemanticsLabel('12PM, past'), findsOneWidget); // clock is 12:00

    await tester.tap(chip230);
    await tester.pump();
    expect(form.duration.value, 30); // shrunk from 1 h: only 30 min until 3 PM
    expect(form.chosenSlots.single.label, '2:30PM - 3PM');

    await tester.tap(find.byTooltip('Longer'));
    await tester.pump();
    expect(form.duration.value, 30); // still: would overlap the 3 PM booking

    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('advance & discount start empty (0 is a hint), so typing replaces it', (tester) async {
    await setUpServices();
    await pumpApp(tester, dark: true);
    final form = BookingFormController.to;
    expect(form.advanceCtrl.text, isEmpty);
    expect(form.discountCtrl.text, isEmpty);
    await tester.tap(find.byTooltip('New booking'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('discount-field')), delta: 400);
    expect(find.widgetWithText(TextField, '0'), findsNWidgets(2)); // the hints

    form.selectStart(14 * 60); // 2-3 PM, fee 1500
    form.onAdvanceChanged('500');
    expect(form.advance.value, 500);
    form.selectStart(14 * 60); // clear the time: fee 0, advance capped back to 0
    await tester.pump();
    expect(form.advanceCtrl.text, isEmpty); // back to the hint, not a literal "0"
    await disposeApp(tester);
  });

  test('invoice text', () {
    final b = seeded(id: 'TRF-1001', hour: 20);
    final text = InvoiceText.whatsApp(b, currency: 'Rs');
    expect(text, contains('#TRF-1001'));
    expect(text, contains('8PM - 9PM'));
    expect(text, contains('*Balance Due:* Rs 1,000'));
    expect(InvoiceText.plain(b.settle(now), currency: 'AED'), contains('Due: AED 0'));
  });

  test('invoice text itemises the discount only when the feature is on', () {
    final b = seeded(id: 'TRF-1001', hour: 20).copyWith(discount: 200); // fee 1500, advance 500
    final on = InvoiceText.whatsApp(b, currency: 'Rs', discountEnabled: true);
    expect(on, contains('*Ground Fee:* Rs 1,500'));
    expect(on, contains('*Discount:* -Rs 200'));
    expect(on, contains('*Total Fee:* Rs 1,300'));
    expect(on, contains('*Balance Due:* Rs 800'));

    final off = InvoiceText.whatsApp(b, currency: 'Rs', discountEnabled: false);
    expect(off, isNot(contains('Discount')));
    expect(off, contains('*Total Fee:* Rs 1,300')); // numbers still add up
    expect(InvoiceText.plain(b, currency: 'Rs', discountEnabled: false), isNot(contains('discount')));
  });

  for (final enabled in [true, false]) {
    testWidgets('booking form ${enabled ? 'shows' : 'hides'} the discount field (config)', (tester) async {
      AppClientConfig.enableDiscount = enabled;
      addTearDown(() => AppClientConfig.enableDiscount = true);
      await setUpServices();
      await pumpApp(tester, dark: true);
      await tester.tap(find.byTooltip('New booking'));
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey('discount-field'));
      if (!enabled) {
        await tester.drag(formScrollable, const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(field, findsNothing);
        expect(find.text('Payable'), findsNothing);
        await disposeApp(tester);
        return;
      }

      // Pick 2PM (fee 1500), give 200 off: payable and balance follow.
      final slot = find.bySemanticsLabel('2PM');
      final semantics = tester.ensureSemantics();
      await reveal(tester, slot);
      await tester.tap(slot);
      await tester.pump();
      await reveal(tester, field);
      await tester.enterText(field, '200');
      await tester.pumpAndSettle();
      expect(BookingFormController.to.payable, 1300);
      expect(BookingFormController.to.balance, 1300);

      // More than the fee is capped to the fee.
      await tester.enterText(field, '5000');
      await tester.pumpAndSettle();
      expect(BookingFormController.to.discount.value, 1500);
      expect(BookingFormController.to.payable, 0);
      semantics.dispose();
      await disposeApp(tester);
    });
  }
}
