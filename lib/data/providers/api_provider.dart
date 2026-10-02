import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:arenabook/app/config/app_strings.dart';
import 'package:arenabook/app/service/getx_service/app_dev_mode_service.dart';
import 'package:arenabook/app/service/getx_service/network_service.dart';
import 'package:arenabook/app/service/getx_service/response_cache_service.dart';
import 'package:arenabook/app/service/service_handler.dart/urls_store.dart';
import 'package:arenabook/app/service/service_handler.dart/user_store.dart';
import 'package:arenabook/app/utils/api_utility/api_utility.dart';
import 'package:arenabook/app/utils/custom_functions/logger.dart';
import 'package:arenabook/app/utils/custom_widgets/custom_toast.dart';
import 'package:arenabook/data/providers/connection_provider.dart';

// enums for http method selection
enum Method { get, post, delete, put, patch, multiPartPost }

/// Per-request offline behaviour, chosen in the repository.
/// networkOnly  -> always the network, never reads or writes the cache (default).
/// networkFirst -> network when possible (and the 200 response is cached); if the network fails,
///                 the cached copy is returned (status 200 + x-cache headers) with an error notice.
///
/// Rules:
/// - ONE cache entry per endpoint (per user). Every successful networkFirst hit replaces the old entry
///   (data + params), whatever its params are.
/// - The cached copy is only returned when the request params match the cached params exactly.
/// - Only applies to GET, and only when AppResponseCacheConfig.enableResponseCache is true.
enum CachePolicy { networkOnly, networkFirst }

class APIProvider {
  // static const requestTimeOut = Duration(seconds: 20);
  static const List<Duration> _retryDelays = [Duration(milliseconds: 800), Duration(milliseconds: 1600)];
  static final _singleton = APIProvider();

  static APIProvider get instance => _singleton;
  final _client = http.Client();

  // base function for any type of api call defining their method endponts and headers etc.
  // this function is called for every api call at the repository level of our app
  //
  // authHeaders: null -> default auth headers (ApiUtility.requestHeaders), {} -> no headers, map -> those headers.
  // Artificial status codes: 510 no network interface, 503 offline, 523 server offline, 524 timeout, 511 unknown failure.
  Future<http.Response> request({
    required String endpoint,
    Map<String, dynamic>? urlParams,
    dynamic bodyMap,
    Map<String, String>? authHeaders,
    Method method = Method.get,
    String? appBaseUrl,
    bool showSCExceptions = true,
    CachePolicy cachePolicy = CachePolicy.networkOnly,
  }) async {
    // defining default base url if not
    var baseUrl = appBaseUrl ?? UrlsStore.to.apiUrl.value;
    //defining default headers if not provided as a parameter to the function
    Map<String, String>? headers = authHeaders == null
        ? ApiUtility.requestHeaders()
        : authHeaders.isEmpty
        ? null
        : authHeaders;
    //defining body
    var body = bodyMap ?? jsonEncode({});
    var parsedURI = Uri.parse(baseUrl);
    Uri uri = Uri(scheme: parsedURI.scheme, host: parsedURI.host, port: parsedURI.port, path: endpoint, queryParameters: urlParams);

    http.Response? response;
    final hasNetworkInterface = GetXNetworkManager.to.connectionType != 0;

    final backupReq = http.Request(ApiUtility.httpMethodString(method), uri);

    // Offline cache: GET + networkFirst + global switch on (isEnabled is false when the config is off).
    final useCache = cachePolicy == CachePolicy.networkFirst && method == Method.get && ResponseCacheService.to.isEnabled;
    final cacheKey = useCache ? ResponseCacheService.buildKey(method: 'GET', uri: uri, userId: UserStore.to.loginId.value) : '';
    final cacheParams = useCache ? ResponseCacheService.canonicalParams(uri) : '';

    try {
      if (hasNetworkInterface == false) {
        response = http.Response(jsonEncode({"message": AppStrings.noInternetConnectionErrorMsg}), 510, request: backupReq);

        final cached = useCache ? await ResponseCacheService.to.read(cacheKey, params: cacheParams) : null;
        if (cached != null) {
          _showCachedDataFeedback(failure: response, cached: cached, showSCExceptions: showSCExceptions);
          return cached;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.closeAllSnackbars();
          if (Get.isSnackbarOpen == false) {
            MyToast.snackToast(AppStrings.noInternetConnectionErrorMsg, 2, false, const Duration(seconds: 2));
          }
        });
        return response;
      }
      response = await _sendRequestWithRetry(uri: uri, headers: headers, body: body, method: method);

      Logger.logs('${uri.toString()} || ${response.statusCode}');

      if (useCache && response.statusCode == 200) {
        // Not awaited: saving to disk must not delay showing fresh data.
        unawaited(ResponseCacheService.to.write(cacheKey, url: uri.toString(), params: cacheParams, response: response));
      }

      _handleResponseFeedback(response: response, showSCExceptions: showSCExceptions);
      return response;
    } on TimeoutException catch (error) {
      response = await _buildFailureResponse(request: backupReq, appBaseUrl: appBaseUrl, error: error);
    } on SocketException catch (error) {
      response = await _buildFailureResponse(request: backupReq, appBaseUrl: appBaseUrl, error: error);
    } on HttpException catch (error) {
      response = await _buildFailureResponse(request: backupReq, appBaseUrl: appBaseUrl, error: error);
    } catch (error) {
      Logger.logs('Request failed @ APIProvider : $error');
      response = http.Response(jsonEncode({"message": AppStrings.somethingWRMsg}), 511, request: backupReq);
    }

    // Network failed (offline / server unreachable / timeout): fall back to the cached copy if allowed.
    if (useCache) {
      final cached = await ResponseCacheService.to.read(cacheKey, params: cacheParams);
      if (cached != null) {
        _showCachedDataFeedback(failure: response, cached: cached, showSCExceptions: showSCExceptions);
        return cached;
      }
    }

    _handleResponseFeedback(response: response, showSCExceptions: showSCExceptions);
    return response;
  }

  /// Cached data is being shown instead of a failed request: tell the user why, and when the data is from.
  void _showCachedDataFeedback({required http.Response failure, required http.Response cached, required bool showSCExceptions}) {
    Logger.logs('Served from cache: ${failure.request?.url} || ${failure.statusCode}');

    if (DeveloperService.to.isDevMode.value) {
      DeveloperService.to.showDevErrorDialog(failure);
      return;
    }
    if (!showSCExceptions) return;

    String reason = AppStrings.noInternetConnectionErrorMsg;
    try {
      reason = jsonDecode(failure.body)['message'] ?? reason;
    } catch (_) {}
    final savedAt = ResponseCacheService.savedAtOf(cached);
    final when = savedAt == null ? '' : ' (${DateFormat('dd MMM, hh:mm a').format(savedAt)})';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.closeAllSnackbars();
      MyToast.snackToast('$reason\n${AppStrings.showingCachedDataMsg}$when', 2);
    });
  }

  Future<http.Response> _sendRequestWithRetry({required Uri uri, required Map<String, String>? headers, required dynamic body, required Method method}) async {
    Object? lastError;

    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      try {
        return await _executeRequest(uri: uri, headers: headers, body: body, method: method);
      } on TimeoutException catch (error) {
        lastError = error;
        if (_shouldRetry(method: method, attempt: attempt) == false) {
          rethrow;
        }
      } on SocketException catch (error) {
        lastError = error;
        if (_shouldRetry(method: method, attempt: attempt) == false) {
          rethrow;
        }
      } on HttpException catch (error) {
        lastError = error;
        if (_shouldRetry(method: method, attempt: attempt) == false) {
          rethrow;
        }
      }

      await Future.delayed(_retryDelays[attempt]);
    }

    throw lastError ?? Exception('Request failed without a captured error');
  }

  Future<http.Response> _executeRequest({required Uri uri, required Map<String, String>? headers, required dynamic body, required Method method}) async {
    switch (method) {
      case Method.post:
        return _client.post(uri, headers: headers, body: body); //.timeout(requestTimeOut);
      case Method.delete:
        return _client.delete(uri, headers: headers); //.timeout(requestTimeOut);
      case Method.put:
        return _client.put(uri, headers: headers, body: body); //.timeout(requestTimeOut);
      case Method.patch:
        return _client.patch(uri, headers: headers, body: body); //.timeout(requestTimeOut);
      case Method.multiPartPost:
        // bodyMap for multipart: {'data': <json-encodable>, 'files': [{'name': .., 'path': ..}]}
        var req = http.MultipartRequest('POST', uri);
        if (headers != null) req.headers.addAll(headers);
        req.fields["data"] = jsonEncode(body['data']);
        if (body['files'] != null && body['files'].isNotEmpty) {
          for (var i = 0; i < body['files'].length; i++) {
            req.files.add(await http.MultipartFile.fromPath(body['files'][i]['name'].toString(), body['files'][i]["path"]));
          }
        }
        final res = await req.send(); // .timeout(requestTimeOut);

        // For Debug Only , To Create cURL from a request of multipart request ----------
        Logger.logs('cURL for multipart request: ${ApiUtility.generateCurl(req)}');

        return http.Response(await res.stream.bytesToString(), res.statusCode);
      case Method.get:
        return _client.get(uri, headers: headers); //.timeout(requestTimeOut);
    }
  }

  // Only idempotent methods are retried, a retried POST could create duplicates on the server.
  bool _shouldRetry({required Method method, required int attempt}) {
    if (attempt >= _retryDelays.length) {
      return false;
    }

    return method == Method.get || method == Method.put || method == Method.delete;
  }

  Future<http.Response> _buildFailureResponse({required http.Request request, required String? appBaseUrl, required Object error}) async {
    final status = await _classifyFailure(appBaseUrl: appBaseUrl, error: error);

    Logger.logs('Request failed @ APIProvider : ${request.url} || $error || ${status.key}');
    return http.Response(jsonEncode({"message": status.value}), status.key, request: request);
  }

  Future<MapEntry<int, String>> _classifyFailure({required String? appBaseUrl, required Object error}) async {
    final internetConnectionFound = await ConnectionProvider.instance.checkInternetConnection();

    if (internetConnectionFound == false) {
      return const MapEntry(503, AppStrings.youAreOfflineMsg);
    }

    if (error is TimeoutException) {
      final serverConnectionFound = await ConnectionProvider.instance.canConnectToServer(appBaseUrl: appBaseUrl);
      return serverConnectionFound ? const MapEntry(524, AppStrings.apiTimeoutErrorMsg) : const MapEntry(523, AppStrings.apiServerOffErrorMsg);
    }

    if (error is SocketException || error is HttpException) {
      final serverConnectionFound = await ConnectionProvider.instance.canConnectToServer(appBaseUrl: appBaseUrl);
      if (serverConnectionFound == false) {
        return const MapEntry(523, AppStrings.apiServerOffErrorMsg);
      }
    }

    return const MapEntry(511, AppStrings.somethingWRMsg);
  }

  void _handleResponseFeedback({required http.Response response, required bool showSCExceptions}) {
    // For Production Mode Each Crashed request details only when asked -------------------
    if (showSCExceptions == true && DeveloperService.to.isDevMode.value == false) {
      ApiUtility.displayMessagePerStatusCode(response.statusCode);
    }
    // For Developer Mode Each Crashed request details -------------------
    if (DeveloperService.to.isDevMode.value == true && (DeveloperService.to.isCoreDevMode.value == true || response.statusCode > 300)) {
      DeveloperService.to.showDevErrorDialog(response);
    }
  }
}

// WARNING: accepts ANY SSL certificate. Only for dev/self-signed servers - remove (or restrict to your host) before production.
class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
