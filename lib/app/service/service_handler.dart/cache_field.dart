import 'dart:convert';

import 'package:get/get.dart';

import '../getx_service/storage_service.dart';

/// One cached value = one SharedPreferences key + one reactive (Obx-friendly) variable, always in sync.
///
/// ```dart
/// final token = CacheField<String>(AppCache.user.token, '');
///
/// token.value        // current value (rebuilds Obx widgets when it changes)
/// token.save('abc')  // updates the variable AND the cache
/// token.read()       // reloads from cache (normally not needed, the constructor already reads)
/// token.delete()     // removes from cache, variable goes back to the default
/// ```
///
/// Supported types: String, bool, int, List&lt;String&gt; natively; anything else (e.g. Map) is stored as JSON.
///
/// Rules:
/// - The default must NOT be null (its type decides how the value is read/written).
/// - For Map/List values, don't mutate in place (`profile.value['x'] = 1`); save a new one instead:
///   `profile.save({...profile.value, 'x': 1})`.
/// - StorageService must be initialized before a CacheField is created (InitBindings guarantees this).
class CacheField<T> {
  CacheField(this.key, this.defaultValue) : _rx = Rx<T>(defaultValue) {
    read(); // load the saved value as soon as the field is created
  }

  final String key;
  final T defaultValue;
  final Rx<T> _rx;

  /// Current value. Reading it inside Obx() makes that widget rebuild when the value changes.
  T get value => _rx.value;

  /// The reactive variable, for GetX workers (`ever(field.rx, ...)`). Write only through [save].
  RxInterface<T> get rx => _rx;

  /// Loads the value from the cache (or the default if nothing is saved) and returns it.
  T read() {
    final storage = StorageService.to;
    if (!storage.containsKey(key)) return _rx.value = defaultValue;

    // The type of the default decides which prefs getter to use.
    final Object? stored = switch (defaultValue) {
      String() => storage.getString(key),
      bool() => storage.getBool(key),
      int() => storage.getInt(key),
      List<String>() => storage.getList(key),
      _ => jsonDecode(storage.getString(key)), // Map / other types are stored as JSON strings
    };
    return _rx.value = stored as T;
  }

  /// Updates the reactive value immediately, then writes it to the cache.
  Future<void> save(T newValue) async {
    _rx.value = newValue;
    final storage = StorageService.to;
    await switch (newValue) {
      String v => storage.setString(key, v),
      bool v => storage.setBool(key, v),
      int v => storage.setInt(key, v),
      List<String> v => storage.setList(key, v),
      _ => storage.setString(key, jsonEncode(newValue)),
    };
  }

  /// Removes the key from the cache and resets the reactive value to the default.
  Future<void> delete() async {
    _rx.value = defaultValue;
    await StorageService.to.remove(key);
  }
}
