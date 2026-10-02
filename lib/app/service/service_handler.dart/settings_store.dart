import 'package:get/get.dart';

import '../../../data/models/sport.dart';
import '../../config/app_cache.dart';
import 'cache_field.dart';

/// Arena business settings (currency + hourly rates), saved to prefs.
class SettingsStore extends GetxController {
  static SettingsStore get to => Get.find();

  static const defaultCurrency = 'Rs';
  static const defaultCricketRate = 1500;
  static const defaultPadelRate = 2000;
  static const maxHourlyRate = 1000000;

  final currencySymbol = CacheField<String>(AppCache.arena.currencySymbol, defaultCurrency);
  final cricketHourlyRate = CacheField<int>(AppCache.arena.cricketHourlyRate, defaultCricketRate);
  final padelHourlyRate = CacheField<int>(AppCache.arena.padelHourlyRate, defaultPadelRate);

  int rateFor(Sport sport) => switch (sport) {
    Sport.cricket => cricketHourlyRate.value,
    Sport.padel => padelHourlyRate.value,
  };

  Future<void> saveCurrency(String symbol) {
    final trimmed = symbol.trim();
    return currencySymbol.save(trimmed.isEmpty ? defaultCurrency : trimmed);
  }

  /// Rates must be at least 1 (a 0 rate would silently create free bookings).
  Future<void> saveRate(Sport sport, int rate) {
    final safe = rate.clamp(1, maxHourlyRate);
    return switch (sport) {
      Sport.cricket => cricketHourlyRate.save(safe),
      Sport.padel => padelHourlyRate.save(safe),
    };
  }
}
