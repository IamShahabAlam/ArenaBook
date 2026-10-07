import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/app_client_config.dart';
import 'package:arenabook/app/config/app_strings.dart';
import 'package:arenabook/app/service/getx_service/booking_service.dart';
import 'package:arenabook/app/service/service_handler.dart/settings_store.dart';
import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/sport.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/rules/booking_stats.dart';
import 'package:arenabook/data/rules/invoice_text.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/dialogs/settings_dialog.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';
import 'arena_app_test.dart' as app;
import 'helpers/sports.dart';

const futsal = Sport(
  id: 'futsal',
  label: 'Futsal Pitch',
  shortLabel: 'Futsal',
  icon: Icons.sports_soccer_rounded,
  tone: SportTone.violet,
  defaultRate: 1800,
  emoji: '⚽',
  courts: [Court(id: 'futsal-1', name: 'Futsal Arena 1', description: 'Futsal Arena 1 (5-a-side)')],
);

Sport disabled(Sport s) => Sport(
  id: s.id,
  label: s.label,
  shortLabel: s.shortLabel,
  icon: s.icon,
  tone: s.tone,
  defaultRate: s.defaultRate,
  emoji: s.emoji,
  courts: s.courts,
  enabled: false,
);

void main() {
  final original = AppClientConfig.sports;
  tearDown(() async {
    AppClientConfig.sports = original;
    await Get.deleteAll(force: true);
  });

  test('the shipped config is valid', () {
    final sports = AppClientConfig.sports;
    expect(Sport.offered, isNotEmpty, reason: 'at least one sport must be enabled');
    expect(sports.map((s) => s.id).toSet().length, sports.length, reason: 'sport ids must be unique');
    final courtIds = [for (final s in sports) ...s.courts.map((c) => c.id)];
    expect(courtIds.toSet().length, courtIds.length, reason: 'court ids must be unique across sports');
    for (final s in sports) {
      expect(s.courts, isNotEmpty, reason: '${s.id} needs at least one court');
      expect(s.defaultRate, greaterThan(0), reason: '${s.id} needs a default rate');
      expect(s.icon, isNotNull);
    }
  });

  testWidgets('cricket switched off: gone from filters, form and Settings; old bookings still show', (tester) async {
    AppClientConfig.sports = [disabled(cricket), padel];
    final oldCricket = app.seeded(id: 'TRF-1001', hour: 20); // made while cricket was on
    await app.setUpServices(seed: [oldCricket]);
    await app.pumpApp(tester, dark: true);

    expect(Sport.offered, [padel]);
    expect(AppStrings.appTagline, 'Padel Court Booking');
    expect(find.text('All Courts'), findsNothing); // one sport: no filter on Home
    expect(BookingStats.from(BookingService.to.bookings).totalBookings, 1); // history still counted
    expect(find.text('Ayesha Khan'), findsOneWidget); // ...and listed

    // Form: no sport picker, padel preselected.
    ShellController.to.go(ArenaTab.addBooking);
    await tester.pumpAndSettle();
    expect(find.text('Select Sport Category'), findsNothing);
    expect(BookingFormController.to.sport.value, padel);

    // Settings: only the padel rate.
    SettingsDialog.show();
    await tester.pumpAndSettle();
    expect(find.text('Padel Rate / Hr'), findsOneWidget);
    expect(find.text('Cricket Rate / Hr'), findsNothing);
    Navigator.of(tester.element(find.text('Padel Rate / Hr'))).pop();
    await tester.pumpAndSettle();
    await app.disposeApp(tester);
  });

  testWidgets('editing an old booking of a switched-off sport keeps that sport selectable', (tester) async {
    AppClientConfig.sports = [disabled(cricket), padel];
    await app.setUpServices(
      seed: [app.seeded(id: 'TRF-1001', hour: 20, date: DateTime(2026, 10, 2))],
    );
    await app.pumpApp(tester, dark: true);
    BookingFormController.to.loadForEdit(BookingService.to.byId('TRF-1001')!);
    expect(BookingFormController.to.formSports, [padel, cricket]);
    await app.disposeApp(tester);
  });

  testWidgets('a third sport appears everywhere from config alone', (tester) async {
    AppClientConfig.sports = [cricket, padel, futsal];
    await app.setUpServices();
    await app.pumpApp(tester, dark: true);

    expect(find.text('Futsal'), findsWidgets); // Home filter (short labels with 3 sports)
    expect(SettingsStore.to.rateFor(futsal), 1800); // default rate from config
    expect(AppStrings.appTagline, 'Indoor Cricket & Padel Court & Futsal Pitch Booking');

    ShellController.to.go(ArenaTab.addBooking);
    await tester.pumpAndSettle();
    expect(find.text('Futsal Pitch'), findsOneWidget); // sport card in the form
    expect(tester.takeException(), isNull); // 3 cards fit

    // A futsal booking works end to end.
    final b = await BookingService.to.create(
      BookingDraft(
        customerName: 'Ali',
        phone: '03001234567',
        sport: futsal,
        courtId: 'futsal-1',
        date: DateTime(2026, 10, 2),
        slots: [TimeRange.hour(20)],
        hourlyRate: SettingsStore.to.rateFor(futsal),
        advancePaid: 0,
      ),
    );
    expect(b.court.name, 'Futsal Arena 1');
    expect(InvoiceText.whatsApp(b, currency: 'Rs'), startsWith('⚽'));
    expect(Sport.fromName(b.toJson()['sport'] as String), futsal);

    SettingsDialog.show();
    await tester.pumpAndSettle();
    expect(find.text('Futsal Rate / Hr'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.text('Futsal Rate / Hr'))).pop();
    await tester.pumpAndSettle();
    await app.disposeApp(tester);
  });

  test('a booking whose sport was removed from config still loads and renders', () {
    final json = app.seeded(id: 'TRF-1001', hour: 20).toJson()
      ..['sport'] = 'squash'
      ..['courtId'] = 'squash-1';
    final b = Booking.fromJson(json);
    expect(b.sport.id, 'squash');
    expect(b.sport.label, 'squash');
    expect(b.sport.enabled, isFalse);
    expect(b.court.name, 'squash-1');
    expect(b.toJson()['sport'], 'squash'); // saved back unchanged
  });
}
