// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter_jailbreak_detection_plus/flutter_jailbreak_detection_plus.dart';
import 'package:get/get.dart';

import '../../utils/custom_functions/logger.dart';

class GetXDeveloperModeManager extends GetxController {
  static GetXDeveloperModeManager get to => Get.find();

  // Developer mode status: true = enabled, false = disabled
  var isDeveloperModeEnabled = false.obs;

  // Timer to periodically check Developer Mode status
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    checkDeveloperMode(); // Initial check
    // _startPeriodicCheck(); // Start periodic monitoring
  }

  @override
  void onClose() {
    // Cancel the timer when the service is disposed
    _timer?.cancel();
    super.onClose();
  }

  // Method to check the current Developer Mode status
  Future<void> checkDeveloperMode() async {
    try {
      if (Platform.isAndroid) {
        isDeveloperModeEnabled.value = await FlutterJailbreakDetectionPlus.developerMode;
        // if (isDeveloperModeEnabled) {
        //   Get.back();
        //   Dialogs.showBlockedDialog();
        // } else {
        //   // if (Get.isDialogOpen == true) {
        //   //   Get.back();
        //   restartApp();
        //   // }
        // }
      }
    } catch (e) {
      Logger.logs('Error checking developer mode: $e');
    }
    update(); // Notify listeners
  }

  // Start periodic checks every 5 seconds
  // void _startPeriodicCheck() {
  //   _timer = Timer.periodic(Duration(seconds: 5), (timer) {
  //     checkDeveloperMode();
  //   });
  // }

  // Show a dialog when Developer Mode is detected
}
