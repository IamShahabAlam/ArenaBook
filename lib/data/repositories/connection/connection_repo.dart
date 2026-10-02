// ignore_for_file: avoid_print

import 'package:arenabook/data/providers/connection_provider.dart';

import '../../../app/utils/custom_functions/logger.dart';

class ConnectionRepo {
  getConnectionState({String? baseUrl}) async {
    // as commented in api level class this function will be called for every api call written in api_provider
    try {
      final response = await ConnectionProvider.instance.canConnectToServer(appBaseUrl: baseUrl);

      return response;
    } catch (e) {
      Logger.logs('$e');
    }
  }
}
