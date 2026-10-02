// ignore_for_file: unused_local_variable, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:arenabook/app/config/app_strings.dart';

import '../../config/app_fontweights.dart';
import '../custom_widgets/common_text.dart';
import '../custom_widgets/custom_drop_formfield.dart';
import '../custom_widgets/logo_loader.dart';
import '../custom_widgets/nuemorph_container.dart';
import 'logger.dart';

class DateTimeFunctions {
  // get twelve months date from current date to next 12 months e.g. March 2022 to march 2023
  static DateTime getTwelveMonthsDateTime(DateTime date) {
    var month = date.month;
    var year = date.year;
    var loopCount = 1;
    var countThisYear = 0;
    var countPreviousYear = 0;
    while (loopCount <= 12) {
      if (month > 0) {
        countThisYear += 1;
        month -= 1;
        loopCount += 1;
      } else {
        countPreviousYear += 1;
        month -= 1;
        loopCount += 1;
      }
    }
    if (countPreviousYear != 0) {
      return DateTime.parse('${date.year - 1}-${getMonthNumber(12 - countPreviousYear)}-01T00:00:00');
    } else {
      return DateTime.parse('${date.year}-${getMonthNumber(12 - countThisYear)}-01T00:00:00');
    }
  }

  // Get Month Number (add zero if single digit) -------------------------------
  static String getMonthNumber(int month) {
    if (month < 10) {
      return '0$month';
    } else {
      return '$month';
    }
  }

  DateTime getStartOfPreviousMonth(DateTime dateTime) {
    // Subtract one month from the given DateTime value
    DateTime startOfPreviousMonth = DateTime(dateTime.year, dateTime.month - 1, 1);

    // Return the start of the previous month
    return startOfPreviousMonth;
  }

  DateTime getEndOfPreviousMonth(DateTime dateTime) {
    // Subtract one month from the given DateTime value
    DateTime endOfPreviousMonth = DateTime(dateTime.year, dateTime.month + 1, 1);

    // Return the start of the previous month
    return endOfPreviousMonth;
  }

  // -------------------------------------------------
  static DateTime getLastDateOfMonth(int year, int month) {
    // Check if the month is within valid range (1 to 12) and year is positive
    if (month < 1 || month > 12 || year <= 0) {
      throw ArgumentError('Invalid month or year');
    }

    // Create a DateTime object for the first day of the next month
    DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);

    // Subtract 1 day from the first day of the next month to get the last day of the current month
    DateTime lastDayOfMonth = firstDayOfNextMonth.subtract(const Duration(days: 1));

    return lastDayOfMonth;
  }

  // Get No Of Months -------------------------------
  static int getDaysInMonth(DateTime date) {
    var firstDayThisMonth = DateTime(date.year, date.month, date.day);
    var firstDayNextMonth = DateTime(firstDayThisMonth.year, firstDayThisMonth.month + 1, firstDayThisMonth.day);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  // Get Day Number (add zero if single digit) -------------------------------
  static String getDayNumber(int day) {
    if (day < 10) {
      return '0$day';
    } else {
      return '$day';
    }
  }

  // Formates Date -------------------------------
  static dateFormat(String date, {String pattern = 'dd-MM-yyyy'}) {
    // ignore: unnecessary_null_comparison
    if (date == null || date == '') {
      return date;
    } else {
      String formattedDate = Jiffy.parse(date).format(pattern: pattern);

      return formattedDate;
    }
  }

  // Formates Time -------------------------------
  static String formatTimeOfDay(String date) {
    String result = '';
    if (date.isNotEmpty) {
      final now = DateTime.parse(date);
      final dt = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
      final format = DateFormat.jm();
      result = format.format(dt);
    }
    //"6:00 AM"
    return result;
  }

  /// For Date Before like 60 days before todays date, (Pick a date by giving difference) e.g: input= days: 6 , output: 6 days before today's date.
  static DateTime dateByDifference(Duration duration, {bool isBefore = true}) {
    DateTime result;
    if (isBefore) {
      var dt = DateTime.now().subtract(duration);
      result = DateTime(dt.year, dt.month, dt.day);
    } else {
      var dt = DateTime.now().add(duration);
      result = DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
    }
    return result;
  }

  // counts duration  e.g. 02 days 12 hours 23 minutes. -------------------------------
  static dayHourMinuteFormat(dynamic inputMinutes) {
    int minutes = inputMinutes.inMinutes;
    int days = minutes ~/ (24 * 60);
    int hours = (minutes % (24 * 60)) ~/ 60;
    int remainingMinutes = minutes % 60;

    String timeInString = '';

    if (days > 0) {
      timeInString += '$days days ';
    }
    if (hours > 0) {
      timeInString += '$hours hours ';
    }
    if (remainingMinutes > 0) {
      timeInString += '$remainingMinutes minutes';
    }

    return timeInString;
  }

  // Finds difference in between two dates e.g. 1Y 11M 12D -------------------------------
  static String dateTimeDifference(DateTime? from, DateTime? to) {
    if (from != null && to != null) {
      DateTime fromTime = DateTime(from.year, from.month, from.day);
      DateTime toTime = DateTime(to.year, to.month, to.day);
      int days = (toTime.difference(fromTime).inHours ~/ 24);

      bool isNegative = days < 0;
      days = days.abs();
      String difference = '';

      int years = (days ~/ 365);
      days %= 365;
      int months = (days ~/ 30);
      days %= 30;

      if (years > 0) {
        difference += '${years}Y ';
      }
      if (months > 0) {
        difference += '${months}M ';
      }
      if (days > 0) {
        difference += '${days}D ';
      }

      return isNegative ? '-$difference' : difference;
    }
    return '';
  }

  static String timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() == 1 ? '' : 's'} ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() == 1 ? '' : 's'} ago';
    return '${(diff.inDays / 365).floor()} year${(diff.inDays / 365).floor() == 1 ? '' : 's'} ago';
  }

  // default date time for url params for api call (it sets 1st date and last date of the current month)
  static DateTimeRange setDefaultDateTime() {
    DateTime start = DateTime.parse('${DateTime.now().year}-${DateTimeFunctions.getMonthNumber(DateTime.now().month)}-01T00:00:00');
    DateTime end = DateTime.parse(
      '${DateTime.now().year}-${DateTimeFunctions.getMonthNumber(DateTime.now().month)}-${DateTimeFunctions.getDaysInMonth(DateTime.now())}T23:59:59',
    );
    return DateTimeRange(start: start, end: end);
  }

  // default Today's date time for url params for api call (it sets today's date with )
  static DateTimeRange setTodaysDateTime() {
    DateTime start = DateTime.parse(
      '${DateTime.now().year}-${DateTimeFunctions.getMonthNumber(DateTime.now().month)}-${DateTimeFunctions.getDayNumber(DateTime.now().day)}T00:00:00',
    );
    DateTime end = DateTime.parse(
      '${DateTime.now().year}-${DateTimeFunctions.getMonthNumber(DateTime.now().month)}-${DateTimeFunctions.getDayNumber(DateTime.now().day)}T23:59:59',
    );
    return DateTimeRange(start: start, end: end);
  }

  static String getTimeString(int value) {
    final int hour = value ~/ 60;
    final int minutes = value % 60;
    return '${hour.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}';
  }

  static String getMonthNameFromNumber(int monthNum) {
    String formattedNum = monthNum.toString().padLeft(2, '0'); // e.g., 2 -> '02'
    final match = AppStrings.monthsMap.firstWhere(
      (month) => month['num'] == formattedNum,
      orElse: () => {'name': ''}, // return empty string if not found
    );
    return match['name'] ?? '';
  }

  /// Sets Singular/Plural Texts on counts -------------------------------
  static String setTextOnCount(dynamic count, {required String singleText, required String pluralText}) {
    if (count == null || count == '') return '';
    if (count <= 1) {
      return singleText;
    } else {
      return pluralText;
    }
  }
}

// Date Time Picker Class
class Pickers {
  // Custom Date Picker -------------------------------
  static Future<DateTime?> getDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required BuildContext context,
    String? helptext,
  }) async {
    return await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: context.theme.copyWith(
            colorScheme: context.theme.colorScheme.copyWith(
              onSurface: context.theme.colorScheme.primaryFixed,
              onPrimary: context.theme.colorScheme.tertiary,
              primary: context.theme.colorScheme.onPrimary,
              onPrimaryContainer: context.theme.colorScheme.onPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: context.theme.colorScheme.onSurface,
                backgroundColor: context.theme.colorScheme.surface,
                side: BorderSide(color: context.theme.colorScheme.onSurface),
              ),
            ),
          ),
          child: child!,
        );
      },
      context: Get.context!,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helptext,
    );
  }

  // Custom Time Picker -------------------------------
  static Future<TimeOfDay?> getTimePicker({required BuildContext context, required TimeOfDay initialTime, String? helptext}) async {
    var theme = context.theme.colorScheme;
    return await showTimePicker(
      context: Get.context!,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: helptext,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: context.theme.copyWith(
              colorScheme: theme.copyWith(
                onSurface: theme.primaryFixed,
                onPrimary: theme.tertiary,
                primary: theme.onPrimary,
                onPrimaryContainer: theme.onPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  // Custom Date Range Picker -------------------------------
  static Future<DateTimeRange?> getDateRangePicker({
    DateTimeRange? initialDateRange,
    required DateTime currentDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required BuildContext context,
    String? helptext,
  }) async {
    return await showDateRangePicker(
      initialDateRange: initialDateRange,
      currentDate: currentDate,
      firstDate: firstDate,
      lastDate: lastDate,
      context: Get.context!,
      helpText: helptext,

      builder: (context, child) {
        return Theme(
          data: context.theme.copyWith(
            colorScheme: ColorScheme.light(
              onPrimary: context.theme.colorScheme.onPrimary,
              primary: context.theme.colorScheme.secondary,
              onSurface: context.theme.colorScheme.onPrimary,
              secondaryContainer: context.theme.colorScheme.surface,
            ),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: context.theme.colorScheme.onPrimary)),
          ),
          child: child!,
        );
      },
    );
  }
  // Date Stamps and dateType with custom Date Picker if no Stamps founds -------------------------------

  static Future<Map> dateStamps(
    BuildContext context, {
    bool isDateType = false,
    bool isFilterDatesLoading = false,
    var dateFiltersList,
    dynamic dateTypeList,
    String? dateTypeName,
    String? dateTypeId,
    dynamic selectedDateRange,
    DateTime? start,
    DateTime? end,
    bool enableTimePickWithCustom = false,
  }) async {
    if (dateFiltersList.isNotEmpty) {
      try {
        await Get.dialog(
          barrierDismissible: true,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Dialog(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              child: isFilterDatesLoading == true
                  ? LogoLoader()
                  : dateFiltersList.isEmpty
                  ? const Center(child: Text('No data'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Type -----------------------------
                        !isDateType
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date Type',
                                    style: TextStyle(color: Get.theme.colorScheme.primary, fontSize: 12.0, fontWeight: AppFontWeights.appTextFontWeightMedium),
                                  ),
                                  Container(
                                    height: 35,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: CustomDropDownFormField(
                                      value: dateTypeId ?? 'DataEntryDate',
                                      items: dateTypeList.map<DropdownMenuItem<String>>((form) {
                                        return DropdownMenuItem<String>(
                                          onTap: () {
                                            dateTypeId = form["Id"].toString();
                                            dateTypeName = form['Name'].toString();
                                          },
                                          value: form['Id'],
                                          child: Text(form['Name'], style: TextStyle(color: Get.theme.colorScheme.onSecondary)),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        dateTypeId = value.toString();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 12),
                        Text(
                          'Date Stamps',
                          style: TextStyle(color: Get.theme.colorScheme.primary, fontSize: 12.0, fontWeight: AppFontWeights.appTextFontWeightMedium),
                        ),

                        // DATE STAMPS -----------------------------
                        ListView.builder(
                          primary: false,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: dateFiltersList.length + 1,
                          itemBuilder: (context, i) {
                            return i == dateFiltersList.length
                                // FOR CUSTOM  ====================
                                ? InkWell(
                                    onTap: () async {
                                      var myMap = await customDateRangePicker(context, selectedDateRange, start, end);
                                      TimeOfDay? startTime;
                                      TimeOfDay? endTime;
                                      if (enableTimePickWithCustom == true) {
                                        startTime = await getTimePicker(context: context, initialTime: TimeOfDay.now(), helptext: 'Start Time');
                                        endTime = await getTimePicker(context: context, initialTime: TimeOfDay.now(), helptext: 'End Time');
                                      }

                                      start = (enableTimePickWithCustom == true) ? arrangeDateTime(myMap['start'], startTime) : myMap['start'];
                                      end = (enableTimePickWithCustom == true) ? arrangeDateTime(myMap['end'], endTime) : myMap['end'];
                                      selectedDateRange = myMap['selectedDateRange'];

                                      Get.back();
                                    },
                                    child: NuemorphContainer(
                                      isShadow: false,
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      height: 30,
                                      isGradient: false,
                                      child: const Center(
                                        child: CommonText(text: 'Custom', fontSize: 16.0, weight: AppFontWeights.appTextFontWeightExtraLight),
                                      ),
                                    ),
                                  )
                                // FOR LIST  ====================
                                : InkWell(
                                    onTap: () {
                                      start = DateTime.parse(
                                        // Jiffy.parse(
                                        dateFiltersList[i]['FromDate'],
                                      );
                                      // .toString()).format(pattern: 'yyyy-MM-dd'));
                                      end = DateTime.parse(
                                        // Jiffy.parse(
                                        dateFiltersList[i]['ToDate'],
                                      );
                                      // .toString()).format(pattern: 'yyyy-MM-dd 23:59:59'));
                                      // update();

                                      selectedDateRange = DateTimeRange(start: start!, end: end!);

                                      Get.back();
                                    },
                                    child: NuemorphContainer(
                                      isShadow: false,
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      height: 30,
                                      isGradient: false,
                                      child: Center(
                                        child: CommonText(
                                          text: dateFiltersList[i]['Period'],
                                          fontSize: 16.0,
                                          weight: AppFontWeights.appTextFontWeightExtraLight,
                                        ),
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
            ),
          ),
        );

        return isDateType
            ? {'dateTypeId': dateTypeId, 'dateTypeName': dateTypeName, 'start': start, 'end': end, 'selectedDateRange': selectedDateRange}
            : {'start': start, 'end': end, 'selectedDateRange': selectedDateRange};
      } catch (e) {
        Get.back();
        Logger.logs(e);
        return isDateType
            ? {'dateTypeId': dateTypeId, 'dateTypeName': dateTypeName, 'start': start, 'end': end, 'selectedDateRange': selectedDateRange}
            : {'start': start, 'end': end, 'selectedDateRange': selectedDateRange};
      }
    } else {
      var myMap = await customDateRangePicker(context, selectedDateRange, start, end);
      TimeOfDay? startTime;
      TimeOfDay? endTime;
      if (enableTimePickWithCustom == true) {
        startTime = await getTimePicker(context: context, initialTime: TimeOfDay.now(), helptext: 'Start Time');
        endTime = await getTimePicker(context: context, initialTime: TimeOfDay.now(), helptext: 'End Time');
      }

      start = (enableTimePickWithCustom == true) ? arrangeDateTime(myMap['start'], startTime) : myMap['start'];
      end = (enableTimePickWithCustom == true) ? arrangeDateTime(myMap['end'], endTime) : myMap['end'];
      selectedDateRange = myMap['selectedDateRange'];
      return isDateType
          ? {'dateTypeId': dateTypeId, 'dateTypeName': dateTypeName, 'start': start, 'end': end, 'selectedDateRange': selectedDateRange}
          : {'start': start, 'end': end, 'selectedDateRange': selectedDateRange};
    }
  }

  // Custom Date Range Picker return values as Map -------------------------------
  static Future<Map> customDateRangePicker(BuildContext context, selectedDateRange, start, end) async {
    DateTimeRange? selectedRange = await getDateRangePicker(
      initialDateRange: selectedDateRange,
      currentDate: DateTime.now(),
      firstDate: DateTime(1990, 1),
      lastDate: DateTime(2090, 12),
      context: context,
      helptext: 'Select Range',
    );

    if (selectedRange != null) {
      start = DateTime.parse(Jiffy.parse(selectedRange.start.toString()).format(pattern: 'yyyy-MM-dd'));
      end = DateTime.parse(Jiffy.parse(selectedRange.end.toString()).format(pattern: 'yyyy-MM-dd 23:59:59'));
      selectedDateRange = DateTimeRange(start: selectedRange.start, end: selectedRange.end);
    }
    return {'start': start, 'end': end, 'selectedDateRange': selectedDateRange};
  }

  static Future<String> dateAndTimePicker({
    // Set help text for both time and date if needed.
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required TimeOfDay initialTime,
  }) async {
    String selectedDateTimeStr = '';
    await getDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate).then((selectedDate) async {
      // After selecting the date, display the time picker.
      if (selectedDate != null) {
        await getTimePicker(context: context, initialTime: initialTime).then((selectedTime) {
          // Handle the selected date and time here.
          if (selectedTime != null) {
            DateTime selectedDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
            selectedDateTimeStr = selectedDateTime.toString();
          }
        });
      }
    });
    return selectedDateTimeStr;
  }

  static DateTime arrangeDateTime(DateTime? date, TimeOfDay? time) {
    return DateTime(date!.year, date.month, date.day, time!.hour, time.minute, 0, 0, 0);
  }
}
