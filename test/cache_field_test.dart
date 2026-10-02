import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arenabook/app/service/getx_service/storage_service.dart';
import 'package:arenabook/app/service/service_handler.dart/cache_field.dart';

void main() {
  // Fresh in-memory SharedPreferences + StorageService before every test.
  Future<void> setUpStorage([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    Get.reset();
    await Get.putAsync(() => StorageService().init());
  }

  test('uses the default when nothing is cached', () async {
    await setUpStorage();
    final token = CacheField<String>('token', '');
    expect(token.value, '');
  });

  test('loads an already cached value on creation', () async {
    await setUpStorage({'token': 'abc'});
    final token = CacheField<String>('token', '');
    expect(token.value, 'abc');
  });

  test('save updates the value and the cache; delete resets both', () async {
    await setUpStorage();
    final isDark = CacheField<bool>('isDark', false);

    await isDark.save(true);
    expect(isDark.value, true);
    expect(StorageService.to.getBool('isDark'), true);

    await isDark.delete();
    expect(isDark.value, false);
    expect(StorageService.to.containsKey('isDark'), false);
  });

  test('a Map round-trips through JSON', () async {
    await setUpStorage();
    final profile = CacheField<Map<String, dynamic>>('profile', const {});
    await profile.save({'name': 'Shahab', 'id': 7});

    // A new field on the same key simulates an app restart.
    final afterRestart = CacheField<Map<String, dynamic>>('profile', const {});
    expect(afterRestart.value, {'name': 'Shahab', 'id': 7});
  });

  test('int and List<String> are stored natively', () async {
    await setUpStorage();
    final count = CacheField<int>('count', 0);
    final tags = CacheField<List<String>>('tags', const []);

    await count.save(5);
    await tags.save(['a', 'b']);

    expect(CacheField<int>('count', 0).value, 5);
    expect(CacheField<List<String>>('tags', const []).value, ['a', 'b']);
  });
}
