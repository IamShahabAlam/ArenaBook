import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arenabook/app/config/app_cache.dart';
import 'package:arenabook/app/service/getx_service/response_cache_service.dart';
import 'package:arenabook/app/service/getx_service/storage_service.dart';

void main() {
  late Directory dir;
  final key32 = List<int>.generate(32, (i) => i); // fixed AES key for tests (the app uses secure storage)

  setUp(() => dir = Directory.systemTemp.createTempSync('response_cache_test'));
  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Future<ResponseCacheService> openCache({bool enabled = true, Duration maxAge = const Duration(days: 7), int maxSize = 1024 * 1024, List<int>? key}) {
    return ResponseCacheService().init(enabled: enabled, maxAge: maxAge, maxSizeBytes: maxSize, encryptionKey: key ?? key32, path: dir.path);
  }

  http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});
  Future<void> tick() => Future.delayed(const Duration(milliseconds: 5));

  test('disabled cache stores and returns nothing', () async {
    final cache = await openCache(enabled: false);
    await cache.write('k', url: 'u', params: '', response: ok('{"a":1}'));
    expect(cache.isEnabled, false);
    expect(await cache.read('k', params: ''), isNull);
  });

  test('write then read returns the same body as a 200 marked as cached', () async {
    final cache = await openCache();
    await cache.write('k', url: 'https://api.test/orders', params: '', response: ok('{"name":"شہاب"}')); // non-latin text survives

    final cached = await cache.read('k', params: '');
    expect(cached!.statusCode, 200);
    expect(jsonDecode(cached.body), {'name': 'شہاب'});
    expect(ResponseCacheService.isFromCache(cached), true);
    expect(ResponseCacheService.savedAtOf(cached), isNotNull);
  });

  test('non-200 responses are never cached', () async {
    final cache = await openCache();
    await cache.write('k', url: 'u', params: '', response: http.Response('{}', 500));
    expect(await cache.read('k', params: ''), isNull);
  });

  test('buildKey: one key per endpoint (params ignored), but separate per user and endpoint', () {
    final defaults = ResponseCacheService.buildKey(method: 'GET', uri: Uri.parse('https://x.com/orders?status=all'), userId: '1');
    final filtered = ResponseCacheService.buildKey(method: 'GET', uri: Uri.parse('https://x.com/orders?status=pending'), userId: '1');
    final otherUser = ResponseCacheService.buildKey(method: 'GET', uri: Uri.parse('https://x.com/orders?status=all'), userId: '2');
    final otherEndpoint = ResponseCacheService.buildKey(method: 'GET', uri: Uri.parse('https://x.com/clients?status=all'), userId: '1');
    expect(defaults, filtered);
    expect(defaults, isNot(otherUser));
    expect(defaults, isNot(otherEndpoint));
  });

  test('canonicalParams ignores param order', () {
    expect(
      ResponseCacheService.canonicalParams(Uri.parse('https://x.com/p?b=2&a=1')),
      ResponseCacheService.canonicalParams(Uri.parse('https://x.com/p?a=1&b=2')),
    );
  });

  test('cached data is only returned when params match exactly', () async {
    final cache = await openCache();
    await cache.write('orders', url: 'u', params: 'page=1&status=all', response: ok('{"a":1}'));

    expect(await cache.read('orders', params: 'page=1&status=all'), isNotNull);
    expect(await cache.read('orders', params: 'page=1&status=pending'), isNull); // different filter -> no cache
    expect(await cache.read('orders', params: 'page=1&status=all'), isNotNull); // mismatch did not delete it
  });

  test('a hit with new params replaces the entry; the old params are no longer served', () async {
    final cache = await openCache();
    await cache.write('orders', url: 'u', params: 'status=all', response: ok('{"v":"all"}'));
    await cache.write('orders', url: 'u', params: 'status=pending', response: ok('{"v":"pending"}'));

    expect(cache.entries.length, 1);
    expect(cache.entries.single.params, 'status=pending');
    expect((await cache.read('orders', params: 'status=pending'))!.body, '{"v":"pending"}');
    expect(await cache.read('orders', params: 'status=all'), isNull);
  });

  test('keys Hive cannot store (non-ASCII or over 255 chars) are skipped, not crashed on', () async {
    final cache = await openCache();
    await cache.write('x' * 300, url: 'u', params: '', response: ok('{}'));
    await cache.write('GET|/شہر|1', url: 'u', params: '', response: ok('{}'));
    expect(cache.entries, isEmpty);
  });

  test('without a test key, a random key is created once in SharedPreferences and reused', () async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    await Get.putAsync(() => StorageService().init());

    var cache = await ResponseCacheService().init(enabled: true, path: dir.path);
    await cache.write('k', url: 'u', params: '', response: ok('{"a":1}'));
    final savedKey = StorageService.to.getString(AppCache.general.responseCacheKey);
    expect(savedKey, isNotEmpty);
    await Hive.close();

    cache = await ResponseCacheService().init(enabled: true, path: dir.path); // restart
    expect(StorageService.to.getString(AppCache.general.responseCacheKey), savedKey);
    expect((await cache.read('k', params: ''))!.body, '{"a":1}');
  });

  test('a new response for the same endpoint replaces the old one (single entry)', () async {
    final cache = await openCache();
    await cache.write('orders', url: 'u', params: 'status=all', response: ok('{"v":1}'));
    await cache.write('orders', url: 'u', params: 'status=all', response: ok('{"v":2}'));

    expect(cache.entries.length, 1);
    expect((await cache.read('orders', params: 'status=all'))!.body, '{"v":2}');
  });

  test('entries older than maxAge are not returned and are wiped', () async {
    final cache = await openCache(maxAge: const Duration(milliseconds: 1));
    await cache.write('k', url: 'u', params: '', response: ok('{}'));
    await tick();

    expect(await cache.read('k', params: ''), isNull);
    expect(cache.entries, isEmpty);
  });

  test('size limit evicts the least recently used entry', () async {
    final body100 = '{"d":"${'x' * 92}"}'; // 100 bytes
    final cache = await openCache(maxSize: 250);

    await cache.write('a', url: 'a', params: '', response: ok(body100));
    await tick();
    await cache.write('b', url: 'b', params: '', response: ok(body100));
    await tick();
    await cache.read('a', params: ''); // 'a' is now more recently used than 'b'
    await tick();
    await cache.write('c', url: 'c', params: '', response: ok(body100)); // 300 bytes > 250 -> evict 'b'

    expect(cache.entries.map((e) => e.key).toSet(), {'a', 'c'});
  });

  test('clear wipes everything (logout)', () async {
    final cache = await openCache();
    await cache.write('k', url: 'u', params: '', response: ok('{}'));
    await cache.clear();
    expect(cache.entries, isEmpty);
  });

  test('data survives a restart with the right key, and is unreadable with a wrong one', () async {
    var cache = await openCache();
    await cache.write('k', url: 'u', params: '', response: ok('{"a":1}'));
    await Hive.close();

    cache = await openCache(); // same key -> "app restart"
    expect((await cache.read('k', params: ''))!.body, '{"a":1}');
    await Hive.close();

    cache = await openCache(key: List<int>.filled(32, 7)); // different key -> encrypted data is useless
    expect(await cache.read('k', params: ''), isNull);
  });
}
