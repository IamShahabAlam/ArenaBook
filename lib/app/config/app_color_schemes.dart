import 'package:flutter/material.dart';

class AppColorSchemes {
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF18191A), //
    // onPrimary: Color(0xFF0044b3), // appColorTitle
    onPrimary: Color(0xFF3088F6), // appColorTitle
    primaryContainer: Color(0xFF242526),
    onPrimaryContainer: Color(0xFF3088F6),
    secondary: Color(0xFF242526), // textfields
    onSecondary: Color(0xFFFFFFFF), // AppColorBlack // FOR TEXT // bodyText 1 & 2
    secondaryContainer: Color(0xFF5595ff), // appColorMain
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF3A3B3C), // appColorBgDark
    onTertiary: Color(0xFFA1A4A8),
    tertiaryContainer: Color(0xFF000000),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xFFE43740),
    errorContainer: Color(0xFFbd0623), // errorColorDark
    onError: Color(0xFF000000),
    onErrorContainer: Color(0xFF410002),
    primaryFixed: Color(0xFF80b0ff), // appColorBgDarker
    onPrimaryFixed: Color(0xFFEFF2FF),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    primaryFixedDim: Color(0xFF18191A),
    onSurfaceVariant: Color(0xFF41484D),
    outline: Color(0xFF616161),
    onInverseSurface: Color(0xFFECF0FF),
    inverseSurface: Color(0xFF002F62),
    inversePrimary: Color(0xFF7FD0FF),
    shadow: Color(0xFF2C2C2C),
    surfaceTint: Color(0xFF00B3F0),
  );

  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFFFFFF), // scaffold
    onPrimary: Color(0xFF0044b3), // appColorTitle
    primaryContainer: Color(0xFFEFF8FF), // loader dialogue bg
    onPrimaryContainer: Color(0xFF9C9999), // appColorGrey
    secondary: Color(0xFFE2F0FD), // appColorBg // textfields
    onSecondary: Color(0xFF000000), // AppColorBlack // FOR TEXT // bodyText 1 & 2
    secondaryContainer: Color(0xFF5595ff), // appColorMain
    onSecondaryContainer: Color(0xFF000000), // AppColorBlack
    tertiary: Color(0xFFb3d0ff), // appColorBgDark
    onTertiary: Color(0x5A000000), // AppColorBlack // Darker Grey
    tertiaryContainer: Color(0xFFFFFFFF),
    onTertiaryContainer: Color(0xFF000000), // AppColorBlack
    error: Color(0xFFE43740),
    errorContainer: Color(0xFFbd0623), // errorColorDark
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFFFFDAD6),
    primaryFixed: Color(0xFF80b0ff), // appColorBgDarker
    onPrimaryFixed: Color(0xFF000000), // AppColorBlack
    surface: Color(0xFFEDF6FF), // appColorBgLight
    onSurface: Color(0xFF000000), // AppColorBlack
    primaryFixedDim: Color(0xFFf5f5f5),
    onSurfaceVariant: Color(0xFFC1C7CE),
    outline: Color(0xFF616161), // Grey Text
    onInverseSurface: Color(0xFF001B3D),
    inverseSurface: Color(0xFF002F62),
    inversePrimary: Color(0xFF00658C),
    shadow: Color(0xFFE4E2E2), // shadow color
    surfaceTint: Color(0xFF00B3F0), // appTextHintFontWeight , appColorPrimary
  );
}
