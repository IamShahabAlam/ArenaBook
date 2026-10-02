// ignore_for_file: must_be_immutable, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_box_shadow.dart';
import '../../config/app_size_config.dart';

class GradeBtn extends StatelessWidget {
  GradeBtn({
    super.key,
    required this.marginAll,
    this.name,
    required this.onpressed,
    required this.firstClr,
    required this.lastClr,
    required this.heightB,
    required this.widthB,
    required this.circularBorder,
    this.isShadow = true,
    this.isChild = false,
    this.isDisabled = false,
    this.child,
    this.textColor,
    this.fontWeight,
    this.fontSize,
    this.isFreeDimension = false,
    this.padding = EdgeInsets.zero,
    this.icon,
  });

  final double marginAll, heightB, widthB, circularBorder;
  final String? name;
  final Function() onpressed;
  final Color firstClr, lastClr;
  Color? textColor;
  bool isShadow = true, isChild = false, isDisabled;
  final Widget? child;
  FontWeight? fontWeight;
  double? fontSize;
  bool? isFreeDimension;
  EdgeInsetsGeometry? padding;
  IconData? icon;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);

    return Container(
      margin: EdgeInsets.all(marginAll),
      padding: padding,
      height: isFreeDimension! ? null : h * heightB,
      width: isFreeDimension! ? null : w * widthB,
      decoration: BoxDecoration(
        boxShadow: isShadow ? [AppBoxShadow.tinyBtnBoxShadow] : [],
        borderRadius: BorderRadius.circular(circularBorder),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDisabled ? [theme.outline, theme.outline.withValues(alpha: 0.7)] : [firstClr, lastClr],
        ),
      ),
      child: MaterialButton(
        // style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(circularBorder)),
        //   enableFeedback: false,
        //   textStyle: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w700, color: Colors.white),
        //   backgroundColor: Colors.transparent,
        //   shadowColor: Colors.transparent,
        // ),
        onPressed: isDisabled ? null : onpressed,
        child: !isChild
            ? FittedBox(
                fit: BoxFit.fitWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name!,
                      style: TextStyle(
                        color: textColor ?? Colors.white, //theme.onSecondaryFixedVariant,
                        fontWeight: fontWeight ?? FontWeight.normal,
                        fontSize: fontSize ?? 14,
                      ),
                    ),
                    icon == null ? SizedBox.shrink() : SizedBox(width: 12),
                    icon == null ? SizedBox.shrink() : Icon(icon, color: textColor ?? Colors.white, size: 18),
                  ],
                ),
              )
            : child,
      ),
    );
  }
}
