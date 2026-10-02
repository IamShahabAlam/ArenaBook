import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../app/service/getx_service/booking_service.dart';
import '../../../app/service/service_handler.dart/settings_store.dart';
import '../../../data/repositories/booking/booking_repository.dart';

import '../../../app/service/getx_service/app_dev_mode_service.dart';
import '../../../app/service/getx_service/developer_mode_service.dart';
import '../../../app/service/getx_service/network_service.dart';
import '../../../app/service/getx_service/response_cache_service.dart';
import '../../../app/service/getx_service/storage_service.dart';
import '../../../app/service/getx_service/theme_manager.dart';
import '../../../app/service/service_handler.dart/theme_store.dart';
import '../../../app/service/service_handler.dart/urls_store.dart';
import '../../../app/service/service_handler.dart/user_store.dart';
import '../../../data/providers/api_provider.dart';

// App-wide (permanent) dependencies. Order matters: StorageService must be ready before any store reads prefs.
class InitBindings implements Bindings {
  @override
  Future<void> dependencies() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Storage Service used for Prefs
    await Get.putAsync(() => StorageService().init());
    // Encrypted offline API response cache (Hive). Controlled by AppResponseCacheConfig.
    await Get.putAsync(() => ResponseCacheService().init());

    Get.put<DeveloperService>(DeveloperService());
    Get.put<GetXDeveloperModeManager>(GetXDeveloperModeManager());
    // For Network Connectivity checks
    Get.put<GetXNetworkManager>(GetXNetworkManager());

    // Urls Stored in Prefs
    Get.put<UrlsStore>(UrlsStore());
    // User Data stored in prefs
    Get.put<UserStore>(UserStore());
    // Theme Stored in Prefs
    Get.put<ThemeStore>(ThemeStore());
    // Theme Manager (reads ThemeStore)
    Get.put<ThemeManager>(ThemeManager());

    // ArenaBook ---------------------------------------------------------------
    // Currency + hourly rates (prefs)
    Get.put<SettingsStore>(SettingsStore());
    // Bookings ledger (Hive). Initialising Hive again is safe; it only sets the storage path.
    await Hive.initFlutter();
    final bookingRepository = await HiveBookingRepository.open();
    await Get.putAsync<BookingService>(() => BookingService(bookingRepository).init(), permanent: true);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    // FOR SSL Issues (Https) -- see AppHttpOverrides warning before shipping
    HttpOverrides.global = AppHttpOverrides();
  }
}
