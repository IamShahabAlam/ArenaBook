// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class Utils {
  static String getImagePath(String name, {String format = 'png'}) {
    return 'assets/images/$name.$format';
  }

  static String getSvgFilePath(String name, {String format = 'svg'}) {
    return 'assets/svg/$name.$format';
  }

  static String getLottiePath(String name, {String format = 'json'}) {
    return 'assets/lottie/$name.$format';
  }

  static String numberFormatter(dynamic number, {String format = '#,##0.##'}) {
    return NumberFormat(format).format(number);
  }
}
