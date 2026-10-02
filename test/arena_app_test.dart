import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:arenabook/presentation/arena/booking_form/booking_form_view.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';
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
    final slot2pm = find.bySemanticsLabel('2PM - 3PM');
    await tester.scrollUntilVisible(slot2pm, 200, scrollable: formScrollable);
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
    final booked = find.bySemanticsLabel('2PM - 3PM, booked');
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

  test('invoice text', () {
    final b = seeded(id: 'TRF-1001', hour: 20);
    final text = InvoiceText.whatsApp(b, currency: 'Rs');
    expect(text, contains('#TRF-1001'));
    expect(text, contains('8PM - 9PM'));
    expect(text, contains('*Balance Due:* Rs 1,000'));
    expect(InvoiceText.plain(b.settle(now), currency: 'AED'), contains('Due: AED 0'));
  });
}
