import 'package:get/get.dart';

import '../../service/getx_service/network_service.dart';

/// Add to a controller whose screen should refresh itself when the internet comes back
/// (e.g. after it was showing cached data while offline).
///
/// ```dart
/// class OrdersController extends GetxController with OfflineAware {
///   @override
///   void onReconnect() => fetchOrders();
/// }
/// ```
/// Only opted-in (currently alive) controllers refetch, so reconnecting doesn't fire every API at once.
mixin OfflineAware on GetxController {
  Worker? _reconnectWorker;
  bool _wasOffline = false;

  /// Called once each time the connection goes offline -> online while this controller is alive.
  void onReconnect();

  @override
  void onInit() {
    super.onInit();
    final network = GetXNetworkManager.to;
    _wasOffline = !network.isOnline.value;
    _reconnectWorker = ever<bool>(network.isOnline, (online) {
      if (online && _wasOffline) onReconnect();
      _wasOffline = !online;
    });
  }

  @override
  void onClose() {
    _reconnectWorker?.dispose();
    super.onClose();
  }
}
