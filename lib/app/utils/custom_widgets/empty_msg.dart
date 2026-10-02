// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:arenabook/app/utils/custom_widgets/gradient_button.dart';
import 'package:arenabook/app/utils/utils.dart';
import 'common_text.dart';

import '../../config/app_size_config.dart';

class EmptyMsg extends StatelessWidget {
  EmptyMsg({
    super.key,
    required this.title,
    required this.msg,
    this.img,
    this.height = 0.3,
    this.isLottie = true,
    this.repeat,
    this.isRetry,
    this.retry,
    this.buttonText,
  });

  String title, msg;
  String? img, buttonText;
  num? height;
  bool? isLottie;
  bool? repeat;
  bool? isRetry;
  Function()? retry;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: w * 0.15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isLottie != null && isLottie == true
              ? img != null && img != ''
                  ? Lottie.asset(
                      repeat: repeat ?? true,
                      options: LottieOptions(),
                      animate: true,
                      Utils.getLottiePath(img!),
                      //'assets/lottie/$img.json',
                      frameRate: FrameRate.composition,
                      height: h * height!,
                      fit: BoxFit.fill,
                      alignment: Alignment.center,
                      addRepaintBoundary: false,
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          0.02.ph,
          CommonText(
            text: title,
            fontSize: 30.0,
            weight: FontWeight.bold,
            color: theme.onSecondary,
            textAlign: TextAlign.center,
          ),
          0.02.ph,
          CommonText(
            text: msg,
            textAlign: TextAlign.center,
            fontSize: 18.0,
            color: theme.onSecondary,
          ),
          0.02.ph,
          isRetry != null && isRetry == true
              ? Container(
                  width: 80,
                  height: 30.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: GradeBtn(
                      circularBorder: 8.0,
                      marginAll: 0,
                      name: buttonText ?? 'Try Again', //_.openFromNavbar == true ? "Save" : "Update",
                      onpressed: retry ?? () {},
                      //  () {
                      //   _.validation(context);
                      // },
                      firstClr: theme.onPrimary,
                      lastClr: theme.tertiary,
                      heightB: 40,
                      widthB: double.infinity),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
