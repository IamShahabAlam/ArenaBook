import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// base getx service for shared preferneces
class StorageService extends GetxService {
  static StorageService get to => Get.find();
  late final SharedPreferences _prefs;

// initializing the instance of shared_pref
//this function is called once in main file
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  Future<bool> setList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  String getString(String key) {
    return _prefs.getString(key) ?? '';
  }

  bool getBool(String key) {
    return _prefs.getBool(key) ?? false;
  }

  List<String> getList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  int getInt(String key) {
    return _prefs.getInt(key) ?? 0;
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}
