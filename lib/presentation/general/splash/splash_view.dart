import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../app/config/app_assets.dart';
import '../../../app/config/app_fontweights.dart';
import '../../../app/config/app_size_config.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/utils/custom_widgets/common_text.dart';
import '../../../app/utils/utils.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);

    return Scaffold(
      backgroundColor: theme.primary,
      body: SizedBox(
        height: h,
        width: w,
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(Utils.getImagePath(AppAssets.images.favIcon), height: 100.0),
                  0.015.ph,
                  CommonText(text: AppStrings.appName, fontSize: 30.0, weight: AppFontWeights.appTextFontWeightMedium, color: theme.onPrimary),
                ],
              ).animate().fadeIn(duration: const Duration(seconds: 1)),
            ),
            // Version Number is in pubspec.yaml file (on Top) & AppStrings.kappVersionWithDate
            CommonText(
              text: AppStrings.kappVersionWithDate,
              fontSize: AppFontSizes.appFontSizeh11,
              weight: AppFontWeights.appTextFontWeightLight,
              color: theme.outline,
            ).animate().fadeIn(duration: const Duration(seconds: 1)),
            0.04.ph,
          ],
        ),
      ),
    );
  }
}
