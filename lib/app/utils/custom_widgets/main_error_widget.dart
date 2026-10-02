import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:arenabook/app/config/app_assets.dart';
import 'package:arenabook/app/config/app_fontweights.dart';
import 'package:arenabook/app/config/app_size_config.dart';
import 'package:arenabook/app/service/getx_service/app_dev_mode_service.dart';
import 'package:arenabook/app/utils/custom_widgets/common_text.dart';

import '../custom_functions/app_alerts.dart';
import '../utils.dart';

class MainErrorWidget extends StatelessWidget {
  const MainErrorWidget({super.key, required this.error});

  final FlutterErrorDetails error;

  @override
  Widget build(BuildContext context) {
    HeightWidth(context);
    return DeveloperService.to.isDevMode.value == false
        ? LayoutBuilder(
            builder: (context, constraints) {
              // If inside scrollable (unbounded height), just wrap content
              if (constraints.maxHeight == double.infinity) {
                return Container(height: h, width: w, color: Theme.of(context).colorScheme.shadow);
              }

              // If bounded (e.g. inside Column/Row with Expanded), fill the space
              return Container(color: Theme.of(context).colorScheme.shadow, width: constraints.maxWidth, height: constraints.maxHeight);
            },
          )
        : GestureDetector(
            onTap: () {
              Dialogs.myLottieDialog(Get.context,
                  lottieName: AppAssets.lottie.errorLottie,
                  showCloseIcon: true,
                  textAlign: TextAlign.left,
                  title: 'Screen Exception',
                  text:
                      'Summary: \n${error.summary.toString().trim()}${error.exceptionAsString().trim() == error.summary.toString().trim() ? '' : '\n\nException: \n${error.exceptionAsString().trim()}'}');
            },
            child: Center(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                (DeveloperService.to.isDevMode.value == false) ? 0.2.ph : 0.03.ph,
                Lottie.asset(
                  options: LottieOptions(),
                  animate: true,
                  repeat: false,
                  Utils.getLottiePath(AppAssets.lottie.errorLottie),
                  frameRate: FrameRate.composition,
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  addRepaintBoundary: false,
                ).center(),
                SizedBox(height: 20.0),
                CommonText(text: "An error occurred, Please try again later.", fontSize: 18.0, weight: AppFontWeights.appTextFontWeightBold).center(),
                SizedBox(height: 20.0),
                CommonText(text: 'Summary: \n${error.summary.toString().trim()}', fontSize: 14.0),
                if (error.exceptionAsString().trim() != error.summary.toString().trim()) ...[
                  SizedBox(height: 20.0),
                  CommonText(text: 'Exception: \n${error.exceptionAsString().trim()}', fontSize: 14.0)
                ]
              ]).paddingSymmetric(horizontal: 12.0),
            ),
          );
  }
}
