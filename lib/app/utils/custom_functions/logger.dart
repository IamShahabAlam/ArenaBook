import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class Logger {
  static logs(dynamic str) {
    if (kDebugMode) {
      // TODO: Implement error and stacktrace
      log(str.toString(), name: Get.currentRoute);
      // 21-07-2025 ; Shahb ; Tried all Console Options ; log() turned out winner
      // print(str);
      // debugPrint(str);
    }
  }
}
