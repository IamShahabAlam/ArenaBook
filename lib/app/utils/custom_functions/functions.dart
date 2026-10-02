// ignore_for_file: prefer_if_null_operators, use_build_context_synchronously, unused_local_variable, non_constant_identifier_names, avoid_print, invalid_use_of_protected_member

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arenabook/app/config/app_strings.dart';
import 'package:arenabook/app/utils/custom_functions/app_alerts.dart';
import 'package:arenabook/app/utils/custom_widgets/custom_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../routes/app_pages.dart';
import '../custom_widgets/pop_up_dialog.dart';
import 'logger.dart';

// few cutom functions
class Functions {
  //not close to white
  static Color getRandomColorNotCloseToWhite(int index) {
    Random random = Random(index);
    int red, green, blue;

    do {
      red = random.nextInt(256);
      green = random.nextInt(256);
      blue = random.nextInt(256);
    } while ((red + green + blue) > 600); // Filter out light colors

    return Color.fromARGB(255, red, green, blue).withValues(alpha: 0.3);
  }

  static Color getRandomColorNotCloseToBlack() {
    Random random = Random();
    int red, green, blue;

    do {
      red = random.nextInt(256);
      green = random.nextInt(256);
      blue = random.nextInt(256);
    } while ((red + green + blue) > 600 || (red + green + blue) < 150); // Avoid light and very dark colors

    return Color.fromARGB(255, red, green, blue);
  }

  static changeKey(dynamic map, String oldKey, String newKey) {
    if (map.containsKey(oldKey)) {
      // Add new key with the old value
      map[newKey] = map[oldKey];
      // Remove the old key
      map.remove(oldKey);
    }
  }

  // Open Map Function
  static Future<void> openGoogleMap(BuildContext context, String url) async {
    String googleUrl = url;
    if (await canLaunchUrlString(googleUrl)) {
      await launchUrlString(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      MyToast.snackToast('Error found in location', 2, true);
      // Functions.ShowPopUpDialog(
      //   context,
      //   'Error In Location',
      //   Icon(
      //     Icons.error_outline_sharp,
      //     color: Get.theme.colorScheme.onPrimary,
      //     size: 80,
      //   ),
      //   () => {},
      //   false,
      //   isHeader: true,
      //   isCloseBtn: true,
      // );
    }
  }

  // Scale Factor Calculator
  static double getScaleFactor(Size size) {
    if (size.width > 400 && size.width <= 450) {
      return 1.0;
    } else if (size.width > 350 && size.width <= 400) {
      return 0.90;
    } else if (size.width > 300 && size.width <= 350) {
      return 0.80;
    } else if (size.width > 250 && size.width <= 300) {
      return 0.70;
    } else if (size.width > 200 && size.width <= 250) {
      return 0.60;
    } else {
      return 0.50;
    }
  }

  // Phone Dialer
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  // Message Dialer
  static Future<void> makeMessage(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    await launchUrl(launchUri);
  }

  // Email Dialer
  static Future<void> makeEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    await launchUrl(launchUri);
  }

  /// It Opens OS Based Store for App update/ App Rating through thier URL
  static navigateToStore() => Functions.launchURL(Platform.isIOS ? AppStrings.appStoreAddress : AppStrings.playStoreAddress);

  static Future<void> playAttachment(String url) async {
    // final Uri launchUri = Uri(

    //   // scheme: 'Media',
    //   path: url,
    // );
    var parsedurl = Uri.parse(url);
    await launchUrl(parsedurl, mode: LaunchMode.inAppBrowserView);
  }

  // Scrolling to a Expansion Key Tile
  static void scrollToSelectedContent({required GlobalKey expansionTileKey}) {
    final keyContext = expansionTileKey.currentContext;
    if (keyContext != null) {
      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        Scrollable.ensureVisible(keyContext, duration: const Duration(milliseconds: 200));
      });
    }
  }

  // Get Keys Present in a Map in List
  static List<dynamic> getKeysInList(data) {
    var keysPresent = [];
    for (int i = 0; i < data.length; i++) {
      data[i].keys.forEach((key) {
        keysPresent.add(key);
      });
    }
    return keysPresent;
  }

  // Get Grouped By Map
  static dynamic getGroupedByMap(data, String keyToGroup) {
    List result = data
        .fold({}, (previousValue, element) {
          Map val = previousValue as Map;
          String date = element[keyToGroup];
          if (!val.containsKey(date)) {
            val[date] = [];
          }
          val[date]?.add(element);
          return val;
        })
        .entries
        .map((e) => {e.key: e.value})
        .toList();

    return result;
  }

  // Custom Pop up Dialog
  static ShowPopUpDialog(
    BuildContext context,
    String title,
    Widget content,
    VoidCallback onPressYes,
    bool isAction, {
    required bool isCloseBtn,
    required bool isHeader,
    VoidCallback? onPressBack,
    bool? isCancel,
  }) {
    showDialog(
      context: context,
      builder: (_) => PopUpDialog(
        title: title,
        content: content,
        onPressYes: onPressYes,
        isAction: isAction,
        isCancel: isCancel,
        isCloseBtn: isCloseBtn,
        isHeader: isHeader,
      ),
      barrierDismissible: true,
    );
  }

  //convert minutes to hour and minutes   e.g. inputMinutes = 322 => 5H, 22M;

  static List doubleMinuteToHourMinute(int inputMinutes) {
    int hour = 0;
    int minute = 0;

    double time = inputMinutes / 60;
    String str = time.toString();
    if (str.contains('.')) {
      var arrTime = str.split('.');
      hour = int.parse(arrTime[0]);
      minute = (double.parse('0.${arrTime[1]}') * 60).round();
    } else {
      hour = (inputMinutes / 60).round();
    }

    return [hour, minute];
  }

  static String NullAlternateValue(dynamic obj) {
    return obj == null ? '' : obj;
  }

  // Sets the Same Brightness as our default theme while new theme Generation ------------
  static Color adjustColorBrightness(String? hexColor, double targetBrightness) {
    Color color = checkColorCode(hexColor);

    try {
      HSLColor hsl = HSLColor.fromColor(color);
      int maxIterations = 100; // Maximum iterations to avoid infinite loop
      double currentBrightness = color.computeLuminance();

      for (int i = 0; i < maxIterations; i++) {
        double lightnessDelta = targetBrightness - currentBrightness;
        hsl = hsl.withLightness((hsl.lightness + lightnessDelta).clamp(0.0, 1.0));
        currentBrightness = hsl.toColor().computeLuminance();

        if ((currentBrightness - targetBrightness).abs() < 0.01) {
          break; // Break the loop if the brightness is close enough to target
        }
      }

      return hsl.toColor();
    } catch (e) {
      Logger.logs(e);
      return color;
    }
  }

  static Color generateSharpAccent(String? hexColor) {
    final color = checkColorCode(hexColor);

    try {
      final hsl = HSLColor.fromColor(color);

      return hsl
          .withSaturation(0.90) // strong/vivid but not neon
          .withLightness(0.45) // balanced “button-like” sharpness
          .toColor();
    } catch (e) {
      Logger.logs(e);
      return color;
    }
  }

  //  It checks the validity of color codes & can make Lighter and darker shades
  static checkColorCode(String? hexColor, {double amount = 0.0}) {
    try {
      // if (hexColor != null) {
      hexColor = hexColor!.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }

      Color color = Color(int.parse(hexColor, radix: 16));

      // Lighten or darken the color if amount is provided
      if (amount != 0) {
        final double luminance = color.computeLuminance();

        if (amount > 0) {
          // Lighten the color
          color = HSLColor.fromColor(color).withLightness((luminance + 0.05 * amount).clamp(0.0, 1.0)).toColor();
        } else {
          // Darken the color
          color = HSLColor.fromColor(color).withLightness((luminance + 0.05 * amount).clamp(0.0, 1.0)).toColor();
        }
      }

      return color;
    } catch (e) {
      // Logger.logs(e);
      if (amount > 0) {
        // Lighten the default color
        return HSLColor.fromColor(Color(int.parse('FF00b3f0', radix: 16))).withLightness((0.5 + 0.05 * amount).clamp(0.0, 1.0)).toColor();
      } else {
        // Darken the default color
        return HSLColor.fromColor(Color(int.parse('FF00b3f0', radix: 16))).withLightness((0.5 + 0.05 * amount).clamp(0.0, 1.0)).toColor();
      }
    }
  }

  //////////
  static Color checkColorCode2(dynamic colorInput, {double amount = 0.0}) {
    try {
      Color color;

      // Handle string hex input
      if (colorInput is String) {
        String hex = colorInput.toUpperCase().replaceAll("#", "");
        if (hex.length == 6) {
          hex = "FF$hex"; // Add alpha if missing
        }
        color = Color(int.parse(hex, radix: 16));
      }
      // Handle Color input directly
      else if (colorInput is Color) {
        color = colorInput;
      } else {
        throw FormatException("Invalid color input type: $colorInput");
      }

      // Adjust brightness if needed
      if (amount != 0) {
        final hslColor = HSLColor.fromColor(color);
        final adjustedLightness = (hslColor.lightness + 0.05 * amount).clamp(0.0, 1.0);
        color = hslColor.withLightness(adjustedLightness).toColor();
      }

      return color;
    } catch (e) {
      print('Color parsing error: $e');
      // Fallback color: #00b3f0
      final fallback = Color(0xFF00B3F0);
      final hsl = HSLColor.fromColor(fallback);
      final adjustedLightness = (hsl.lightness + 0.05 * amount).clamp(0.0, 1.0);
      return hsl.withLightness(adjustedLightness).toColor();
    }
  }

  // URL Launcher
  static Future<void> launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  // A dynamic null checker function which can give ur given output and results ifNull found!.

  static dynamic nullSwitch(dynamic input, {dynamic output, dynamic ifNull = ''}) {
    try {
      // DebugPrint.log(input.runtimeType.toString());
      if (input != null) {
        if (input is int || input is double) {
          return output ?? input;
        } else {
          if (input.isEmpty) {
            return ifNull;
          } else {
            return output ?? input;
          }
        }
      } else {
        return ifNull;
      }
    } catch (e) {
      Logger.logs('ERROR : $e');
      return ifNull;
    }
  }

  /*
  TODO : NullSwitch update to this 
   
   static dynamic nullSwitch(dynamic input, {dynamic output(), dynamic ifNull = ''}) {
  try {
    if (input != null) {
      if (input is int || input is double) {
        return output != null ? output() : input;
      } else {
        if (input.isEmpty) {
          return ifNull;
        } else {
          return output != null ? output() : input;
        }
      }
    } else {
      return ifNull;
    }
  } catch (e) {
    DebugPrint.log('ERROR : $e');
    return ifNull;
  }
}

// Then call it like this:
Functions.nullSwitch(
  controller.omc.cartItemsList.value, 
  output: () => ' (${controller.omc.cartItemsList.value[0]['DiscountPercentage']}%)'
);
   */
  /*
  static numberFormatter<String>(dynamic number, {dynamic format = '#,##0', int? decimalDigits}) {
    if (number == null) return '';

    if (decimalDigits != null && decimalDigits > 0) {
      var noOfDecimalDigits = '#' * decimalDigits;
      format = '$format.$noOfDecimalDigits';
    }

    return NumberFormat(format).format(number);
  }*/

  static String numberFormatter(dynamic number, {String? format, int? decimalDigits, String locale = 'en_US'}) {
    if (number == null || number == '') return '';

    // If custom format is provided, use it
    if (format != null) {
      return NumberFormat(format, locale).format(number);
    }

    // Else create format based on decimal digits
    NumberFormat formatter = NumberFormat.currency(
      locale: locale,
      decimalDigits: decimalDigits ?? 0,
      symbol: '', // Remove currency symbol
    );

    return formatter.format(number).trim();
  }

  static num numberUnformatter(dynamic input, {String locale = 'en_US'}) {
    if (input == null) return 0;

    // If already num, just return
    if (input is num) return input;

    if (input is String) {
      String value = input.trim();

      // Remove grouping separators (commas, spaces, etc.)
      final separator = NumberFormat.decimalPattern(locale).symbols.GROUP_SEP;
      value = value.replaceAll(separator, '');

      // Convert locale decimal separator to "."
      final decimalSep = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
      if (decimalSep != '.') {
        value = value.replaceAll(decimalSep, '.');
      }

      // Try parsing
      return num.tryParse(value) ?? 0;
    }

    throw ArgumentError('Unsupported type: ${input.runtimeType}');
  }

  /// Finds if Decimal val is > 0 then keep else return an int.
  static String detectNonAbsDecimal(dynamic number) {
    String inputStr = double.parse(number.toString()).toString();
    try {
      var numb = int.parse(inputStr.split('.').last);
      String result;

      if (numb > 0) {
        result = inputStr;
      } else {
        result = inputStr.split('.').first.toString();
        // number.toInt().toString();
      }
      return result;
    } catch (e) {
      print(e);
      return inputStr.split('.').first.toString();
    }
  }

  static String smartNumberFormatter(num value, {int? decimalDigits}) {
    final v = value.toDouble();

    // If decimal is zero, format as integer
    if (v == v.floor()) {
      return numberFormatter(v.toInt(), decimalDigits: 0);
    }

    // Otherwise format with decimals (preserve original precision or use provided)
    return numberFormatter(v, decimalDigits: decimalDigits);
  }


  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Check if the URL has a valid scheme (http or https)
      return (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAbsolutePath;
    } catch (e) {
      // If parsing throws an error, it's not a valid URL
      return false;
    }
  }

  /*
bool isValidUrl(String url) {
  RegExp urlPattern = RegExp(
    r'^https?:\/\/[\w\-]+(\.[\w\-]+)+\s*([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?$',
    caseSensitive: false,
  );
  return urlPattern.hasMatch(url);
}
*/

  // extracts Name from path
  static String extractFileName(String filePath) {
    List<String> parts = filePath.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }


  // For Both Enter Press from a Hardware Keyboard
  static detectEnter(KeyEvent event, Function() function) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.physicalKey == PhysicalKeyboardKey.numpadEnter)) {
      Logger.logs('********* Pressed *************');
      function();
    }
  }

  /// Back-press handler: on the home route asks to exit the app, otherwise navigates to home.
  static void homeOrExitRoute({String? homeRoute, bool doExit = true}) {
    final route = homeRoute ?? PageNames.dashBoardScreen;
    if (Get.currentRoute == route) {
      if (doExit) {
        Dialogs.showCustomAlertDialog(Get.context!, "Do you want to Exit ?", () => exit(0), () => Get.back());
      } else {
        Get.back();
      }
    } else {
      Get.offAllNamed(route);
    }
  }

  static String getOrdinal(num number) {
    if (number <= 0) return number.toString();

    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }

    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  /////////////////////////
  static InlineSpan getOrdinalRich({int number = 1, TextStyle? numberStyle, TextStyle? suffixStyle, String? text, TextStyle? textStyle}) {
    String suffix;

    if (number % 100 >= 11 && number % 100 <= 13) {
      suffix = 'th';
    } else {
      switch (number % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    return TextSpan(
      children: [
        TextSpan(text: '$number', style: numberStyle),
        WidgetSpan(
          child: Transform.translate(
            offset: const Offset(1.5, -5), // Adjust to taste
            child: Text(
              suffix,
              //textScaleFactor: 0.7, // Smaller size
              style: suffixStyle,
            ),
          ),
        ),
        WidgetSpan(child: SizedBox(width: 10)),
        TextSpan(text: text ?? '', style: textStyle), // Add space and text
      ],
    );
  }

  static String firstStringSplitter(String? input, {String splitOn = ','}) {
    if (input == null || input == '' || input == 'null') return '';
    return input.contains(splitOn) ? input.split(splitOn).first : input;
  }

  static bool isRouteDefined(String routeName) {
    return Get.routeTree.routes.any((route) => route.name == routeName);
  }


  static decodedSvg(String? rawSvgString) {
    return rawSvgString!.replaceAll(r'\r', '').replaceAll(r'\n', '').replaceAll(r'\"', '"').replaceAll('"<?xml', '<?xml');
  }

  //calculate the percentage difference between two numbers
  static double calculatePercentageChange(num oldNo, num newNo) {
    if (oldNo == 0) {
      // Avoid division by zero
      return newNo == 0 ? 0.0 : (newNo > 0 ? 100.0 : -100);
    }
    return ((newNo - oldNo) / oldNo) * 100;
  }

  static String generateRandomGuid() {
    final Random random = Random();

    // Generate 4 random bytes => 8 hex chars
    final Uint8List bytes = Uint8List(4)..setAll(0, Iterable<int>.generate(4, (_) => random.nextInt(256)));

    // Convert to hex string
    final String hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    return 'mob-$hex'; // example: mob-a1b2c3d4
  }

  static bool isArabic(String? text) {
    if (text == null || text.isEmpty) return false;
    final arabic = RegExp(r'[\u0600-\u06FF]');
    return arabic.hasMatch(text);
  }

  /// For Descending Only Date wise (O => o)
  static List<dynamic> sortListByDate(inputList, propertName) {
    var sortedList = inputList;
    sortedList.sort((a, b) => (DateTime.parse(b[propertName] ?? '')).compareTo(DateTime.parse(a[propertName] ?? '')));

    return sortedList;
  }
}

// Ths is for quantity field
class DigitsOnlyFormatter extends TextInputFormatter {
  final bool isDecimalAllowed;

  DigitsOnlyFormatter({this.isDecimalAllowed = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String filtered = newValue.text;

    if (isDecimalAllowed) {
      // ✅ Allow only digits and at most one decimal point
      filtered = filtered.replaceAll(RegExp(r'[^0-9.]'), '');
      // Prevent multiple decimals
      if ('.'.allMatches(filtered).length > 1) {
        filtered = oldValue.text;
      }
    } else {
      // ✅ Digits only
      filtered = filtered.replaceAll(RegExp(r'[^0-9]'), '');
    }

    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

// this is also for quantity
class NumberLimitFormatter extends TextInputFormatter {
  final int max;

  NumberLimitFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > max) {
      return oldValue; // reject change
    }
    return newValue;
  }
}
