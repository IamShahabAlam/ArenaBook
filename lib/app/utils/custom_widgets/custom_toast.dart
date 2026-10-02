import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:arenabook/app/config/app_assets.dart';
import 'package:arenabook/app/utils/utils.dart';

import '../../config/app_colors.dart';

//TODO  remove this from everywhere and relace it with snack bar made in app alerts file in custom functions

class MyToast {
  /*
  static snackToast(String message, int code, [bool setMiddle = false, Duration duration = const Duration(seconds: 2)]) {
    var img = code == 0
        ? AppAssets.lottie.errorLottie
        : code == 1
            ? AppAssets.lottie.successLottie
            : AppAssets.lottie.infoLottie;

    var color = code == 0
        ? AppColors.errorColorDark
        : code == 1
            ? AppColors.successColorDark
            : Get.theme.colorScheme.outline;
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        backgroundColor: color.withValues(alpha: 0.7),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: setMiddle ? Get.height * 0.4 : 0),
        content: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                options: LottieOptions(),
                animate: true,
                Utils.getLottiePath(img),
                //'assets/lottie/$img.json',
                frameRate: FrameRate.composition,
                height: 40,
                fit: BoxFit.fill,
                alignment: Alignment.center,
                addRepaintBoundary: false,
              ),
              CommonText(
                text: message,
                color: Colors.white,
                weight: AppFontWeights.appTextFontWeightMedium,
              ).fittedBox(280, BoxFit.scaleDown),
            ],
          ),
        )));
  }
*/
  static void snackToast(
    String message,
    int colorCode, [
    bool setOnTop = false,
    Duration duration = const Duration(seconds: 3),
    String? title,
    // SnackPosition? position = SnackPosition.TOP,
    bool? isIconify = true,
  ]) {
    var img = colorCode == 0
        ? AppAssets.lottie.errorLottie
        : colorCode == 1
        ? AppAssets.lottie.successLottie
        : AppAssets.lottie.infoLottie;

    String titleStr =
        title ??
        (colorCode == 0
            ? 'Error'
            : colorCode == 1
            ? 'Success'
            : 'Info');

    Color bgColor = colorCode == 0
        ? AppColors.errorColorDark
        : colorCode == 1
        ? AppColors.successColorDark
        : Get.theme.colorScheme.outline;
    Get.snackbar(
      titleStr,
      message,
      duration: duration,
      animationDuration: Duration(milliseconds: 1500),
      snackPosition: setOnTop ? SnackPosition.TOP : SnackPosition.BOTTOM,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: isIconify == true ? 12 : 25, vertical: 12),
      icon: isIconify == true
          ? Lottie.asset(
              options: LottieOptions(),
              animate: true,
              Utils.getLottiePath(img),
              //'assets/lottie/$img.json',
              frameRate: FrameRate.composition,
              height: 35,
              width: 35,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              addRepaintBoundary: false,
            ).marginSymmetric(horizontal: 5)
          : null,
      backgroundColor: bgColor.withValues(alpha: 0.7),
      colorText: AppColors.appColorWhite,
    );
  }
}
