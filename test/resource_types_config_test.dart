import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/app_client_config.dart';
import 'package:arenabook/app/config/app_strings.dart';
import 'package:arenabook/app/service/getx_service/booking_service.dart';
import 'package:arenabook/app/service/service_handler.dart/settings_store.dart';
import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/resource.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/rules/booking_stats.dart';
import 'package:arenabook/data/rules/invoice_text.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/dialogs/settings_dialog.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';
import 'arena_app_test.dart' as app;
import 'helpers/resource_types.dart';

const futsal = ResourceType(
  id: 'futsal',
  label: 'Futsal Pitch',
  shortLabel: 'Futsal',
  icon: Icons.sports_soccer_rounded,
  tone: ResourceTone.violet,
  defaultRate: 1800,
  emoji: '⚽',
  resources: [Resource(id: 'futsal-1', name: 'Futsal Arena 1', description: 'Futsal Arena 1 (5-a-side)')],
);

ResourceType disabled(ResourceType s) => ResourceType(
  id: s.id,
  label: s.label,
  shortLabel: s.shortLabel,
  icon: s.icon,
  tone: s.tone,
  defaultRate: s.defaultRate,
  emoji: s.emoji,
  resources: s.resources,
  enabled: false,
);

void main() {
  final original = AppClientConfig.resourceTypes;
  tearDown(() async {
    AppClientConfig.resourceTypes = original;
    await Get.deleteAll(force: true);
  });

  test('the shipped config is valid', () {
    final resourceTypes = AppClientConfig.resourceTypes;
    expect(ResourceType.offered, isNotEmpty, reason: 'at least one sport must be enabled');
    expect(resourceTypes.map((s) => s.id).toSet().length, resourceTypes.length, reason: 'sport ids must be unique');
    final resourceIds = [for (final s in resourceTypes) ...s.resources.map((c) => c.id)];
    expect(resourceIds.toSet().length, resourceIds.length, reason: 'court ids must be unique across sports');
    for (final s in resourceTypes) {
      expect(s.resources, isNotEmpty, reason: '${s.id} needs at least one court');
      expect(s.defaultRate, greaterThan(0), reason: '${s.id} needs a default rate');
      expect(s.icon, isNotNull);
    }
  });

  test('a resource shows its description only when it adds to the name', () {
    expect(const Resource(id: 'a', name: 'Studio A', description: 'Studio A (cyclorama wall)').detail, 'Studio A (cyclorama wall)');
    expect(
      const Resource(id: 'b', name: 'Court B', description: ' Court B ').detail,
      isNull,
      reason: 'repeats the name',
    );
    expect(
      const Resource(id: 'c', name: 'Room 1').detail,
      isNull,
      reason: 'no description',
    );
    expect(Resource.byId('removed-1').detail, isNull, reason: 'placeholder for a removed resource');
  });

  test('the tagline lists resource types as "A, B & C"', () {
    final both = [cricket, padel]; // read both first: the helpers are lazy and look up the current config
    AppClientConfig.resourceTypes = [cricket];
    expect(AppStrings.appTagline, 'Indoor Cricket Booking');
    AppClientConfig.resourceTypes = both;
    expect(AppStrings.appTagline, 'Indoor Cricket & Padel Court Booking');
  });

  testWidgets('cricket switched off: gone from filters, form and Settings; old bookings still show', (tester) async {
    AppClientConfig.resourceTypes = [disabled(cricket), padel];
    final oldCricket = app.seeded(id: 'TRF-1001', hour: 20); // made while cricket was on
    await app.setUpServices(seed: [oldCricket]);
    await app.pumpApp(tester, dark: true);

    expect(ResourceType.offered, [padel]);
    expect(AppStrings.appTagline, 'Padel Court Booking');
    expect(find.text('All Courts'), findsNothing); // one sport: no filter on Home
    expect(BookingStats.from(BookingService.to.bookings).totalBookings, 1); // history still counted
    expect(find.text('Ayesha Khan'), findsOneWidget); // ...and listed

    // Form: no sport picker, padel preselected.
    ShellController.to.go(ArenaTab.addBooking);
    await tester.pumpAndSettle();
    expect(find.text('Select Sport Category'), findsNothing);
    expect(BookingFormController.to.resourceType.value, padel);

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
    AppClientConfig.resourceTypes = [disabled(cricket), padel];
    await app.setUpServices(
      seed: [app.seeded(id: 'TRF-1001', hour: 20, date: DateTime(2026, 10, 2))],
    );
    await app.pumpApp(tester, dark: true);
    BookingFormController.to.loadForEdit(BookingService.to.byId('TRF-1001')!);
    expect(BookingFormController.to.formResourceTypes, [padel, cricket]);
    await app.disposeApp(tester);
  });

  testWidgets('a third sport appears everywhere from config alone', (tester) async {
    AppClientConfig.resourceTypes = [cricket, padel, futsal];
    await app.setUpServices();
    await app.pumpApp(tester, dark: true);

    expect(find.text('Futsal'), findsWidgets); // Home filter (short labels with 3 sports)
    expect(SettingsStore.to.rateFor(futsal), 1800); // default rate from config
    expect(AppStrings.appTagline, 'Indoor Cricket, Padel Court & Futsal Pitch Booking');

    ShellController.to.go(ArenaTab.addBooking);
    await tester.pumpAndSettle();
    expect(find.text('Futsal Pitch'), findsOneWidget); // sport card in the form
    expect(tester.takeException(), isNull); // 3 cards fit

    // A futsal booking works end to end.
    final b = await BookingService.to.create(
      BookingDraft(
        customerName: 'Ali',
        phone: '03001234567',
        resourceType: futsal,
        resourceId: 'futsal-1',
        date: DateTime(2026, 10, 2),
        slots: [TimeRange.hour(20)],
        hourlyRate: SettingsStore.to.rateFor(futsal),
        advancePaid: 0,
      ),
    );
    expect(b.resource.name, 'Futsal Arena 1');
    expect(InvoiceText.whatsApp(b, currency: 'Rs'), startsWith('⚽'));
    expect(ResourceType.byId(b.toJson()['sport'] as String), futsal);

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
    expect(b.resourceType.id, 'squash');
    expect(b.resourceType.label, 'squash');
    expect(b.resourceType.enabled, isFalse);
    expect(b.resource.name, 'squash-1');
    expect(b.toJson()['sport'], 'squash'); // saved back unchanged
  });
}
