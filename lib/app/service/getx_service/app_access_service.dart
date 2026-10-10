import 'dart:async';
import 'dart:io' show HttpDate;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../data/models/app_access.dart';
import '../../../presentation/arena/dialogs/trial_expired_dialog.dart';
import '../../config/app_cache.dart';
import '../../config/app_client_config.dart';
import '../../config/arena_theme.dart';
import '../service_handler.dart/cache_field.dart';

/// Gist body plus GitHub's own clock (the `Date` header), which the phone owner can't change.
typedef AccessFetch = Future<({String body, DateTime? serverTime})?> Function();

/// Enforces the remote trial switch ([AppAccess]).
/// - The last valid config is cached, so a block holds offline and a broken Gist edit changes nothing.
/// - Before the very first successful fetch there is no config, so the app runs (fail open).
/// - "Now" never goes below the latest time already seen, so rewinding the phone clock doesn't help.
class AppAccessService extends GetxService {
  AppAccessService({AccessFetch? fetch, DateTime Function()? clock}) : _fetch = fetch ?? _fetchGist, _clock = clock ?? DateTime.now;

  static AppAccessService get to => Get.find();

  static const _pollWhileBlocked = Duration(minutes: 1);

  final AccessFetch _fetch;
  final DateTime Function() _clock;
  final _config = CacheField<String>(AppCache.general.accessConfig, '');
  final _latestTime = CacheField<int>(AppCache.general.accessLatestTime, 0);

  final blocked = false.obs;

  /// Days left while a dated trial is running (drawer notice); null otherwise.
  final trialDaysLeft = RxnInt();

  var _guarding = false; // false until the splash has left: the dialog has no screen to cover before that
  DateTime? _fetchedAt;
  Future<void>? _inFlight;
  Route<void>? _dialog;
  Timer? _poll;

  @override
  void onInit() {
    super.onInit();
    _evaluate();
    refresh(); // runs alongside the splash
  }

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  /// Called when the splash finishes: from here on a block shows the dialog.
  void startGuarding() {
    _guarding = true;
    // After the shell route is in place; ensureVisualUpdate so that frame is guaranteed to come.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _evaluate())
      ..ensureVisualUpdate();
  }

  /// Gate before opening the booking form and before Save. Re-checks the rules now and
  /// shows the dialog if blocked; also refetches in the background when the config is older than [maxAge].
  bool allows({Duration maxAge = const Duration(minutes: 1)}) {
    final ok = !_evaluate();
    final at = _fetchedAt;
    if (at == null || _clock().difference(at).abs() >= maxAge) refresh();
    return ok;
  }

  /// Fetches the Gist and re-applies the rules. Concurrent calls share one request.
  Future<void> refresh() => _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<void> _refresh() async {
    _fetchedAt = _clock();
    try {
      final result = await _fetch();
      if (result != null) {
        if (result.serverTime case final server?) _remember(server.millisecondsSinceEpoch);
        if (AppAccess.tryParse(result.body) != null) await _config.save(result.body);
      }
    } catch (_) {
      // Offline or GitHub down: keep the cached config.
    }
    _evaluate();
  }

  /// Applies the rules to the cached config and opens/closes the dialog to match. Returns true if blocked.
  bool _evaluate() {
    final access = AppAccess.tryParse(_config.value);
    final now = _now();
    blocked.value = access?.isBlocked(now) ?? false;
    trialDaysLeft.value = access?.trialDaysLeft(now);
    _syncDialog();
    return blocked.value;
  }

  DateTime _now() {
    final device = _clock().millisecondsSinceEpoch;
    _remember(device);
    return DateTime.fromMillisecondsSinceEpoch(max(device, _latestTime.value));
  }

  // Saved at most once a minute: checks run on every gate and tick, and a minute's drift doesn't matter.
  void _remember(int ms) {
    if (ms > _latestTime.value + 60000) _latestTime.save(ms);
  }

  void _syncDialog() {
    if (!_guarding) return;
    if (blocked.value) {
      _poll ??= Timer.periodic(_pollWhileBlocked, (_) => refresh()); // notices IsAppEnable going back to true
      if (_dialog == null) _showDialog();
    } else {
      _poll?.cancel();
      _poll = null;
      final dialog = _dialog;
      _dialog = null;
      if (dialog != null && dialog.isActive) dialog.navigator?.removeRoute(dialog);
    }
  }

  void _showDialog() {
    final context = Get.context;
    if (context == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.arena.overlay,
      builder: (_) => const TrialExpiredDialog(),
    );
    _dialog = route;
    // If anything ever pops it, forget it so the next check opens it again.
    Navigator.of(context).push(route).whenComplete(() {
      if (_dialog == route) _dialog = null;
    });
  }

  static Future<({String body, DateTime? serverTime})?> _fetchGist() async {
    // Unique query = fresh copy instead of GitHub's 5-minute cached one.
    final uri = Uri.parse(AppClientConfig.accessConfigUrl).replace(queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'});
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    DateTime? server;
    try {
      server = HttpDate.parse(response.headers['date'] ?? '');
    } catch (_) {}
    return (body: response.body, serverTime: server);
  }
}
