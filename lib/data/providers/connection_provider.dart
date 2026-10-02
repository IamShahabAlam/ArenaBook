import 'dart:async';
import 'dart:io';
import 'package:arenabook/app/utils/custom_functions/logger.dart';
import '../../app/service/service_handler.dart/urls_store.dart';

// Low level reachability probes, used by APIProvider to classify a failed request:
// no internet at all (503) vs. internet ok but server unreachable (523) vs. server slow (524).
class ConnectionProvider {
  static const Duration _internetProbeTimeout = Duration(seconds: 3);
  static const Duration _serverProbeTimeout = Duration(seconds: 3);
  static final _singleton = ConnectionProvider();

  static ConnectionProvider get instance => _singleton;

  Future<bool> canConnectToServer({String? appBaseUrl}) async {
    var baseUrl = appBaseUrl ?? UrlsStore.to.apiUrl.value;

    try {
      final baseUri = Uri.parse(baseUrl);
      return await _probeUri(baseUri, timeout: _serverProbeTimeout);
    } on SocketException {
      Logger.logs('Connection Socket failed @ ConnectionProvider');
      return false;
    } on TimeoutException {
      Logger.logs('Connection Timeout failed @ ConnectionProvider');
      return false;
    } catch (e) {
      Logger.logs('Connection failed @ ConnectionProvider : $e');
      return false;
    }
  }

  Future<bool> checkInternetConnection() async {
    try {
      const endpoints = [
        'https://connectivitycheck.gstatic.com/generate_204',
        'https://clients3.google.com/generate_204',
        'https://cp.cloudflare.com/generate_204',
      ];

      for (final url in endpoints) {
        try {
          final isReachable = await _probeUri(Uri.parse(url), timeout: _internetProbeTimeout);
          if (isReachable) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _probeUri(Uri uri, {required Duration timeout}) async {
    final httpClient = HttpClient()..connectionTimeout = timeout;

    try {
      final request = await httpClient.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      return response.statusCode < 500;
    } finally {
      httpClient.close(force: true);
    }
  }
}
