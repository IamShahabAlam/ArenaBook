// ignore_for_file: invalid_use_of_protected_member, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:arenabook/app/config/app_border_radius.dart';
import 'package:arenabook/app/config/app_box_shadow.dart';
import 'package:arenabook/app/config/app_size_config.dart';
import 'package:arenabook/app/service/getx_service/developer_mode_service.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

import '../../config/app_assets.dart';
import '../../config/app_fontweights.dart';
import '../../service/getx_service/network_service.dart';
import '../custom_widgets/common_text.dart';
import '../../../routes/app_pages.dart';
import '../../config/app_colors.dart';
import '../../service/service_handler.dart/user_store.dart';
import '../custom_widgets/logo_loader.dart';
import '../utils.dart';
import 'logger.dart';

// custom dialogs for app alerts
// loaders
class Dialogs {
  static void showSnackbar(
    String title,
    String msg, {
    int? colorCode = 2,
    SnackPosition? position = SnackPosition.TOP,
    bool? isIconify = false,
    Duration? duration,
  }) {
    var img = colorCode == 0
        ? AppAssets.lottie.errorLottie
        : colorCode == 1
        ? AppAssets.lottie.successLottie
        : AppAssets.lottie.infoLottie;
    Get.snackbar(
      title,
      msg,
      animationDuration: duration ?? Duration(seconds: 2),
      duration: duration ?? Duration(seconds: 2),
      //barBlur: 0.8,
      snackPosition: position,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: isIconify == true ? 12 : 25, vertical: 12),
      icon: isIconify == true
          ? Lottie.asset(
              options: LottieOptions(),
              animate: true,
              Utils.getLottiePath(img),
              //'assets/lottie/$img.json',
              frameRate: FrameRate.composition,
              height: 25,
              width: 25,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              addRepaintBoundary: false,
            )
          : null,
      backgroundColor: colorCode == 0
          ? AppColors.errorColorDark
          : colorCode == 1
          ? AppColors.successColorDark
          : Get.theme.colorScheme.outline,
      colorText: AppColors.appColorWhite,
      // colorCode == 0
      //     ? AppColors.errorColorDark
      //     : colorCode == 1
      //         ? AppColors.successColorDark
      //         : Get.theme.colorScheme.outline,
    );
  }

  static void showProgressBar({bool barrierDissmissable = false, String? text, bool? canPop = true}) {
    Get.dialog(
      barrierDismissible: barrierDissmissable,

      // WillPopScope(
      //   onWillPop: () async => true,
      // child:
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LogoLoader(text),
            // isText == true ? SizedBox(height: 8) : SizedBox.shrink(),
          ],
        ),
      ),
      // ),
    );
  }

  // Network Message with navigations
  static void showNetworkMessageForSplash() {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        backgroundColor: Get.theme.colorScheme.secondary,
        content: Text(
          'No internet connection\nConnect to internet and retry', // "Are you sure you want to go back, all your changes will be discarded",
          style: TextStyle(fontSize: 17, color: Get.theme.colorScheme.onSecondary),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: () {
              Get.back();
            },
            child: Text(
              "Ignore",
              style: TextStyle(fontWeight: AppFontWeights.appTextFontWeightMedium, color: Get.theme.colorScheme.onSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Get.theme.colorScheme.tertiary, foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: () async {
              Get.back();
              // await GetXNetworkManager.to.checkConnectivity();

              Dialogs.showProgressBar();
              Future.delayed(const Duration(seconds: 2), () {
                if (GetXNetworkManager.to.connectionType == 0) {
                  Dialogs.hideProgressBar();
                  Get.back();
                  Dialogs.showNetworkMessageForSplash();
                } else {
                  Dialogs.hideProgressBar();
                  // Logged in -> stay where we are, otherwise send to login
                  if (UserStore.to.isLoggedIn) {
                    Get.back();
                  } else {
                    Get.offAllNamed(PageNames.loginScreen);
                  }
                }
              });
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  static void showBlockedDialog() {
    // if (Get.isDialogOpen == true) return; // Avoid multiple dialogs
    showDialog(
      barrierDismissible: false,
      context: Get.context!,
      builder: (ctx) => AlertDialog(
        backgroundColor: Get.theme.colorScheme.secondary,
        content: Text(
          'Developer Mode Detected\n Please disable it and  try again.',
          style: TextStyle(fontSize: 17, fontWeight: AppFontWeights.appTextFontWeightLight, color: Get.theme.colorScheme.onSecondary),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          Visibility(
            visible: GetXDeveloperModeManager.to.isDeveloperModeEnabled.value,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.onSecondary),
              onPressed: () async {
                try {
                  await OpenSettingsPlusAndroid().applicationDevelopment();
                } catch (e) {
                  Logger.logs(e);
                }
              },
              child: Text(
                "Open Settings",
                style: TextStyle(fontWeight: AppFontWeights.appTextFontWeightMedium, color: Get.theme.colorScheme.onSecondary),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Get.theme.colorScheme.tertiary, foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: () async {
              GetXDeveloperModeManager.to.checkDeveloperMode().then((value) async {
                if (GetXDeveloperModeManager.to.isDeveloperModeEnabled.value) {
                  Get.back();
                  showBlockedDialog();
                } else {
                  Get.back();
                  Get.offAllNamed(PageNames.splashscreen);
                }
              });
              // Get.back();
            },
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
    // Get.dialog(
    //   // AlertDialog(
    //   //   title: CommonText(text: 'Developer Mode Detected'),
    //   //   content: CommonText(text: 'Developer Mode is enabled. Please disable it try again.'),
    //   //   actions: [
    //   //     TextButton(
    //   //       onPressed: () {
    //   //         // Close the app
    //   //         Get.back(); // Close dialog
    //   //         checkDeveloperMode(); // Exit the app
    //   //       },
    //   //       child: CommonText(text: 'Try Again'),
    //   //     ),
    //   //     TextButton(
    //   //       onPressed: () {
    //   //         // Navigate to Developer Options settings
    //   //         openAppSettings();
    //   //       },
    //   //       child: CommonText(text: 'Open Settings'),
    //   //     ),
    //   //   ],
    //   // ),
    //   barrierDismissible: false,
    // );
  }

  // Hides Progress indicator
  static void hideProgressBar() {
    // Commenting and replacing Naigator.poop() as this has started misbehaving
    // Get.back();

    Navigator.of(Get.context!).pop();
    //  Get.back(closeOverlays: true);
  }

  // Custom  Dialog box (ONLY: OK)
  static void showAlertDialog(String message, {Function()? onback}) {
    Get.defaultDialog(
      title: "Alert",
      content: Text(message, style: const TextStyle(), textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.all(20.0),
      cancel: Container(),
      confirm: SizedBox(
        width: 100,
        child: MaterialButton(
          onPressed:
              onback ??
              () async {
                Get.back();
              },
          child: const CommonText(text: "Ok"),
        ),
      ),
      radius: 10.0,
      titlePadding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
    );
  }

  // Custom DIalog Box (WITH YES AND NO)
  static showCustomAlertDialog(context, text, onYes, onNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Get.theme.colorScheme.secondary,
        content: Text(
          text,
          style: TextStyle(fontSize: 17, fontWeight: AppFontWeights.appTextFontWeightLight, color: Get.theme.colorScheme.onSecondary),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: onNo,
            child: Text(
              "No",
              style: TextStyle(fontWeight: AppFontWeights.appTextFontWeightMedium, color: Get.theme.colorScheme.onSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Get.theme.colorScheme.tertiary, foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: onYes,
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  static myLottieDialog(
    context, {
    String? title,
    String? text,
    Widget? subTextWidget,
    TextAlign? textAlign = TextAlign.center,
    TextAlign? subTextAlign = TextAlign.center,
    String? lottieName,
    bool repeatAnim = false,
    bool isTopButton = false,
    bool isBottomButton = false,
    bool showCloseIcon = false,
    String? topName,
    Color? topColor,
    IconData? topIcon,
    Function()? topFunc,
    String? bottomName,
    Color? bottomColor,
    IconData? bottomIcon,
    Function()? bottomFunc,
    bool isDismissible = true,
  }) {
    showDialog(
      barrierDismissible: isDismissible,
      context: context,
      builder: (ctx) => WillPopScope(
        onWillPop: isDismissible == true ? () async => true : () async => false,
        child: Dialog(
          // contentPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent, // Get.context!.theme.colorScheme.surfaceTint, //Get.theme.colorScheme.primary,
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              // width: 300,
              // height: 600,
              child: Stack(
                alignment: Alignment.topCenter,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(top: 35),
                    decoration: BoxDecoration(color: Get.context!.theme.colorScheme.primary, borderRadius: AppBorderRadius.circularBorderHigh),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 70),

                          Visibility(
                            visible: title != '',
                            child: CommonText(
                              text: title!,
                              fontSize: 18,
                              weight: AppFontWeights.appTextFontWeightMedium,
                              textAlign: TextAlign.center,
                            ).marginOnly(bottom: 20),
                          ),

                          // content:
                          Visibility(
                            visible: text != '',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CommonText(text: text!, textAlign: textAlign!),
                                subTextWidget ?? const SizedBox.shrink(),
                                // CommonText(text: subTextWidget, textAlign: subTextAlign!),
                              ],
                            ).marginOnly(bottom: 30),
                          ),

                          isTopButton == true
                              ? SizedBox(
                                  width: double.maxFinite,
                                  child: MaterialButton(
                                    color: topColor ?? Get.context!.theme.colorScheme.onPrimary,
                                    onPressed: topFunc ?? () {},
                                    child: CommonText(text: topName ?? "", color: Colors.white),
                                  ),
                                ).marginOnly(bottom: 0)
                              : const SizedBox.shrink(),
                          isBottomButton == true
                              ? SizedBox(
                                  width: double.maxFinite,
                                  child: MaterialButton(
                                    color: bottomColor ?? Get.context!.theme.colorScheme.onPrimary,
                                    onPressed: bottomFunc ?? () {},
                                    child: CommonText(text: bottomName ?? "", color: Colors.white),
                                  ),
                                ).marginOnly(bottom: 10)
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                  if (showCloseIcon) ...[
                    Positioned(
                      top: 35,
                      right: 0,
                      child: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                    ),
                  ],
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        boxShadow: [AppBoxShadow.containerLightShadow],
                        shape: BoxShape.circle,
                        color: Get.context!.theme.colorScheme.primary,
                        // borderRadius: AppBorderRadius.circularBorderHigh
                      ),
                      child:
                          Lottie.asset(
                            Utils.getLottiePath(lottieName!),
                            options: LottieOptions(),
                            animate: true,
                            repeat: repeatAnim,
                            frameRate: FrameRate.composition,
                            // height: Get.height * 0.1,
                            // width: 100, //Get.width * 0.2,
                            fit: BoxFit.fill,
                            alignment: Alignment.center,
                            addRepaintBoundary: false,
                          )
                          // .marginOnly(left: 60, right: 60, bottom: 10, top: 10)
                          .animateToBottom(delay: 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
