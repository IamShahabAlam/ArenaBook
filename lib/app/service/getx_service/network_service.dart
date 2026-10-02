import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/custom_functions/app_alerts.dart';
import '../../../routes/app_pages.dart';
import '../../utils/custom_functions/logger.dart';

class GetXNetworkManager extends GetxController {
  static GetXNetworkManager get to => Get.find();

  // Connection type: 0 = No Internet, 1 = connected to WIFI, 2 = connected to Mobile Data.
  int connectionType = 0;

  // Reactive online flag (listen with ever()/Obx, e.g. OfflineAware refetches when it turns true).
  final isOnline = false.obs;

  // Instance of Flutter Connectivity
  final Connectivity _connectivity = Connectivity();

  // Stream to keep listening to network change state
  late StreamSubscription<List<ConnectivityResult>> _streamSubscription;

  @override
  void onClose() {
    // Stop listening to network state when app is closed
    _streamSubscription.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    getConnectionType();
    _streamSubscription = _connectivity.onConnectivityChanged.listen(_updateState);
    super.onInit();
  }

  // A method to check the connection status (internet connection type)
  Future<void> getConnectionType() async {
    List<ConnectivityResult>? connectivityResult;
    try {
      connectivityResult = await (_connectivity.checkConnectivity());
    } on PlatformException catch (e) {
      Logger.logs(e);
    }
    return _updateState(connectivityResult ?? [ConnectivityResult.none]);
  }

  // State update method based on network connectivity, connectionType set to 1 (WIFI), 2 (Mobile Data), or 0 (None)
  void _updateState(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      connectionType = 1;
    } else if (results.contains(ConnectivityResult.mobile)) {
      connectionType = 2;
    } else {
      connectionType = 0;

      if (Get.currentRoute != PageNames.splashscreen) {
        Dialogs.showNetworkMessageForSplash();
      }
    }

    isOnline.value = connectionType != 0;
    update(); // Update the UI
  }

  // Function to check connectivity of internet globally
  void checkConnectivity() {
    getConnectionType();
    update();
  }
}
