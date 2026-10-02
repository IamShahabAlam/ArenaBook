import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/config/app_strings.dart';
import '../../../app/service/service_handler.dart/theme_store.dart';
import '../../../app/service/service_handler.dart/user_store.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    waitAndNavigate();
    super.onInit();
  }

  // Splash navigation
  Future<void> waitAndNavigate() async {
    // To block rooted/dev-mode devices, check GetXDeveloperModeManager.to.isDeveloperModeEnabled here
    // and show Dialogs.showBlockedDialog() instead of navigating.
    await Future.delayed(const Duration(milliseconds: AppStrings.splashTime));

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: ThemeStore.to.isDarkMode.value ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: ThemeStore.to.isDarkMode.value ? Brightness.light : Brightness.dark,
      ),
    );

    if (UserStore.to.isLoggedIn) {
      Get.offAllNamed(PageNames.dashBoardScreen);
    } else {
      Get.offAllNamed(PageNames.loginScreen);
    }
  }
}

class SplashBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}
