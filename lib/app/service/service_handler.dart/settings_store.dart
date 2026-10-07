import 'package:get/get.dart';

import '../../../data/models/sport.dart';
import '../../config/app_cache.dart';
import 'cache_field.dart';

/// Arena business settings (currency + an hourly rate per configured sport), saved to prefs.
class SettingsStore extends GetxController {
  static SettingsStore get to => Get.find();

  static const defaultCurrency = 'Rs';
  static const maxHourlyRate = 1000000;

  final currencySymbol = CacheField<String>(AppCache.arena.currencySymbol, defaultCurrency);

  /// One saved rate per sport id; a sport's config `defaultRate` until changed.
  final _rates = <String, CacheField<int>>{for (final s in Sport.all) s.id: CacheField<int>(AppCache.arena.hourlyRate(s.id), s.defaultRate)};

  int rateFor(Sport sport) => _rates[sport.id]?.value ?? sport.defaultRate;

  /// For GetX workers that react to any rate change.
  List<RxInterface<int>> get rateStreams => [for (final f in _rates.values) f.rx];

  Future<void> saveCurrency(String symbol) {
    final trimmed = symbol.trim();
    return currencySymbol.save(trimmed.isEmpty ? defaultCurrency : trimmed);
  }

  /// Rates must be at least 1 (a 0 rate would silently create free bookings).
  Future<void> saveRate(Sport sport, int rate) async => _rates[sport.id]?.save(rate.clamp(1, maxHourlyRate));
}
