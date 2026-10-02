import 'package:get/get.dart';
import 'package:arenabook/app/config/app_cache.dart';

import 'cache_field.dart';

// handling Theme mode and Theme Color , saving them to prefs
class ThemeStore extends GetxController {
  static ThemeStore get to => Get.find();

  final isDarkMode = CacheField<bool>(AppCache.themes.isDarkMode, true); // ArenaBook defaults to dark
  final selectedThemeColor = CacheField<String>(AppCache.themes.themeColor, ''); // hex string, '' = default palette
  final userPreferenceId = CacheField<String>(AppCache.themes.themePrefsId, ''); // server-side id of the saved theme

  Future<void> onLogout() async {
    await Future.wait([isDarkMode.delete(), selectedThemeColor.delete(), userPreferenceId.delete()]);
  }
}
