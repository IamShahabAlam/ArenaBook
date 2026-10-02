import 'package:flutter_test/flutter_test.dart';

import 'package:arenabook/app/utils/api_utility/api_utility.dart';
import 'package:arenabook/app/utils/custom_functions/datetime_functions.dart';
import 'package:arenabook/app/utils/custom_functions/functions.dart';

// Unit tests for the pure (platform independent) helpers shipped with the starter.
void main() {
  group('Functions', () {
    test('getOrdinal handles teens and regular suffixes', () {
      expect(Functions.getOrdinal(1), '1st');
      expect(Functions.getOrdinal(2), '2nd');
      expect(Functions.getOrdinal(3), '3rd');
      expect(Functions.getOrdinal(11), '11th');
      expect(Functions.getOrdinal(22), '22nd');
    });

    test('nullSwitch returns fallback for null/empty', () {
      expect(Functions.nullSwitch(null, ifNull: '--'), '--');
      expect(Functions.nullSwitch('', ifNull: '--'), '--');
      expect(Functions.nullSwitch('abc'), 'abc');
      expect(Functions.nullSwitch(0), 0);
    });

    test('calculatePercentageChange avoids divide by zero', () {
      expect(Functions.calculatePercentageChange(0, 0), 0.0);
      expect(Functions.calculatePercentageChange(50, 100), 100.0);
    });
  });

  group('DateTimeFunctions', () {
    test('dateTimeDifference formats years, months and days', () {
      expect(DateTimeFunctions.dateTimeDifference(DateTime(2024, 1, 1), DateTime(2024, 1, 11)), '10D ');
      expect(DateTimeFunctions.dateTimeDifference(null, DateTime(2024)), '');
    });

    test('getMonthNumber pads single digits', () {
      expect(DateTimeFunctions.getMonthNumber(3), '03');
      expect(DateTimeFunctions.getMonthNumber(12), '12');
    });
  });

  group('ApiUtility', () {
    test('encryptBase64Credentials builds a Basic auth token', () {
      expect(ApiUtility.encryptBase64Credentials('user', 'pass'), 'dXNlcjpwYXNz');
    });
  });

  group('DigitsOnlyFormatter', () {
    test('strips non digits', () {
      final result = DigitsOnlyFormatter().formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '12a3'));
      expect(result.text, '123');
    });

    test('allows a single decimal point when enabled', () {
      final formatter = DigitsOnlyFormatter(isDecimalAllowed: true);
      expect(formatter.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '1.5')).text, '1.5');
      expect(formatter.formatEditUpdate(const TextEditingValue(text: '1.5'), const TextEditingValue(text: '1.5.')).text, '1.5');
    });
  });
}
