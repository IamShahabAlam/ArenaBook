// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'arena_logo.dart';
import 'common_text.dart';

import '../../config/app_fontweights.dart';

class MyDialog {
  static MyAlertDialog(context, text, onYes, onNo, {String? yes, no, Color? color, bool? barrier}) {
    showDialog(
      barrierDismissible: barrier ?? true,
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: color ?? Get.theme.colorScheme.secondary,
        content: WillPopScope(
          onWillPop: barrier == false
              ? () async {
                  return false;
                }
              : () async {
                  Get.back();
                  return true;
                },
          child: Text(
            text,
            style: TextStyle(fontSize: 17, fontWeight: AppFontWeights.appTextFontWeightLight, color: Get.theme.colorScheme.onSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: onNo,
            child: Text(
              no ?? "No",
              style: TextStyle(fontWeight: AppFontWeights.appTextFontWeightMedium, color: Get.theme.colorScheme.onSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Get.theme.colorScheme.tertiary, foregroundColor: Get.theme.colorScheme.onSecondary),
            onPressed: onYes,
            child: Text(yes ?? "Yes"),
          ),
        ],
      ),
    );
  }

  static void showDialogBox(String title, String message, Function() onOKPress, {Color? color, bool? barrier}) {
    Get.defaultDialog(
        barrierDismissible: barrier ?? true,
        backgroundColor: color,
        title: title,
        content: WillPopScope(
            onWillPop: barrier == false
                ? () async {
                    return false;
                  }
                : () async {
                    Get.back();
                    return true;
                  },
            child: Text(message, style: const TextStyle(), textAlign: TextAlign.center)),
        contentPadding: const EdgeInsets.all(20.0),
        cancel: Container(),
        confirm: SizedBox(
          width: 100,
          child: MaterialButton(
            color: Get.theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            // style: ElevatedButton.styleFrom(backgroundColor: Get.theme.colorScheme.onPrimary),
            onPressed: onOKPress,
            child: CommonText(
              text: "Ok",
              color: Get.theme.colorScheme.primary,
            ),
          ),
        ),
        radius: 10.0,
        titlePadding: const EdgeInsets.fromLTRB(0, 15, 0, 0));
  }

  static void showScrollableListDialog({
    required String title,
    required List messages,
    required Function onOKPress,
    bool? barrier,
  }) {
    final context = Get.context!;
    final double maxHeight = MediaQuery.of(context).size.height * 0.8;

    Get.dialog(
      barrierDismissible: barrier ?? true,
      WillPopScope(
        onWillPop: barrier == false
            ? () async => false
            : () async {
                onOKPress();
                return true;
              },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CommonText(
                    text: title,
                    weight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                // List
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                        child: CommonText(
                          text: messages[index],
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 100,
                    child: MaterialButton(
                      color: Get.theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onPressed: () => onOKPress(),
                      child: CommonText(
                        text: "Ok",
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

/*  static showProgressBar() {
    Get.dialog(
        WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Center(
            child: Container(
                height: 100,
                width: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage(ArenaLogo.assetPath),
                ))).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: const Duration(milliseconds: 800)),
          ),
        ),
        barrierDismissible: false);
  }

 static void hideProgressBar() {
    Get.back();
  }*/

  static Widget LoaderDialog() {
    return Stack(
      children: [
        Center(
          child: Container(
            height: 100,
            width: 100,
            margin: EdgeInsets.only(top: Get.height * 0.2),
            child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    child: const ArenaLogo(size: 80, semanticLabel: 'Loading'))
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .shimmer(
                  duration: const Duration(milliseconds: 400),
                ),
          ),
        )
      ],
    );
  }
}
