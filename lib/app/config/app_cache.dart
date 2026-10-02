// ignore_for_file: library_private_types_in_public_api

// Shared Preferences keys, grouped by feature. Add a new group per module.
class AppCache {
  static _User get user => _User();
  static _URLs get urls => _URLs();
  static _Themes get themes => _Themes();
  static _General get general => _General();
}

class _User {
  final String profile = 'Profile';
  final String userId = 'UserId';
  final String token = 'Token';
}

class _URLs {
  final String apiUrl = "ApiUrl";
  final String url = "Url";
}

class _Themes {
  final String isDarkMode = "isDarkMode";
  final String themeColor = "ThemeColor";
  final String themePrefsId = "userPreferenceId";
}

class _General {
  final String devMode = "dev_mode";
  final String responseCacheKey = "ResponseCacheKey"; // AES key of the offline API response cache (base64)
}
