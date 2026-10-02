// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:arenabook/app/service/getx_service/app_dev_mode_service.dart';
import 'package:arenabook/app/config/app_client_config.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/repositories/auth_repository/auth_repo.dart';
import '../../config/app_assets.dart';
import '../../config/app_strings.dart';
import '../../service/service_handler.dart/user_store.dart';
import '../custom_functions/app_alerts.dart';
import '../custom_functions/logger.dart';
import '../custom_widgets/custom_toast.dart';

// some functions specifically used to handle api calls
class ApiUtility {
  // encoding the credentials to base64 format (for Basic Auth headers)
  static String encryptBase64Credentials(String username, String password) {
    String credentials = '$username:$password';
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    return encoded;
  }

  static String encryptBase64Response(String response) {
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(response);
    return encoded;
  }

  // default headers for authenticated requests (adjust keys to your backend's contract)
  static Map<String, String> requestHeaders() {
    var userStore = UserStore.to;
    try {
      return {
        'Content-Type': 'application/json',
        'UserId': userStore.loginId.value,
        'Token': userStore.token.value,
      };
    } catch (e) {
      Logger.logs(e);
      return {};
    }
  }

  static void displayMessagePerStatusCode(int? code) {
    Map messagesPerCode = {
      // 401: AppStrings.apiUnauthorizeErrorMsg, // Handled Separately at bottom
      404: AppStrings.apiNotFoundErrorMsg,
      422: AppStrings.apiInvalidDataErrorMsg,
      500: AppStrings.apiServerErrorMsg, // Artificial
      503: AppStrings.youAreOfflineMsg, // Artificial
      511: AppStrings.somethingWRMsg, // Artificial
      523: AppStrings.apiServerOffErrorMsg,
      524: AppStrings.apiTimeoutErrorMsg,
    };

    Get.closeAllSnackbars();
    if (Get.isSnackbarOpen == false) {
      if (code == null || messagesPerCode.keys.contains(code) == true) {
        MyToast.snackToast(code == null ? AppStrings.somethingWRMsg : messagesPerCode[code], 2);
      } else if (code == 401) {
        Get.isDialogOpen == true
            ? null
            : Dialogs.myLottieDialog(
                Get.context,
                isDismissible: false,
                lottieName: AppAssets.lottie.errorLottie,
                showCloseIcon: false,
                title: 'Session Expired',
                text: 'Your session has expired, please login again',
                isBottomButton: true,
                bottomName: 'Re-Login',
                bottomFunc: () => AuthRepo.clearSession(),
              );
      } else if (code != 510 && code > 300) {
        MyToast.snackToast(AppStrings.apiUnknownErrorMsg, 0);
      }
    }
  }

  static void logCurlCommand({required String url, required String method, Map<String, String>? headers, Map<String, dynamic>? body}) {
    final buffer = StringBuffer();

    buffer.write("curl -X ${method.toUpperCase()} '$url'");

    headers?.forEach((key, value) {
      buffer.write(" -H '$key: $value'");
    });

    if (body != null && body.isNotEmpty) {
      final bodyString = jsonEncode(body);
      buffer.write(" -d '$bodyString'");
    }

    Logger.logs('\n🔹 CURL Command:\n$buffer\n');
  }

  static String httpMethodString(Method method) {
    Map methodsMap = {
      Method.get: 'GET',
      Method.post: 'POST',
      Method.put: 'PUT',
      Method.patch: 'PATCH',
      Method.delete: 'DELETE',
      Method.multiPartPost: 'MultiPartPOST',
    };

    return methodsMap[method] ?? 'GET';
  }

  // use in every controller's catch block: shows the exception in dev mode, a generic toast otherwise
  static void controllersCatch(exception, {required String methodName}) {
    if (DeveloperService.to.isDevMode.value) {
      Dialogs.myLottieDialog(
        Get.context,
        lottieName: AppAssets.lottie.infoLottie,
        showCloseIcon: true,
        title: 'Controller Exception',
        text: '$methodName\n\n${exception.toString()}',
        textAlign: TextAlign.left,
      );
    } else {
      Logger.logs('$methodName\n\n${exception.toString()}');
      MyToast.snackToast(AppStrings.somethingWRMsg, 0);
    }
  }

  static String responseToCurlString(http.Response? response) {
    dynamic request = response?.request;
    if (request != null && request is http.Request) {
      request = response?.request as http.Request;
    }
    if (response == null || request == null) {
      return "// ❌ No request found in response. Can't generate cURL.";
    }

    final buffer = StringBuffer();

    // Start with curl command
    buffer.writeln('curl --location \'${request.url}\' \\');

    // Add method explicitly if not GET (curl defaults to GET)
    if (request.method.toUpperCase() != 'GET') {
      buffer.writeln("--request '${request.method}' \\");
    }

    request.headers.forEach((key, value) {
      buffer.writeln("--header '$key: $value' \\");
    });

    // Add body if POST/PUT/PATCH
    if (request.body.isNotEmpty && ['POST', 'PUT', 'PATCH', 'DELETE'].contains(request.method.toUpperCase())) {
      // Escape single quotes for shell
      String escapedBody = request.body.replaceAll("'", "'\"'\"'");
      buffer.writeln("-d '$escapedBody' \\");
    }

    // Remove trailing \ from last line
    String result = buffer.toString();
    if (result.endsWith(' \\\n')) {
      result = result.substring(0, result.length - 3); // remove trailing \ and newline
    } else if (result.endsWith('\\')) {
      result = result.substring(0, result.length - 1);
    }

    return result.toString();
  }

  static String generateCurl(http.MultipartRequest request) {
    final buffer = StringBuffer();

    buffer.write("curl -X ${request.method} '${request.url}' \\\n");

    request.headers.forEach((k, v) {
      buffer.write("  -H '$k: $v' \\\n");
    });

    request.fields.forEach((k, v) {
      buffer.write("  -F '$k=$v' \\\n");
    });

    for (var file in request.files) {
      buffer.write("  -F '${file.field}=@${file.filename}' \\\n");
    }

    return buffer.toString();
  }

  // Picks the base url per build flavour (Beta/Stage -> stage server).
  static String setupInitialBaseUrl() {
    return AppStrings.kappVersionWithDate.toLowerCase().contains('beta') && AppClientConfig.stageBaseUrl.isNotEmpty
        ? AppClientConfig.stageBaseUrl
        : AppClientConfig.baseUrl;
  }
}
