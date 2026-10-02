import 'package:jiffy/jiffy.dart';

class DateUtility {
  //////////////////////////////////////////////////////////////
  ///for task due date
  static DateTime now = DateTime.now();
  //
  static DateTime startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
  static DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  //
  static DateTime startOfYesterday = startOfToday.subtract(Duration(days: 1));
  static DateTime endOfYesterday = endOfToday.subtract(Duration(days: 1));
  //
  static DateTime startOfTomorrow = startOfToday.add(Duration(days: 1));
  static DateTime endOfTomorrow = endOfToday.add(Duration(days: 1));
  //
  static DateTime startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
  static DateTime endOfWeek = startOfWeek.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  //
  static DateTime startOfLastWeek = startOfWeek.subtract(Duration(days: 7));
  static DateTime endOfLastWeek = endOfWeek.subtract(Duration(days: 7));
  //
  static DateTime startOfNextWeekActual = startOfWeek.add(Duration(days: 7));
  static DateTime endOfNextWeekActual = endOfWeek.add(Duration(days: 7));
  //
  static DateTime startOfMonth = DateTime(now.year, now.month, 1);
  static DateTime endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(seconds: 1));
  //
  static DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
  static DateTime endOfLastMonth = DateTime(now.year, now.month, 1).subtract(Duration(seconds: 1));
  //
  static DateTime startOfNextMonth = DateTime(now.year, now.month + 1, 1);
  static DateTime endOfNextMonth = DateTime(now.year, now.month + 2, 1).subtract(Duration(seconds: 1));
  //
  static DateTime startOfYear = DateTime(now.year, 1, 1);
  static DateTime endOfYear = DateTime(now.year + 1, 1, 1).subtract(Duration(seconds: 1));
  //
  static DateTime startOfLastYear = DateTime(now.year - 1, 1, 1);
  static DateTime endOfLastYear = DateTime(now.year, 1, 1).subtract(Duration(seconds: 1));
  //
  static DateTime startOfNextYear = DateTime(now.year + 1, 1, 1);
  static DateTime endOfNextYear = DateTime(now.year + 2, 1, 1).subtract(Duration(seconds: 1));
  ///////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////
  static DateTime startOfSeleMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfSelectedMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1).subtract(Duration(seconds: 1));
  }

  static DateTime startOfSelectedDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  static DateTime endOfSelectedDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  //////////////////////////////////////////////////////
  static bool isToday(DateTime date) {
    return ((date.isAfter(startOfToday) || date.isAtSameMomentAs(startOfToday))) && ((date.isBefore(endOfToday) || date.isAtSameMomentAs(endOfToday)));
  }

//
  static bool isYesterday(DateTime date) {
    return ((date.isAfter(startOfYesterday) || date.isAtSameMomentAs(startOfYesterday))) &&
        ((date.isBefore(endOfYesterday) || date.isAtSameMomentAs(endOfYesterday)));
  }

//
  static bool isNextDay(DateTime date) {
    return ((date.isAfter(startOfTomorrow) || date.isAtSameMomentAs(startOfTomorrow))) &&
        ((date.isBefore(endOfTomorrow) || date.isAtSameMomentAs(endOfTomorrow)));
  }

//
  static bool isCurrentWeek(DateTime date) {
    return ((date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek))) && ((date.isBefore(endOfWeek) || date.isAtSameMomentAs(endOfWeek)));
  }

//
  static bool isLastWeek(DateTime date) {
    return ((date.isAfter(startOfLastWeek) || date.isAtSameMomentAs(startOfLastWeek))) &&
        ((date.isBefore(endOfLastWeek) || date.isAtSameMomentAs(endOfLastWeek)));
  }

//
  // static bool isNextWeek(DateTime date) {
  //   return ((date.isAfter(startOfNextWeek) || date.isAtSameMomentAs(startOfNextWeek))) &&
  //       ((date.isBefore(endOfNextWeek) || date.isAtSameMomentAs(endOfNextWeek)));
  // }

  static DateTime get startOfNextWeekWhenSunday {
    //  if (now.weekday == DateTime.sunday) {
    // If today is Sunday, next week should start from the Monday after this coming week
    return startOfToday.add(Duration(days: 8));
    // } else {
    //   // If today is any day other than Sunday, next week starts on the upcoming Monday
    //   return startOfNextWeekActual;
    // }
  }

  // // End of the next week from start of next week
  static DateTime get endOfNextWeekWhenSunday {
    //  if (now.weekday == DateTime.sunday) {
    // If today is Sunday, the end of next week is the Sunday after the next week
    return endOfWeek.add(Duration(days: 14)); // Next Sunday after the next week
    // } else {
    // If today is any day other than Sunday, the end of next week is the following Sunday
    //   return endOfNextWeekActual; // This Sunday of the next week
    // }
  }

  static bool isActualNextWeek(DateTime date) {
    return ((date.isAfter(startOfNextWeekActual) || date.isAtSameMomentAs(startOfNextWeekActual))) &&
        ((date.isBefore(endOfNextWeekActual) || date.isAtSameMomentAs(endOfNextWeekActual)));
  }

  // Method to check if a given date falls in the next week, according to the defined start and end
  static bool isNextWeekWhenSunday(DateTime date) {
    return ((date.isAfter(startOfNextWeekWhenSunday) || date.isAtSameMomentAs(startOfNextWeekWhenSunday))) &&
        ((date.isBefore(endOfNextWeekWhenSunday) || date.isAtSameMomentAs(endOfNextWeekWhenSunday)));
  }

//
  static bool isCurrentMonth(DateTime date) {
    return ((date.isAfter(startOfMonth) || date.isAtSameMomentAs(startOfMonth))) && ((date.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth)));
  }

//
  static bool isLastMonth(DateTime date) {
    return ((date.isAfter(startOfLastMonth) || date.isAtSameMomentAs(startOfLastMonth))) &&
        ((date.isBefore(endOfLastMonth) || date.isAtSameMomentAs(endOfLastMonth)));
  }

  //
  static bool isNextMonth(DateTime date) {
    return ((date.isAfter(startOfNextMonth) || date.isAtSameMomentAs(startOfNextMonth))) &&
        ((date.isBefore(endOfNextMonth) || date.isAtSameMomentAs(endOfNextMonth)));
  }

  //
  static bool isCurrentYear(DateTime date) {
    return ((date.isAfter(startOfNextMonth) || date.isAtSameMomentAs(startOfNextMonth))) &&
        ((date.isBefore(endOfNextMonth) || date.isAtSameMomentAs(endOfNextMonth)));
  }

  //
  static bool isLastYear(DateTime date) {
    return ((date.isAfter(startOfNextMonth) || date.isAtSameMomentAs(startOfNextMonth))) &&
        ((date.isBefore(endOfNextMonth) || date.isAtSameMomentAs(endOfNextMonth)));
  }

  //
  static bool isNextYear(DateTime date) {
    return ((date.isAfter(startOfNextMonth) || date.isAtSameMomentAs(startOfNextMonth))) &&
        ((date.isBefore(endOfNextMonth) || date.isAtSameMomentAs(endOfNextMonth)));
  }

///////////////////////////////
////////////////////////////////////
  static String stringForm(DateTime date) {
    return Jiffy.parse(date.toString()).format(pattern: 'dd-MMM-yyyy');
  }

  static String stringFormWeek(DateTime date) {
    return Jiffy.parse(date.toString()).format(pattern: 'EE dd-MMM-yyyy');
  }

 static int getDatedNo(DateTime date) {
  // Get the first day of the year for the given date
  DateTime startOfYear = DateTime(date.year, 1, 1);
  // Calculate the difference in days
  int datedNo = date.difference(startOfYear).inDays + 1; // Add 1 to include the start day
  return datedNo;
}
}
