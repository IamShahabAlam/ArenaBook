import 'package:get/get.dart';

import '../../config/app_cache.dart';
import '../../config/app_client_config.dart';
import 'cache_field.dart';

// saving the urls to prefs (e.g. when the base url is resolved at runtime / per client)
class UrlsStore extends GetxController {
  static UrlsStore get to => Get.find();

  // Falls back to AppClientConfig.baseUrl when nothing is cached (and after delete).
  final apiUrl = CacheField<String>(AppCache.urls.apiUrl, AppClientConfig.baseUrl);
  final url = CacheField<String>(AppCache.urls.url, '');

  Future<void> onLogout() async {
    await Future.wait([apiUrl.delete(), url.delete()]);
  }
}
