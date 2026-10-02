import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../../config/app_cache.dart';
import '../../config/app_response_cache_config.dart';
import '../../utils/custom_functions/logger.dart';
import '../service_handler.dart/cache_field.dart';

/// Metadata of one cached response (the body itself lives in the data box).
class CacheEntryInfo {
  CacheEntryInfo({
    required this.key,
    required this.url,
    required this.params,
    required this.savedAt,
    required this.lastAccess,
    required this.sizeBytes,
    required this.contentType,
  });

  final String key; // 'METHOD|scheme://host:port/path|userId' (one entry per endpoint)
  final String url; // readable request url (for the developer list)
  final String params; // canonical query params the response was fetched with; reads must match exactly
  final DateTime savedAt; // when the response was fetched (drives maxAge)
  final DateTime lastAccess; // last read/write (drives LRU eviction)
  final int sizeBytes;
  final String contentType;

  factory CacheEntryInfo.fromMap(String key, Map map) => CacheEntryInfo(
    key: key,
    url: map['url'] as String,
    params: map['params'] as String? ?? '',
    savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int),
    lastAccess: DateTime.fromMillisecondsSinceEpoch(map['lastAccess'] as int),
    sizeBytes: map['sizeBytes'] as int,
    contentType: map['contentType'] as String,
  );

  Map<String, dynamic> toMap() => {
    'url': url,
    'params': params,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'lastAccess': lastAccess.millisecondsSinceEpoch,
    'sizeBytes': sizeBytes,
    'contentType': contentType,
  };

  CacheEntryInfo touched() => CacheEntryInfo(
    key: key,
    url: url,
    params: params,
    savedAt: savedAt,
    lastAccess: DateTime.now(),
    sizeBytes: sizeBytes,
    contentType: contentType,
  );

  @override
  String toString() => '${(sizeBytes / 1024).toStringAsFixed(1)} KB | saved $savedAt | $url';
}

/// Encrypted, size-limited, auto-expiring cache of successful GET responses, used by APIProvider
/// for CachePolicy.networkFirst. Settings come from AppResponseCacheConfig.
///
/// Storage (Hive, AES-256 encrypted):
///  - index box (Box, in memory, small): key -> CacheEntryInfo map  => fast expiry/size/LRU decisions
///  - data box (LazyBox, on disk):       key -> response bytes      => bodies are only loaded when read
class ResponseCacheService extends GetxService {
  static ResponseCacheService get to => Get.find();

  static const _indexBoxName = 'response_cache_index';
  static const _dataBoxName = 'response_cache_data';

  /// Headers added to responses served from cache.
  static const cacheHeader = 'x-cache';
  static const savedAtHeader = 'x-cache-saved-at';

  late bool _enabled;
  late Duration _maxAge;
  late int _maxSizeBytes;
  Box<Map>? _index;
  LazyBox<Uint8List>? _data;

  bool get isEnabled => _enabled && _index != null && _data != null;

  /// Parameters are only for tests; the app uses AppResponseCacheConfig + the key saved in SharedPreferences.
  Future<ResponseCacheService> init({bool? enabled, Duration? maxAge, int? maxSizeBytes, List<int>? encryptionKey, String? path}) async {
    _enabled = enabled ?? AppResponseCacheConfig.enableResponseCache;
    _maxAge = maxAge ?? AppResponseCacheConfig.maxAge;
    _maxSizeBytes = maxSizeBytes ?? AppResponseCacheConfig.maxCacheSizeBytes;

    try {
      path != null ? Hive.init(path) : await Hive.initFlutter();

      if (!_enabled) {
        // Caching switched off: make sure no old (possibly sensitive) data stays on the device.
        await Hive.deleteBoxFromDisk(_indexBoxName);
        await Hive.deleteBoxFromDisk(_dataBoxName);
        return this;
      }

      final cipher = HiveAesCipher(encryptionKey ?? await _loadOrCreateEncryptionKey());
      await _openBoxes(cipher);
      await _removeOrphans();
      await purgeExpired();
    } catch (e) {
      Logger.logs('ResponseCache disabled, init failed: $e');
      _enabled = false;
    }
    return this;
  }

  // ─────────────────── KEYS ───────────────────

  /// ONE key per endpoint per user: query params are deliberately NOT part of the key, so every new response
  /// for the same endpoint replaces the previous one. The params are stored inside the entry instead
  /// (see [canonicalParams]) and a read only succeeds when they match exactly.
  /// Readable on purpose, e.g. 'GET|https://api.example.com:443/orders|12', so `entries` is easy to inspect.
  static String buildKey({required String method, required Uri uri, String userId = ''}) {
    return '${method.toUpperCase()}|${uri.scheme}://${uri.host}:${uri.port}${uri.path}|$userId';
  }

  /// Hive string keys must be ASCII and at most 255 chars; any other key is simply not cached.
  static bool _isValidKey(String key) => key.length <= 255 && key.codeUnits.every((c) => c < 128);

  /// Query params in a stable form (sorted by name), so `?a=1&b=2` and `?b=2&a=1` count as the same.
  static String canonicalParams(Uri uri) =>
      SplayTreeMap<String, String>.of(uri.queryParameters).entries.map((e) => '${e.key}=${e.value}').join('&');

  // ─────────────────── READ / WRITE ───────────────────

  /// Cached response (status 200 + x-cache headers), or null if missing / expired / disabled,
  /// or if it was fetched with different params than [params] (the entry is kept in that case).
  Future<http.Response?> read(String key, {required String params}) async {
    if (!isEnabled || !_isValidKey(key)) return null;
    try {
      final meta = _index!.get(key);
      if (meta == null) return null;

      final info = CacheEntryInfo.fromMap(key, meta);
      if (info.params != params) return null; // different filters: cached data would be misleading
      if (_isExpired(info)) {
        await _remove(key);
        return null;
      }

      final bytes = await _data!.get(key);
      if (bytes == null) {
        await _index!.delete(key); // index without data (e.g. app killed mid-write): self-heal
        return null;
      }

      await _index!.put(key, info.touched().toMap()); // mark as recently used
      return http.Response.bytes(
        bytes,
        200,
        headers: {'content-type': info.contentType, cacheHeader: 'HIT', savedAtHeader: info.savedAt.toIso8601String()},
      );
    } catch (e) {
      Logger.logs('ResponseCache read failed: $e');
      return null;
    }
  }

  /// Saves a successful response, replacing whatever this endpoint had cached before.
  /// Non-200 responses and bodies bigger than the whole limit are ignored.
  Future<void> write(String key, {required String url, required String params, required http.Response response}) async {
    if (!isEnabled || response.statusCode != 200 || !_isValidKey(key)) return;
    final bytes = response.bodyBytes;
    if (bytes.length > _maxSizeBytes) return;

    try {
      final now = DateTime.now();
      // Data first, index second: an interrupted write leaves an orphan that init() removes.
      await _data!.put(key, bytes);
      await _index!.put(
        key,
        CacheEntryInfo(
          key: key,
          url: url,
          params: params,
          savedAt: now,
          lastAccess: now,
          sizeBytes: bytes.length,
          contentType: response.headers['content-type'] ?? 'application/json; charset=utf-8',
        ).toMap(),
      );
      await purgeExpired();
      await _enforceSizeLimit();
    } catch (e) {
      Logger.logs('ResponseCache write failed: $e');
    }
  }

  // ─────────────────── HOUSEKEEPING ───────────────────

  /// Deletes every entry older than maxAge. Runs on app start and after every write.
  Future<void> purgeExpired() async {
    if (!isEnabled) return;
    final expired = entries.where(_isExpired).map((e) => e.key).toList();
    for (final key in expired) {
      await _remove(key);
    }
    if (expired.isNotEmpty) await _compact();
  }

  /// Wipes everything (called on logout).
  Future<void> clear() async {
    if (!isEnabled) return;
    await _index!.clear();
    await _data!.clear();
    await _compact();
  }

  // ─────────────────── DEVELOPER INSIGHT ───────────────────

  /// Every cached entry, most recently used first.
  List<CacheEntryInfo> get entries {
    if (!isEnabled) return [];
    final list = _index!.keys.map((k) => CacheEntryInfo.fromMap(k as String, _index!.get(k)!)).toList();
    list.sort((a, b) => b.lastAccess.compareTo(a.lastAccess));
    return list;
  }

  int get totalSizeBytes => entries.fold(0, (sum, e) => sum + e.sizeBytes);

  /// Prints the cache contents to the debug console.
  void logEntries() {
    final list = entries;
    Logger.logs(
      'ResponseCache: ${list.length} entries, ${(totalSizeBytes / 1024).toStringAsFixed(1)} KB / '
      '${(_maxSizeBytes / 1024 / 1024).toStringAsFixed(0)} MB\n${list.join('\n')}',
    );
  }

  /// Helpers for controllers/views, e.g. to show "Offline - data from 10:42".
  static bool isFromCache(http.Response response) => response.headers[cacheHeader] == 'HIT';
  static DateTime? savedAtOf(http.Response response) => DateTime.tryParse(response.headers[savedAtHeader] ?? '');

  // ─────────────────── INTERNALS ───────────────────

  bool _isExpired(CacheEntryInfo info) => DateTime.now().difference(info.savedAt) > _maxAge;

  Future<void> _remove(String key) async {
    await _index!.delete(key);
    await _data!.delete(key);
  }

  /// Evicts least recently used entries until the cache is under 90% of the limit
  /// (the 10% headroom avoids evicting again on every single write).
  Future<void> _enforceSizeLimit() async {
    var total = totalSizeBytes;
    if (total <= _maxSizeBytes) return;

    final oldestFirst = entries.reversed.toList();
    final target = (_maxSizeBytes * 0.9).floor();
    for (final e in oldestFirst) {
      if (total <= target) break;
      await _remove(e.key);
      total -= e.sizeBytes;
    }
    await _compact();
  }

  /// Hive appends to its files; compacting reclaims the space of deleted entries.
  Future<void> _compact() async {
    await _index!.compact();
    await _data!.compact();
  }

  Future<void> _removeOrphans() async {
    final orphans = _data!.keys.where((k) => !_index!.containsKey(k)).toList();
    for (final key in orphans) {
      await _data!.delete(key);
    }
  }

  Future<void> _openBoxes(HiveAesCipher cipher) async {
    try {
      _index = await Hive.openBox<Map>(_indexBoxName, encryptionCipher: cipher);
      _data = await Hive.openLazyBox<Uint8List>(_dataBoxName, encryptionCipher: cipher);
    } catch (e) {
      // Unreadable (e.g. key lost after reinstall / backup restore). It's only a cache: start fresh.
      Logger.logs('ResponseCache unreadable, recreating: $e');
      await Hive.deleteBoxFromDisk(_indexBoxName);
      await Hive.deleteBoxFromDisk(_dataBoxName);
      _index = await Hive.openBox<Map>(_indexBoxName, encryptionCipher: cipher);
      _data = await Hive.openLazyBox<Uint8List>(_dataBoxName, encryptionCipher: cipher);
    }
  }

  /// Random 256-bit AES key, created once per install and kept in SharedPreferences.
  /// Protects the Hive files from casual inspection; not meant to resist someone with full access to the app's data.
  Future<List<int>> _loadOrCreateEncryptionKey() async {
    final storedKey = CacheField<String>(AppCache.general.responseCacheKey, '');
    if (storedKey.value.isNotEmpty) return base64Decode(storedKey.value);

    final key = Hive.generateSecureKey();
    await storedKey.save(base64Encode(key));
    return key;
  }
}
