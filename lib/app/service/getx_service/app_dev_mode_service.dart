import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:arenabook/app/utils/api_utility/api_utility.dart';
import 'package:arenabook/app/utils/custom_widgets/common_text.dart';
import 'package:vibration/vibration.dart';

import '../../utils/custom_functions/logger.dart';
import '../../utils/custom_functions/app_alerts.dart';
import '../../utils/custom_widgets/custom_toast.dart';
import '../../utils/custom_widgets/gradient_button.dart';
import '../../utils/custom_widgets/recognizable_text.dart';
import '../service_handler.dart/cache_field.dart';
import '../../config/app_cache.dart';
import '../../config/app_strings.dart';

class DeveloperService extends GetxController {
  static DeveloperService get to => Get.find();

  /// ─────────────────── MODES ───────────────────
  final isDevMode = CacheField<bool>(AppCache.general.devMode, false);
  final RxBool isCoreDevMode = false.obs;
  DateTime? coreDevModeInitiateTme;

  /// ─────────────────── LOGS ───────────────────
  final RxList<http.Response?> logs = <http.Response?>[].obs;
  final RxBool isDialogOpen = false.obs;

  /// Gesture sequence
  final List<String> gestureSequence = [];
  static const String _targetPattern = 'doubleTap,swipeUp,swipeRight';

  @override
  void onInit() {
    _initFromStorage();
    super.onInit();
  }

  Future<void> _initFromStorage() async {
    // isDevMode already loaded its cached value when the field was created
    isCoreDevMode.value = false;
    Logger.logs('Dev Mode : ${isDevMode.value}');
  }

  /// ─────────────────── DEV MODE ───────────────────

  void checkPattern() {
    if (gestureSequence.join(',') == _targetPattern) {
      switchDevMode(true);
      gestureSequence.clear();
    }
  }

  void switchDevMode([bool turnOn = true]) {
    isCoreDevMode.value = false;
    coreDevModeInitiateTme = null;
    gestureSequence.clear();

    isDevMode.save(turnOn);

    if (turnOn) {
      MyToast.snackToast('Developer Mode Activated', 2);
    }
  }

  void turnOnCoreDevMode() {
    Vibration.vibrate(duration: 300);
    isCoreDevMode.value = true;
    coreDevModeInitiateTme = null;
  }

  /// ─────────────────── LOG HANDLING ───────────────────

  void addLog(http.Response? response) {
    logs.add(response);
  }

  void clearLogs() {
    logs.clear();
  }

  /// 🔥 MAIN ENTRY POINT
  void showDevErrorDialog(http.Response? response) {
    addLog(response);

    if (isDialogOpen.value) return;

    isDialogOpen.value = true;

    /// Ensure dialog opens AFTER current frame
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!Get.isDialogOpen!) {
      _openDevLogDialog();
    } else {
      isDialogOpen.value = false;
    }
    // });
  }

  /// ─────────────────── DIALOG ───────────────────

  void _openDevLogDialog() {
    final theme = Get.context!.theme.colorScheme;

    Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.all(8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Obx(() => Text('🚨 Dev Logs (${logs.length})')),
            GestureDetector(onTap: () => _copyResponseFromLog(null, copyAll: true), child: const Text('📋 Copy All')),
          ],
        ),
        content: SizedBox(
          height: 450,
          width: 320,
          child: Obx(() => ListView.builder(itemCount: logs.length, itemBuilder: (_, index) => _buildLogCard(logs[index], theme))),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          GradeBtn(
            isChild: false,
            circularBorder: 8.0,
            marginAll: 2.0,
            name: "Close",
            onpressed: () {
              clearLogs();
              Get.back();
            },
            firstClr: theme.onPrimary,
            lastClr: theme.primaryFixed,
            heightB: 0.04,
            widthB: 0.30,
          ),
        ],
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      /// SAFETY RESET
      isDialogOpen.value = false;
    });
  }


  /// ─────────────────── LOG CARD ───────────────────

  Widget _buildLogCard(http.Response? log, ColorScheme theme) {
    final req = log?.request as http.Request?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (req?.method != null) RecognizableTextWidget(text: '🔹 Method:\n${req!.method}'),
            if (req?.url != null) RecognizableTextWidget(text: '\n🌐 Base URL:\n${req!.url.scheme}://${req.url.authority}'),
            if (req?.url.path != null) RecognizableTextWidget(text: '\n🔗 Endpoint:\n${req!.url.path}'),
            if (req?.headers.isNotEmpty ?? false) RecognizableTextWidget(text: '\n🧾 Headers:\n${jsonEncode(req!.headers)}'),
            if (req?.url.queryParameters.isNotEmpty ?? false) RecognizableTextWidget(text: '\n🔎 Query Params:\n${jsonEncode(req!.url.queryParameters)}'),
            if (req?.body.isNotEmpty ?? false) RecognizableTextWidget(text: '\n📤 Payload:\n${req!.body}'),
            if (log?.statusCode != null) RecognizableTextWidget(text: '\n📦 Status Code:\n${log!.statusCode}'),
            if (log?.body != null) RecognizableTextWidget(text: '\n📫 Response:\n${_trimResponseBody(log!.body)}'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GradeBtn(
                  isChild: false,
                  circularBorder: 8.0,
                  marginAll: 2.0,
                  name: "Save",
                  onpressed: () async {
                    await _saveResponseFromLog(log);
                  },
                  firstClr: theme.onPrimary,
                  lastClr: theme.primaryFixed,
                  heightB: 0.04,
                  widthB: 0.25,
                ),
                GradeBtn(
                  isChild: false,
                  circularBorder: 8.0,
                  marginAll: 2.0,
                  name: "Copy",
                  onpressed: () {
                    _copyResponseFromLog(log);
                  },
                  firstClr: theme.onPrimary,
                  lastClr: theme.primaryFixed,
                  heightB: 0.04,
                  widthB: 0.25,
                ),
              ],
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                _copyCurlFromLog(log);
              },
              child: const Center(
                child: CommonText(text: 'Copy Curl'),
                // GradeBtn(
                //   isChild: false,
                //   circularBorder: 8.0,
                //   marginAll: 2.0,
                //   name: "Copy cURL",
                //   onpressed: () {
                //     _copyCurlFromLog(log);
                //   },
                //   firstClr: theme.onPrimary,
                //   lastClr: theme.primaryFixed,
                //   heightB: 0.06,
                //   widthB: 0.35,
                // ),
              ),
            ),
            const SizedBox(height: 10),
            // TextButton(
            //   onPressed: () {
            //     _copyCurlFromLog(log);
            //   },
            //   child: Text('Copy Curl', style: TextStyle(color: theme.onSecondary)),
            // ),
          ],
        ),
      ),
    );
  }

  /// ─────────────────── HELPERS ───────────────────

  String _trimResponseBody(dynamic body, {int maxLines = 3, int maxLength = 250}) {
    final lines = const LineSplitter().convert(body.toString());
    final selected = lines.take(maxLines).join('\n');
    return selected.length > maxLength ? '${selected.substring(0, maxLength)}...' : selected;
  }

  Future<void> _saveResponseFromLog(http.Response? log) async {
    Dialogs.showProgressBar();
    try {
      final endpoint = log?.request?.url.path.split('/').last ?? 'unknown';
      final name = '${endpoint}_${DateTime.now().millisecondsSinceEpoch}';
      final path = Platform.isAndroid ? '/storage/emulated/0/Download/${AppStrings.appName.isEmpty ? 'App' : AppStrings.appName}' : (await getApplicationDocumentsDirectory()).path;

      Directory(path).createSync(recursive: true);
      final file = File('$path/$name.txt');
      await file.writeAsString(_prepareLogData(log));

      Dialogs.hideProgressBar();
    } catch (e) {
      Dialogs.hideProgressBar();
      Logger.logs('Save error: $e');
    }
  }

  String _prepareLogData(http.Response? log) {
    final req = log?.request as http.Request?;

    return '''
Method: ${req?.method}
URL: ${req?.url}
Headers: ${jsonEncode(req?.headers)}
Query: ${jsonEncode(req?.url.queryParameters)}
Payload: ${req?.body}
Status: ${log?.statusCode}
Response: ${log?.body}
''';
  }

  void _copyResponseFromLog(http.Response? log, {bool copyAll = false}) {
    String text = '';
    if (copyAll) {
      for (final l in logs) {
        text += _prepareLogData(l);
      }
    } else {
      text = _prepareLogData(log);
    }

    Clipboard.setData(ClipboardData(text: text));
    MyToast.snackToast('Copied to Clipboard', 2);
  }
}

void _copyCurlFromLog(http.Response? log) {
  final curlCommand = ApiUtility.responseToCurlString(log);
  Clipboard.setData(ClipboardData(text: curlCommand));
  MyToast.snackToast('cURL copied to Clipboard', 2);
}

class DevGestureDetector extends StatelessWidget {
  const DevGestureDetector({super.key, required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        if (DeveloperService.to.isDevMode.value) {
          DeveloperService.to.coreDevModeInitiateTme = DateTime.now();
        }
      },
      onLongPressEnd: (_) {
        if (DeveloperService.to.isDevMode.value) {
          if (DeveloperService.to.coreDevModeInitiateTme != null &&
              DateTime.now().difference(DeveloperService.to.coreDevModeInitiateTme!).inMilliseconds > 3000) {
            DeveloperService.to.turnOnCoreDevMode();
          }
        }
        DeveloperService.to.coreDevModeInitiateTme = null;
      },
      onDoubleTap: () {
        DeveloperService.to.gestureSequence.clear();
        DeveloperService.to.gestureSequence.add('doubleTap');
        DeveloperService.to.checkPattern();
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          DeveloperService.to.gestureSequence.add('swipeDown');
        } else {
          DeveloperService.to.gestureSequence.add('swipeUp');
        }
        DeveloperService.to.checkPattern();
      },
      onHorizontalDragEnd: (detailsH) {
        if (detailsH.primaryVelocity! > 0) {
          DeveloperService.to.gestureSequence.add('swipeRight');
        }
        DeveloperService.to.checkPattern();
      },
      child: child,
    );
  }
}
