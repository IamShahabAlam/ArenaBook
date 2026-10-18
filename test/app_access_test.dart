import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arenabook/app/service/getx_service/app_access_service.dart';
import 'package:arenabook/app/service/getx_service/storage_service.dart';
import 'package:arenabook/data/models/app_access.dart';
import 'package:arenabook/presentation/arena/booking_form/booking_form_controller.dart';
import 'package:arenabook/presentation/arena/dialogs/trial_expired_dialog.dart';
import 'package:arenabook/presentation/arena/shell/booking_actions.dart';
import 'package:arenabook/presentation/arena/shell/shell_controller.dart';

import 'arena_app_test.dart' show disposeApp, now, pumpApp, setUpServices;

String gist({Object? status = 1, Object? enabled = true, Object? date = '', String client = 'demo'}) => jsonEncode({
  'clients': {
    client: {'IsAppEnable': enabled, 'AppDisableAfterDate': date, 'DataEntryStatus': status, 'UserName': 'Shahab'},
  },
});

/// The Gist as first published: missing comma + trailing comma.
const brokenGist = '{"clients": {"demo": {"IsAppEnable": false, "AppDisableAfterDate":"" "DataEntryStatus": 1, "UserName":"Shahab",}}}';

bool blockedAt(String body, DateTime at) => AppAccess.parse(body, client: 'demo').isBlocked(at);

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
      final trial = AppAccess.parse(gist(enabled: false, date: '2026-10-20'), client: 'demo');
      expect(trial.trialDaysLeft(DateTime(2026, 10, 10, 9)), 11);
      expect(trial.trialDaysLeft(DateTime(2026, 10, 20, 23, 59)), 1); // last day
      expect(trial.trialDaysLeft(DateTime(2026, 10, 21)), isNull); // expired: the dialog takes over
      for (final other in [gist(enabled: true, date: '2026-10-20'), gist(status: 0, enabled: false, date: '2026-10-20'), gist(enabled: false)]) {
        expect(AppAccess.parse(other, client: 'demo').trialDaysLeft(now), isNull, reason: other);
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

    test('invalid JSON blocks now as "not activated"', () {
      for (final body in [brokenGist, '', '[1, 2]', '<html>Wi-Fi login</html>']) {
        final access = AppAccess.parse(body, client: 'demo');
        expect(access.isBlocked(now), isTrue, reason: body);
        expect(access.notActivated, isTrue, reason: body);
        expect(access.trialDaysLeft(now), isNull, reason: body);
      }
    });

    test('each client reads only its own entry; an unlisted client is blocked', () {
      final body = jsonEncode({
        'clients': {
          'demo': {'DataEntryStatus': 1, 'IsAppEnable': false},
          'other': {'DataEntryStatus': 1, 'IsAppEnable': true},
        },
      });
      expect(AppAccess.parse(body, client: 'demo').isBlocked(now), isTrue);
      expect(AppAccess.parse(body, client: 'demo').notActivated, isFalse, reason: 'blocked by its own entry');
      expect(AppAccess.parse(body, client: 'other').isBlocked(now), isFalse);
      final unlisted = AppAccess.parse(body, client: 'new_arena');
      expect(unlisted.isBlocked(now), isTrue);
      expect(unlisted.notActivated, isTrue);
    });

    test('a Gist without the clients map, or a malformed entry, blocks as "not activated"', () {
      final bodies = [
        jsonEncode({'DataEntryStatus': 1, 'IsAppEnable': true}), // old single-client format
        jsonEncode({'clients': []}),
        jsonEncode({
          'clients': {'demo': 'on'},
        }),
      ];
      for (final body in bodies) {
        expect(AppAccess.parse(body, client: 'demo').notActivated, isTrue, reason: body);
      }
    });

    test('only a 200 from GitHub itself counts as the Gist', () {
      final github = {'x-github-request-id': '3226:1B26', 'date': 'Sun, 18 Oct 2026 17:45:31 GMT'};
      expect(AppAccessService.gistResult(http.Response('{}', 200, headers: github))?.body, '{}');
      expect(AppAccessService.gistResult(http.Response('{}', 200, headers: github))?.serverTime, DateTime.utc(2026, 10, 18, 17, 45, 31));
      expect(AppAccessService.gistResult(http.Response('<html>login</html>', 200)), isNull, reason: 'Wi-Fi portal or proxy');
      expect(AppAccessService.gistResult(http.Response('404: Not Found', 404, headers: github)), isNull);
      expect(AppAccessService.gistResult(http.Response('', 503, headers: github)), isNull);
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

    test('a broken Gist edit blocks, holds offline, and lifts once fixed', () async {
      await service(fetch: () async => (body: gist(enabled: true), serverTime: null));
      final broken = await service(fetch: () async => (body: brokenGist, serverTime: null));
      expect(broken.blocked.value, isTrue);
      expect(broken.notActivated.value, isTrue);
      expect((await service(fetch: () async => null)).blocked.value, isTrue, reason: 'offline restart keeps the block');
      final fixed = await service(fetch: () async => (body: gist(enabled: true), serverTime: null));
      expect(fixed.blocked.value, isFalse);
      expect(fixed.notActivated.value, isFalse);
    });

    test('a Gist without this client blocks it', () async {
      final s = await service(fetch: () async => (body: gist(client: 'another_arena'), serverTime: null));
      expect(s.blocked.value, isTrue);
      expect(s.notActivated.value, isTrue);
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

  testWidgets('a bad Gist or a missing client shows "not activated", updates in place, and lifts once fixed', (tester) async {
    var body = brokenGist;
    await setUpServices();
    await Get.delete<AppAccessService>(force: true);
    Get.put(AppAccessService(fetch: () async => (body: body, serverTime: null), clock: () => now));
    await pumpApp(tester, dark: false);
    AppAccessService.to.startGuarding();
    await tester.pumpAndSettle();

    expect(find.text('App Not Activated'), findsOneWidget);
    expect(find.text(TrialExpiredDialog.notActivatedMessage), findsOneWidget);
    expect(find.text('WhatsApp Support'), findsOneWidget);
    BookingActions.newBooking();
    await tester.pumpAndSettle();
    expect(ShellController.to.tab.value, ArenaTab.home, reason: 'bookings stay locked');

    // Client added to the Gist but its trial is over: same dialog, now with the trial wording.
    body = gist(enabled: false);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text(TrialExpiredDialog.message), findsOneWidget);
    expect(find.text(TrialExpiredDialog.notActivatedMessage), findsNothing);

    body = gist(enabled: true);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text(TrialExpiredDialog.message), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });
}
