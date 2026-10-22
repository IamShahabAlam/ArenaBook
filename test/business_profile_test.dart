import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/app_client_config.dart';
import 'package:arenabook/app/config/business/business_profile.dart';
import 'package:arenabook/app/config/business/profiles.dart';
import 'package:arenabook/data/models/booking.dart';
import 'package:arenabook/data/models/resource.dart';
import 'package:arenabook/data/models/time_range.dart';
import 'package:arenabook/data/rules/booking_rules.dart';
import 'package:arenabook/data/rules/invoice_text.dart';
import 'package:arenabook/presentation/arena/dialogs/cancel_booking_dialog.dart';
import 'package:arenabook/presentation/arena/dialogs/info_dialogs.dart';
import 'package:arenabook/presentation/arena/dialogs/trial_expired_dialog.dart';
import 'package:arenabook/presentation/arena/invoice/invoice_sheet.dart';
import 'package:arenabook/presentation/arena/shell/booking_actions.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';
import 'arena_app_test.dart' as app;

/// Neutral resource types: the wording under test comes from the profile, not from these names.
const photo = ResourceType(
  id: 'photo',
  label: 'Photo Studio',
  shortLabel: 'Photo',
  icon: Icons.photo_camera_rounded,
  tone: ResourceTone.violet,
  defaultRate: 4000,
  emoji: '📷',
  resources: [Resource(id: 'photo-a', name: 'Studio A', description: 'Studio A (cyclorama wall)')],
);

const podcast = ResourceType(
  id: 'podcast',
  label: 'Podcast Room',
  shortLabel: 'Podcast',
  icon: Icons.mic_rounded,
  tone: ResourceTone.blue,
  defaultRate: 2500,
  emoji: '🎙️',
  resources: [Resource(id: 'podcast-1', name: 'Room 1', description: 'Room 1 (two mics)')],
);

/// Any of these on screen means a string still bypasses [Terms].
final sportsWording = RegExp(r'\b(courts?|grounds?|sports?|players?|pitch(es)?|playing|turf)\b', caseSensitive: false);

Booking booking(String id, {bool cancelled = false}) => Booking(
  id: id,
  customerName: 'Sara Ahmed',
  phone: '03001234567',
  resourceType: photo,
  resourceId: 'photo-a',
  date: DateTime(2026, 10, 2),
  slots: [TimeRange.hour(15)],
  hourlyRate: 4000,
  totalFee: 4000,
  advancePaid: 1000,
  cancelledAt: cancelled ? app.now : null,
  cancelReason: cancelled ? 'Plans changed' : '',
  advanceReturned: cancelled,
  createdAt: app.now,
  updatedAt: app.now,
);

/// Every string a user can see or hear: texts, rich texts and accessibility labels.
Set<String> visibleText(WidgetTester tester) => {
  for (final w in tester.allWidgets)
    if (w is Text)
      w.data ?? w.textSpan?.toPlainText() ?? ''
    else if (w is RichText)
      w.text.toPlainText()
    else if (w is Semantics && w.properties.label != null)
      w.properties.label!,
};

void expectNoSportsWording(WidgetTester tester, String where) {
  expect(visibleText(tester).where(sportsWording.hasMatch), isEmpty, reason: 'sports wording on $where');
}

void main() {
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

  group('demo (sports venue)', () {
    test('ships the sports venue profile with the original wording and time rules', () {
      expect(AppClientConfig.profile, same(sportsVenue));
      expect(AppClientConfig.policy, same(sportsVenue.policy));
      final terms = AppClientConfig.terms;
      expect(terms.booking, 'Ground Booking');
      expect(terms.bookings, 'Ground Bookings');
      expect(terms.fee, 'Ground Fee');
      expect(terms.passHint, 'Show at arena entry');
    });

    test('receipt keeps its original lines', () {
      final b = app.seeded(id: 'TRF-1001', hour: 20);
      final text = InvoiceText.whatsApp(b, currency: 'Rs');
      expect(text, contains('*ARENABOOK GROUND RECEIPT*'));
      expect(text, contains('*Court:* Turf Pitch 1 (Main)'));
      expect(text, endsWith('Thank you for playing at ArenaBook grounds! Present this receipt at entry.'));
      expect(InvoiceText.plain(b, currency: 'Rs'), contains('\nCourt: Turf Pitch 1 (Main)\n'));
      expect(BookingRules.validateDiscount(2000, 1500), 'Discount cannot be more than the ground fee');
      expect(TrialExpiredDialog.notActivatedMessage, contains('for your arena;'));
    });
  });

  test('every profile has a unique id and complete wording', () {
    expect(allProfiles.map((p) => p.id).toSet().length, allProfiles.length);
    for (final p in allProfiles) {
      final t = p.terms;
      final words = [t.subject, t.resource, t.resources, t.resourceType, t.customer, t.fee, t.place, t.passHint, t.receiptThanks, t.cancelReasonHint];
      expect(words.every((w) => w.trim().isNotEmpty), isTrue, reason: p.id);
      if (p != sportsVenue) expect(words.where(sportsWording.hasMatch), isEmpty, reason: p.id);
    }
  });

  for (final profile in allProfiles.where((p) => p != sportsVenue)) {
    final t = profile.terms;

    group('${profile.id} profile', () {
      setUp(() => useProfile(profile));

      test('receipts, rules and messages use its words', () {
        final whatsApp = InvoiceText.whatsApp(booking('TRF-1001'), currency: 'Rs', discountEnabled: true);
        final plain = InvoiceText.plain(booking('TRF-1001'), currency: 'Rs');
        expect(whatsApp, contains('*ARENABOOK ${t.subject.toUpperCase()} RECEIPT*'));
        expect(whatsApp, contains('*${t.resource}:* Studio A'));
        expect(whatsApp, endsWith(t.receiptThanks));
        expect(plain, contains('\n${t.resource}: Studio A\n'));
        expect(BookingRules.validateDiscount(5000, 4000), 'Discount cannot be more than the ${t.fee.toLowerCase()}');
        expect(TrialExpiredDialog.notActivatedMessage, contains('for your ${t.place};'));
        for (final text in [whatsApp, plain, InvoiceText.whatsApp(booking('TRF-1002', cancelled: true), currency: 'Rs')]) {
          expect(sportsWording.hasMatch(text), isFalse, reason: text);
        }
      });

      testWidgets('no screen, sheet or dialog shows sports wording', (tester) async {
        await app.setUpServices(seed: [booking('TRF-1001'), booking('TRF-1002', cancelled: true)]);
        await app.pumpApp(tester, dark: true);

        // IndexedStack builds every tab, so this covers Home, Bookings, Pending and Calendar.
        expectNoSportsWording(tester, 'the tabs');
        expect(find.text('All ${t.resources}', skipOffstage: false), findsWidgets);
        expect(find.text(t.bookings, skipOffstage: false), findsOneWidget);
        expect(find.text('UNSETTLED ${t.fee.toUpperCase()}S', skipOffstage: false), findsOneWidget);

        ShellController.to.scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();
        expectNoSportsWording(tester, 'the drawer');
        expect(find.text('${t.subject} Management'), findsOneWidget);
        ShellController.to.scaffoldKey.currentState!.closeDrawer();
        await tester.pumpAndSettle();

        BookingActions.newBooking();
        await tester.pumpAndSettle();
        expectNoSportsWording(tester, 'the booking form');
        expect(find.text('Select ${t.resourceType} Category'), findsOneWidget);
        expect(find.text('Select ${t.resource}'), findsOneWidget);

        for (final id in ['TRF-1001', 'TRF-1002']) {
          InvoiceSheet.show(id);
          await tester.pumpAndSettle();
          expectNoSportsWording(tester, 'invoice $id');
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();
        }

        SupportDialog.show();
        await tester.pumpAndSettle();
        expectNoSportsWording(tester, 'the support dialog');
        Get.back();
        await tester.pumpAndSettle();

        CancelBookingDialog.show(booking('TRF-1001'));
        await tester.pumpAndSettle();
        expectNoSportsWording(tester, 'the cancel dialog');
        expect(find.text('Was advance payment returned to ${t.customer.toLowerCase()}?'), findsOneWidget);
        expect(find.text(t.cancelReasonHint), findsOneWidget);
        Get.back();
        await tester.pumpAndSettle();

        await app.disposeApp(tester);
      });
    });
  }
}
