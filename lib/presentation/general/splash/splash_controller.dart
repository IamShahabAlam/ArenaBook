import 'dart:async';

import 'package:get/get.dart';

import '../../../app/config/app_strings.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  Timer? _timer;
  var _left = false;

  @override
  void onReady() {
    super.onReady();
    // To block rooted/dev-mode devices, check GetXDeveloperModeManager.to.isDeveloperModeEnabled here
    // and show Dialogs.showBlockedDialog() instead of navigating.
    _timer = Timer(const Duration(milliseconds: AppStrings.splashTime), skip);
  }

  /// Also called by the Skip button. Guarded so the timer and a tap can't navigate twice.
  void skip() {
    if (_left) return;
    _left = true;
    _timer?.cancel();
    Get.offAllNamed(PageNames.shellScreen);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class SplashBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(SplashController());
  }
}
