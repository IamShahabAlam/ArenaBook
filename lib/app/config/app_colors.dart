import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColors {
  //APP Colors ---------------------------------------------------------------
  static const Color appColorPrimary = Color(0xff00b3f0);

  static const Color appColorSecondary = Color(0xFFFFCC00);
  static const Color appColorPrimaryDark = Color(0xFF00351C);
  static const Color appColorAccent = Color(0xFFFBFBFB);
  static const Color appColorBlack = Color(0xFF000000);
  static const Color appColorGrey = Color(0xFF9C9999);
  static const Color appColorTextRed = Color(0xFFBA0C2F);
  static const Color appColorDarkRed = Color(0xFFFF1746);
  static const Color appColorHint = Color(0xFFC6C6C6);
  static const Color appColorLightTextColor = Color(0xFFEDC2CB);
  static const Color appColorTransparent = Color(0xFF0FFFFF);
  static const Color appColorBlue = Color(0xFF0A80FE);
  static const Color appColorLightBlue = Color(0xDA086ACF);
  static const Color appColorTextDarkGray = Color(0xFF484848);
  static const Color appColorTextLightGray = Color(0xFFAAAAAA);
  static const Color appColorSperator = Color(0xFFE3E3E3);
  static const Color appColorIcon = Color(0xFF89C2FE);
  static const Color appColorWhite = Color(0xFFFFFFFF);
  static const Color appColorTextBlack = Color(0xFF111111);
  static const Color appColorSeparator = Color(0xFFd1d1d1);
  static const Color appColorAbsent = Color(0xFFE47F7F); // used for Beta/Stage banner
  static const Color appColorBanner = Color(0xff7ED957);

  // -----------------
  static const Color appColordivider = Color(0xFFBADEFC);
  static const Color textfieldbg = Color(0xFFE2F0FA);

  static const Color fileIconColor = Color(0xFFF5BF38);

  static const Color errorColorDark = Color(0xFFbd0623);
  static const Color errorColorLight = Color(0xFFff6e6b);
  static const Color successColorDark = Color(0xFF069C88);
  static const Color successColorLight = Color(0xFF04E4C6);

  static LinearGradient drawerbgGradient = LinearGradient(
      colors: Get.isDarkMode
          ? [
              Get.theme.colorScheme.onPrimary,
              Get.theme.colorScheme.secondary,
              Get.theme.colorScheme.primary,
              Get.theme.colorScheme.primary,
            ]
          : [
              Get.theme.colorScheme.primaryFixed,
              Get.theme.colorScheme.tertiary,
              Get.theme.colorScheme.secondary,
              Get.theme.colorScheme.primary,
            ],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft);
}
