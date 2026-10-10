import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arenabook/app/service/getx_service/app_access_service.dart';
import 'package:arenabook/app/service/getx_service/storage_service.dart';
import 'package:arenabook/data/models/app_access.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/dialogs/trial_expired_dialog.dart';
import 'package:arenabook/presentation/arena/shell/booking_actions.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';

import 'arena_app_test.dart' show disposeApp, now, pumpApp, setUpServices;

String gist({Object? status = 1, Object? enabled = true, Object? date = ''}) =>
    jsonEncode({'IsAppEnable': enabled, 'AppDisableAfterDate': date, 'DataEntryStatus': status, 'UserName': 'Shahab'});

/// The Gist as first published: missing comma + trailing comma.
const brokenGist = '{"IsAppEnable": false, "AppDisableAfterDate":"" "DataEntryStatus": 1, "UserName":"Shahab",}';

bool blockedAt(String body, DateTime at) => AppAccess.tryParse(body)!.isBlocked(at);

void main() {
  group('AppAccess rules', () {
    test('DataEntryStatus other than 1 ignores the config entirely', () {
      expect(blockedAt(gist(status: 0, enabled: false), now), isFalse);
      expect(blockedAt(gist(status: 0, enabled: false, date: '2020-01-01'), now), isFalse);
      expect(blockedAt(gist(status: null, enabled: false), now), isFalse);
    });

    test('IsAppEnable true always runs', () {
      expect(blockedAt(gist(enabled: true, date: '2020-01-01'), now), isFalse);
    });

    test('IsAppEnable false with no date blocks immediately', () {
      expect(blockedAt(gist(enabled: false, date: ''), now), isTrue);
      expect(blockedAt(gist(enabled: false, date: null), now), isTrue);
    });

    test('IsAppEnable false with a date blocks once that whole day has passed', () {
      final body = gist(enabled: false, date: '2026-10-20');
      expect(blockedAt(body, DateTime(2026, 10, 20, 23, 59)), isFalse);
      expect(blockedAt(body, DateTime(2026, 10, 21)), isTrue);
    });

    test('days left counts today, and only while a dated trial is running', () {
      final trial = AppAccess.tryParse(gist(enabled: false, date: '2026-10-20'))!;
      expect(trial.trialDaysLeft(DateTime(2026, 10, 10, 9)), 11);
      expect(trial.trialDaysLeft(DateTime(2026, 10, 20, 23, 59)), 1); // last day
      expect(trial.trialDaysLeft(DateTime(2026, 10, 21)), isNull); // expired: the dialog takes over
      for (final other in [gist(enabled: true, date: '2026-10-20'), gist(status: 0, enabled: false, date: '2026-10-20'), gist(enabled: false)]) {
        expect(AppAccess.tryParse(other)!.trialDaysLeft(now), isNull, reason: other);
      }
    });

    test('a full timestamp is used as is', () {
      final body = gist(enabled: false, date: '2026-10-20T18:00:00');
      expect(blockedAt(body, DateTime(2026, 10, 20, 17, 59)), isFalse);
      expect(blockedAt(body, DateTime(2026, 10, 20, 18)), isTrue);
    });

    test('hand-typed values are accepted ("1", "false")', () {
      expect(blockedAt(gist(status: '1', enabled: 'false'), now), isTrue);
      expect(blockedAt(gist(status: 1.0, enabled: 'TRUE'), now), isFalse);
    });

    test('invalid JSON is rejected, not treated as enabled or disabled', () {
      expect(AppAccess.tryParse(brokenGist), isNull);
      expect(AppAccess.tryParse(''), isNull);
      expect(AppAccess.tryParse('[1, 2]'), isNull);
    });
  });

  group('AppAccessService', () {
    Future<AppAccessService> service({required AccessFetch fetch, DateTime? clock}) async {
      if (Get.isRegistered<AppAccessService>()) await Get.delete<AppAccessService>(force: true);
      final s = Get.put(AppAccessService(fetch: fetch, clock: () => clock ?? now));
      await s.refresh();
      return s;
    }

    setUp(() async {
      Get.testMode = true;
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      await Get.putAsync(() => StorageService().init());
    });
    // Get.put won't replace a registered StorageService, so a leftover one would leak these prefs into later tests.
    tearDown(() async => Get.deleteAll(force: true));

    test('runs before the first fetch, then a fetched block holds offline', () async {
      expect((await service(fetch: () async => null)).blocked.value, isFalse);
      expect((await service(fetch: () async => (body: gist(enabled: false), serverTime: null))).blocked.value, isTrue);
      // App restarted with no internet: the cached block still applies.
      expect((await service(fetch: () async => throw Exception('offline'))).blocked.value, isTrue);
    });

    test('a broken Gist edit keeps the last valid config', () async {
      await service(fetch: () async => (body: gist(enabled: false), serverTime: null));
      expect((await service(fetch: () async => (body: brokenGist, serverTime: null))).blocked.value, isTrue);
    });

    test('winding the phone clock back does not reopen a passed date', () async {
      final expired = gist(enabled: false, date: '2026-10-20');
      final phoneRewound = DateTime(2026, 10, 15);
      final s = await service(fetch: () async => (body: expired, serverTime: DateTime.utc(2026, 10, 22)), clock: phoneRewound);
      expect(s.blocked.value, isTrue);
      // Remembered across restarts, even offline.
      expect((await service(fetch: () async => null, clock: phoneRewound)).blocked.value, isTrue);
    });
  });

  testWidgets('a running dated trial shows the days left at the bottom of the drawer', (tester) async {
    await setUpServices();
    await Get.delete<AppAccessService>(force: true);
    // `now` is 1 Oct 12:00, so the 10th leaves 10 days (1st..10th).
    Get.put(
      AppAccessService(
        fetch: () async => (body: gist(enabled: false, date: '2026-10-10'), serverTime: null),
        clock: () => now,
      ),
    );
    await pumpApp(tester, dark: true);
    AppAccessService.to.startGuarding();
    await tester.pumpAndSettle();
    expect(find.text(TrialExpiredDialog.message), findsNothing); // still running

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('You are on your trial version, 10 days remaining.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('trial expired: dialog cannot be closed, every booking gate re-checks, and it lifts by itself', (tester) async {
    var body = gist(enabled: false);
    await setUpServices();
    await Get.delete<AppAccessService>(force: true);
    Get.put(AppAccessService(fetch: () async => (body: body, serverTime: null), clock: () => now));
    await pumpApp(tester, dark: true);

    // The splash hands over, then the dialog appears with all contacts.
    AppAccessService.to.startGuarding();
    await tester.pumpAndSettle();
    final dialog = find.text(TrialExpiredDialog.message);
    expect(dialog, findsOneWidget);
    expect(find.text('WhatsApp Support'), findsOneWidget);
    expect(find.text('Call Helpline'), findsOneWidget);
    expect(find.text('Email Support'), findsOneWidget);
    expect(find.byTooltip('Close'), findsNothing);

    // Back press and barrier tap do nothing.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(dialog, findsOneWidget);

    // Simulated bypass: the dialog is gone, yet opening the form or saving is refused and the dialog returns.
    Navigator.of(tester.element(dialog)).pop();
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    BookingActions.newBooking();
    await tester.pumpAndSettle();
    expect(ShellController.to.tab.value, ArenaTab.home);
    expect(dialog, findsOneWidget);
    expect(await BookingFormController.to.submit(), isNull);
    expect(dialog, findsOneWidget); // still one, not stacked

    // Owner sets IsAppEnable back to true: the next poll closes the dialog.
    body = gist(enabled: true);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    BookingActions.newBooking();
    await tester.pumpAndSettle();
    expect(ShellController.to.tab.value, ArenaTab.addBooking);

    await disposeApp(tester);
  });
}
