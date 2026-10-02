import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_client_config.dart';
import '../../../../app/service/service_handler.dart/user_store.dart';
import '../../../../app/utils/api_utility/api_utility.dart';
import '../../../../app/utils/custom_functions/app_alerts.dart';
import '../../../../app/utils/custom_widgets/custom_toast.dart';
import '../../../../data/providers/api_endpoints.dart';
import '../../../../data/repositories/auth_repository/auth_repo.dart';
import '../../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthRepo authRepo = AuthRepo();

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() => isPasswordHidden.value = !isPasswordHidden.value;

  String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    Get.focusScope?.unfocus();

    if (AppClientConfig.baseUrl.isEmpty || ApiEndPoint.user.loginUrl.isEmpty) {
      MyToast.snackToast('Set AppClientConfig.baseUrl & ApiEndPoint.user.loginUrl first', 2);
      return;
    }

    try {
      Dialogs.showProgressBar();
      var response = await authRepo.login(usernameController.text.trim(), passwordController.text);
      Dialogs.hideProgressBar();

      if (response != null && response.statusCode == 200) {
        var respBody = jsonDecode(response.body);
        // Map these keys to your backend's login response.
        await UserStore.to.profile.save(respBody);
        await UserStore.to.loginId.save((respBody['UserId'] ?? '').toString());
        await UserStore.to.token.save((respBody['Token'] ?? respBody['token'] ?? '').toString());

        Get.offAllNamed(PageNames.dashBoardScreen);
      } else if (response != null && response.statusCode == 401) {
        MyToast.snackToast('Invalid username or password', 0);
      }
    } catch (e) {
      Dialogs.hideProgressBar();
      ApiUtility.controllersCatch(e, methodName: 'login()');
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class LoginBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<LoginController>(LoginController());
  }
}
