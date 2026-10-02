import 'package:intl/intl.dart';

import '../../service/service_handler.dart/settings_store.dart';

/// Display formatting in one place, so every screen shows money and dates the same way.
class ArenaFormat {
  ArenaFormat._();

  static final _grouped = NumberFormat('#,##0', 'en_US');

  /// "Rs 1,500" — whole numbers only (spec). Pass [symbol] in tests; the app uses the saved setting.
  /// Reading the setting inside Obx makes the text update when the currency changes.
  static String money(int amount, {String? symbol}) => '${symbol ?? SettingsStore.to.currencySymbol.value} ${_grouped.format(amount)}';

  static String number(int value) => _grouped.format(value);

  /// "Wed, 1 Oct"
  static String shortDay(DateTime d) => DateFormat('EEE, d MMM').format(d);

  /// "Oct 1, 2026"
  static String longDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  /// "Wed"
  static String weekdayShort(DateTime d) => DateFormat('EEE').format(d);

  /// "Oct"
  static String monthShort(DateTime d) => DateFormat('MMM').format(d);

  /// "October 2026"
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  /// "Today", "Tomorrow" or "Wed, 1 Oct"
  static String relativeDay(DateTime day, DateTime now) {
    // UTC midnights so a daylight-saving day (23h/25h) can't break the day count.
    final diff = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return shortDay(day);
  }

  static String hours(int minutes) {
    final h = minutes / 60;
    return '${h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1)} hr${h == 1 ? '' : 's'}';
  }
}
