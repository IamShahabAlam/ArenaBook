import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/service/getx_service/app_access_service.dart';
import '../../../app/service/getx_service/booking_service.dart';
import '../booking_form/booking_form_controller.dart';
import '../bookings/bookings_controller.dart';
import '../calendar/calendar_controller.dart';
import '../home/home_controller.dart';

enum ArenaTab { home, bookings, addBooking, pending, calendar }

/// Bottom-navigation shell. Tabs live in an IndexedStack, so each keeps its scroll position and filters.
class ShellController extends GetxController with WidgetsBindingObserver {
  static ShellController get to => Get.find();

  final tab = ArenaTab.home.obs;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _clock;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      BookingService.to.tick();
      AppAccessService.to.allows(maxAge: const Duration(minutes: 5)); // a disable date can pass while the app is open
    });
  }

  @override
  void onClose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    BookingService.to.tick();
    AppAccessService.to.refresh();
  }

  void go(ArenaTab value) {
    FocusManager.instance.primaryFocus?.unfocus();
    tab.value = value;
  }

  /// Android back: close the drawer, else return to Home, else let the system exit.
  bool handleBack() {
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      scaffoldKey.currentState?.closeDrawer();
      return true;
    }
    if (tab.value != ArenaTab.home) {
      go(ArenaTab.home);
      return true;
    }
    return false;
  }
}

class ShellBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ShellController());
    Get.put(BookingFormController());
    Get.put(HomeController());
    Get.put(BookingsController());
    Get.put(CalendarController());
  }
}
