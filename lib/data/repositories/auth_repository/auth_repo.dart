import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../app/service/getx_service/response_cache_service.dart';
import '../../../app/service/getx_service/theme_manager.dart';
import '../../../app/service/service_handler.dart/urls_store.dart';
import '../../../app/service/service_handler.dart/user_store.dart';
import '../../../app/utils/api_utility/api_utility.dart';
import '../../../app/utils/custom_functions/logger.dart';
import '../../../routes/app_pages.dart';
import '../../providers/api_endpoints.dart';
import '../../providers/api_provider.dart';

//repo level class which calls network function from api_provider class
//these functions are then called in getx controllers to update states based on their response
//this is for all auth functions called in all auth screens eg. login / logout
class AuthRepo {
  // login user api call
  Future<http.Response?> login(String username, String password) async {
    var loginHeader = {
      "Authorization": "Basic ${ApiUtility.encryptBase64Credentials(username, password)}",
      "Content-Type": "application/json",
    };
    try {
      final response = await APIProvider.instance.request(
        showSCExceptions: false,
        method: Method.post,
        endpoint: ApiEndPoint.user.loginUrl,
        authHeaders: loginHeader,
      );

      return response;
    } catch (e) {
      Logger.logs('error with user login $e');
      return null;
    }
  }

  // logout user api call
  Future<http.Response?> logout() async {
    try {
      final response = await APIProvider.instance.request(
        showSCExceptions: false,
        method: Method.post,
        endpoint: ApiEndPoint.user.logoutUrl,
      );

      return response;
    } catch (e) {
      Logger.logs('error with user logout $e');
      return null;
    }
  }

  // update password api call
  Future<http.Response?> updatePassword(Map<String, dynamic> payload) async {
    try {
      final response = await APIProvider.instance.request(
        method: Method.post,
        endpoint: ApiEndPoint.user.updatePasswordUrl,
        bodyMap: payload,
      );

      return response;
    } catch (e) {
      Logger.logs('error with update password $e');
      return null;
    }
  }

  /// Clears every cached session store and sends the user to login.
  /// Add your own stores' onLogout() here as you create them.
  static Future<void> clearSession() async {
    await UserStore.to.onLogout();
    await UrlsStore.to.onLogout();
    await ThemeManager.to.onLogout();
    await ResponseCacheService.to.clear(); // no cached API data survives a logout
    Get.offAllNamed(PageNames.loginScreen);
  }
}
