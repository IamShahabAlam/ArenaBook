import 'package:get/get.dart';
import 'package:arenabook/app/config/app_cache.dart';

import 'cache_field.dart';

// when user is logged in the response we get in the form of map is saved in the prefs
// some keys and values are used for api calls as url parametes or a value in the payload in api calls
class UserStore extends GetxController {
  static UserStore get to => Get.find();

  final profile = CacheField<Map<String, dynamic>>(AppCache.user.profile, const {});
  final loginId = CacheField<String>(AppCache.user.userId, '');
  final token = CacheField<String>(AppCache.user.token, '');

  /// Single source of truth for "is there an active session".
  bool get isLoggedIn => token.value.isNotEmpty;

  Future<void> onLogout() async {
    await Future.wait([profile.delete(), loginId.delete(), token.delete()]);
  }
}
