import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/app_colors.dart';
import 'package:arenabook/app/config/app_fontweights.dart';

class AppTextStyles {
  static TextStyle splashSubtitleTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.appColorWhite.withValues(alpha: 0.6),
    fontSize: 20.0,
    letterSpacing: 1.8,
  );
  static const TextStyle splashTextStyle = TextStyle(
    fontWeight: AppFontWeights.appTextFontWeightMedium,
    color: AppColors.appColorWhite,
    fontSize: 30.0,
    letterSpacing: 1.8,
  );

  // Banner Text Style ---------------

  static const TextStyle bannerTextStyle = TextStyle(color: Colors.white, letterSpacing: 2.2, fontWeight: AppFontWeights.appTextFontWeightBold, fontSize: 12);

  static TextStyle get appBarTextStyle => TextStyle(
    fontWeight: FontWeight.bold,
    color: Get.context!.theme.colorScheme.onPrimaryContainer,
    fontSize: 20.0,
    // fontFamily: 'Poppins'
  );
}
