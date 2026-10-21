import 'package:get/get.dart';

import '../../../data/models/resource.dart';
import '../../config/app_cache.dart';
import '../../config/app_client_config.dart';
import 'cache_field.dart';

/// Arena business settings (currency + an hourly rate per configured resource type), saved to prefs.
class SettingsStore extends GetxController {
  static SettingsStore get to => Get.find();

  static String get defaultCurrency => AppClientConfig.client.currency;
  static const maxHourlyRate = 1000000;

  final currencySymbol = CacheField<String>(AppCache.arena.currencySymbol, defaultCurrency);

  /// One saved rate per resource type id; its config `defaultRate` until changed.
  final _rates = <String, CacheField<int>>{for (final s in ResourceType.all) s.id: CacheField<int>(AppCache.arena.hourlyRate(s.id), s.defaultRate)};

  int rateFor(ResourceType resourceType) => _rates[resourceType.id]?.value ?? resourceType.defaultRate;

  /// For GetX workers that react to any rate change.
  List<RxInterface<int>> get rateStreams => [for (final f in _rates.values) f.rx];

  Future<void> saveCurrency(String symbol) {
    final trimmed = symbol.trim();
    return currencySymbol.save(trimmed.isEmpty ? defaultCurrency : trimmed);
  }

  /// Rates must be at least 1 (a 0 rate would silently create free bookings).
  Future<void> saveRate(ResourceType resourceType, int rate) async => _rates[resourceType.id]?.save(rate.clamp(1, maxHourlyRate));
}
