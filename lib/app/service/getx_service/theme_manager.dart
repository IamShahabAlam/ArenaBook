// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/custom_functions/logger.dart';
import '../service_handler.dart/theme_store.dart';
import '../../utils/custom_functions/functions.dart';
import '../../config/app_color_schemes.dart';

// Builds light/dark ThemeData from a single seed (hex) color and persists the choice via ThemeStore.
// To sync theme with a backend, call your repo inside saveThemeData() / getThemeData().
class ThemeManager extends GetxController {
  static ThemeManager get to => Get.find();
  var themeList = [].obs;
  var selectedThemeColor = ''.obs;
  var isDarkMode = false.obs;
  var userPreferenceId = ''.obs;
  var themeTitle = ''.obs;

  // ----------------

  @override
  void onInit() {
    readThemeRawJson('assets/theme/rawTheme.json');

    super.onInit();
  }

  Future<void> readThemeRawJson(String obj) async {
    try {
      String response = await rootBundle.loadString(obj);
      themeList.value = jsonDecode(response);
      getThemeData();
    } catch (e) {
      Logger.logs('ERROR IN READING THEME JSON : $e');
    }
    update();
  }

  Future<void> saveThemeData(String setColor, bool setMode, String setTitle) async {
    await ThemeStore.to.selectedThemeColor.save(setColor);
    await ThemeStore.to.isDarkMode.save(setMode);
    selectedThemeColor.value = setColor;
    isDarkMode.value = setMode;
    themeTitle.value = setTitle;
    updateColorScheme();
    update();
  }

  Future<void> toggleDarkMode() async {
    await saveThemeData(selectedThemeColor.value, !isDarkMode.value, themeTitle.value);
  }

  Future<void> getThemeData() async {
    try {
      selectedThemeColor.value = ThemeStore.to.selectedThemeColor.read();
      isDarkMode.value = ThemeStore.to.isDarkMode.read();
      userPreferenceId.value = ThemeStore.to.userPreferenceId.read();

      updateColorScheme();
    } catch (e) {
      Logger.logs('ERROR IN GETTING THEME COLOR : $e');
    }

    update();
  }

  // -------------------------------------------
  var darkColorScheme = AppColorSchemes.dark.obs;

  var lightColorScheme = AppColorSchemes.light.obs;
  // -------------------------------------------
  Rx<ThemeData> get defaultLightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: lightColorScheme.value,
    primaryColor: lightColorScheme.value.secondaryContainer,
    scaffoldBackgroundColor: lightColorScheme.value.primary,
    // APBAR THEME -----------------
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.value.secondary,
      foregroundColor: lightColorScheme.value.onPrimary,
      elevation: 4.0,
      shadowColor: lightColorScheme.value.surface,
      centerTitle: true,
      titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: lightColorScheme.value.onSecondary, fontSize: 20.0, fontFamily: 'Poppins'),
    ),
    // TextTheme --------------------
    textTheme: GoogleFonts.robotoFlexTextTheme(
      TextTheme(
        bodyLarge: TextStyle(color: lightColorScheme.value.onSecondary),
        bodyMedium: TextStyle(color: lightColorScheme.value.onSecondary),
      ),
    ),

    ///
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: lightColorScheme.value.primary,
      alignment: Alignment.center,
      iconColor: lightColorScheme.value.onPrimary,
      elevation: 12.0,
      titleTextStyle: TextStyle(color: lightColorScheme.value.onPrimary),
      contentTextStyle: TextStyle(color: lightColorScheme.value.onSecondary),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(lightColorScheme.value.onPrimary),
      ),
    ),

    // TextField Theme -------------------------
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: lightColorScheme.value.onPrimary,
      selectionHandleColor: lightColorScheme.value.onPrimary,
      selectionColor: lightColorScheme.value.secondaryContainer,
    ),

    // ListTile Theme ------------------------------
    listTileTheme: const ListTileThemeData(visualDensity: VisualDensity.compact, dense: true),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(lightColorScheme.value.tertiary),
      trackColor: WidgetStatePropertyAll<Color>(lightColorScheme.value.tertiary.withValues(alpha: 0.2)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: lightColorScheme.value.primary),
  ).obs;

  Rx<ThemeData> get defaultDarkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: darkColorScheme.value,
    primaryColor: darkColorScheme.value.secondaryContainer,
    scaffoldBackgroundColor: darkColorScheme.value.primary,
    // APBAR THEME -----------------
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.value.secondary,
      foregroundColor: darkColorScheme.value.onPrimary,
      elevation: 4.0,
      shadowColor: darkColorScheme.value.surface,
      centerTitle: true,
      titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: darkColorScheme.value.onSecondary, fontSize: 20.0, fontFamily: 'Poppins'),
    ),
    // TextTheme --------------------
    textTheme: GoogleFonts.robotoFlexTextTheme(
      TextTheme(
        bodyLarge: TextStyle(color: darkColorScheme.value.onSecondary),
        bodyMedium: TextStyle(color: darkColorScheme.value.onSecondary),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: darkColorScheme.value.primary,
      alignment: Alignment.center,
      iconColor: darkColorScheme.value.onPrimary,
      elevation: 12.0,
      titleTextStyle: TextStyle(color: darkColorScheme.value.onPrimary),
      contentTextStyle: TextStyle(color: darkColorScheme.value.onSecondary),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(darkColorScheme.value.onPrimary),
      ),
    ),

    // TextField Theme -------------------------
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: darkColorScheme.value.onPrimary,
      selectionHandleColor: darkColorScheme.value.onPrimary,
      selectionColor: darkColorScheme.value.secondaryContainer,
    ),
    // ListTile Theme ------------------------------
    listTileTheme: const ListTileThemeData(visualDensity: VisualDensity.compact, dense: true),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(darkColorScheme.value.tertiary),
      trackColor: WidgetStatePropertyAll<Color>(darkColorScheme.value.tertiary.withValues(alpha: 0.2)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: darkColorScheme.value.primary),
  ).obs;

  // --------------------------------------------

  void updateColorScheme() {
    // FOR LIGHT MODE
    if (selectedThemeColor.value.isNotEmpty) {
      try {
        lightColorScheme.value = ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFFFFFFFF), // scaffold
          onPrimary: Functions.adjustColorBrightness(selectedThemeColor.value, 0.07388917719357102), // appColorTitle
          primaryContainer: Functions.adjustColorBrightness(selectedThemeColor.value, 0.9270552565734236), // loader dialogue bg
          onPrimaryContainer: const Color(0xFF9C9999), // appColorGrey
          secondary: Functions.adjustColorBrightness(selectedThemeColor.value, 0.855807763078998), // appColorBg // textfields
          onSecondary: const Color(0xFF000000), // AppColorBlack // FOR TEXT // bodyText 1 & 2
          secondaryContainer: Functions.adjustColorBrightness(selectedThemeColor.value, 0.3064618695637558), // appColorMain
          onSecondaryContainer: const Color(0xFF000000), // AppColorBlack
          tertiary: Functions.adjustColorBrightness(selectedThemeColor.value, 0.5191545613461705), // appColorBgDark
          onTertiary: const Color(0x5A000000), // AppColorBlack // Darker Grey
          tertiaryContainer: const Color(0xFFFFFFFF),
          onTertiaryContainer: const Color(0xFF000000), // AppColorBlack
          error: const Color(0xFFE43740),
          errorContainer: const Color(0xFFbd0623), // errorColorDark
          onError: const Color(0xFFFFFFFF),
          onErrorContainer: const Color(0xFFFFDAD6),
          primaryFixed: Functions.adjustColorBrightness(selectedThemeColor.value, 0.42859862291639533), // appColorBgDarker
          onPrimaryFixed: const Color(0xFF000000), // AppColorBlack
          surface: Functions.adjustColorBrightness(selectedThemeColor.value, 0.9113605926285169), // appColorBgLight
          onSurface: const Color(0xFF000000), // AppColorBlack
          primaryFixedDim: const Color(0xFFf5f5f5),
          onSurfaceVariant: const Color(0xFFC1C7CE),
          outline: const Color(0xFF616161), // Grey Text
          onInverseSurface: Functions.adjustColorBrightness(selectedThemeColor.value, 0.011207878466963136),
          inverseSurface: Functions.generateSharpAccent(selectedThemeColor.value),
          inversePrimary: Functions.adjustColorBrightness(selectedThemeColor.value, 0.1120081056025926),
          shadow: const Color(0xFFE4E2E2), // shadow color
          surfaceTint: Functions.adjustColorBrightness(selectedThemeColor.value, 0.3853146978920506), // appColorPrimary
        );

        // FOR DARK MODE

        darkColorScheme.value = ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF18191A),
          onPrimary: Functions.adjustColorBrightness(selectedThemeColor.value, 0.24890518188614275), // appColorTitle
          primaryContainer: const Color(0xFF242526),
          onPrimaryContainer: Functions.adjustColorBrightness(selectedThemeColor.value, 0.24890518188614275),
          secondary: const Color(0xFF242526), // textfields
          onSecondary: const Color(0xFFFFFFFF), // FOR TEXT // bodyText 1 & 2
          secondaryContainer: Functions.adjustColorBrightness(selectedThemeColor.value, 0.3064618695637558), // appColorMain
          onSecondaryContainer: const Color(0xFFFFFFFF),
          tertiary: const Color(0xFF3A3B3C), // appColorBgDark
          onTertiary: const Color(0xFFA1A4A8),
          tertiaryContainer: const Color(0xFF000000),
          onTertiaryContainer: const Color(0xFFFFFFFF),
          error: const Color(0xFFE43740),
          errorContainer: const Color(0xFFbd0623), // errorColorDark
          onError: const Color(0xFF000000),
          onErrorContainer: const Color(0xFF410002),
          primaryFixed: Functions.adjustColorBrightness(selectedThemeColor.value, 0.42859862291639533), // appColorBgDarker
          onPrimaryFixed: const Color(0xFFEFF2FF),
          surface: const Color(0xFF000000),
          onSurface: const Color(0xFFFFFFFF),
          primaryFixedDim: const Color.fromARGB(255, 54, 48, 48),
          onSurfaceVariant: const Color(0xFF41484D),
          outline: const Color(0xFF616161),
          onInverseSurface: Functions.adjustColorBrightness(selectedThemeColor.value, 0.8737304335470611),
          inverseSurface: Functions.generateSharpAccent(selectedThemeColor.value),
          inversePrimary: Functions.adjustColorBrightness(selectedThemeColor.value, 0.5684377629409924),
          shadow: const Color(0xFF2C2C2C),
          surfaceTint: const Color(0xFF00B3F0),
        );
      } catch (e) {
        Logger.logs('ERROR IN UPDATING THEME $e');
      }
    } else {
      resetDefaultTheme();
    }

    update();
  }

  void resetDefaultTheme() {
    selectedThemeColor.value = '';
    themeTitle.value = '';

    ThemeStore.to.selectedThemeColor.delete();

    darkColorScheme.value = AppColorSchemes.dark;

    lightColorScheme.value = AppColorSchemes.light;
    update();
  }

  Future<void> onLogout() async {
    ThemeStore.to.onLogout();
    themeTitle.value = '';
    getThemeData();
    update();
  }
}
