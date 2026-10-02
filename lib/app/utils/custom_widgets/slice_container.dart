// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arenabook/app/config/app_border_radius.dart';

import '../../config/app_paddings.dart';

class Slice extends StatelessWidget {
  double? height, leftWidth;
  double? contentHorizontalPadding;
  Color? statusColor;
  final VoidCallback onPress;
  final Widget leftAreaContent;
  final Widget rightAreaContent;
  final bool isSelected;
  Slice({
    super.key,
    required this.onPress,
    required this.leftAreaContent,
    required this.rightAreaContent,
    required this.isSelected,
    this.height,
    this.contentHorizontalPadding,
    this.statusColor,
    this.leftWidth,
  });

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    Size screenSize = MediaQuery.of(context).size;
    double? containerHeight = height ?? 250;
    return GestureDetector(
      onTap: () {
        onPress();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppPaddings.appMainPaddingSmall),
        child: PhysicalModel(
          borderRadius: AppBorderRadius.circularBorderHigh,
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          elevation: 5.0,
          child: Container(
            width: double.infinity,
            height: containerHeight,
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: theme.onPrimary, width: 1.5) : const Border(),
              borderRadius: AppBorderRadius.circularBorderNormal,
            ),
            child: Row(
              children: [
                // Left Container
                Container(
                  height: containerHeight,
                  width: leftWidth ?? screenSize.width * 0.20,
                  color: statusColor ?? theme.onPrimary,
                  child: leftAreaContent,
                ),
                // Right Child
                Expanded(
                  child: Container(
                    height: containerHeight,
                    padding: EdgeInsets.symmetric(
                      vertical: AppPaddings.appMainPaddingLarge,
                      horizontal: contentHorizontalPadding ?? AppPaddings.appMainPaddingLarge,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary,
                    ),
                    child: rightAreaContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Slice2 extends StatelessWidget {
  double? leftWidth;
  // double? contentHorizontalPadding;
  Color? statusColor;
  final Function() onPress;
  final Widget leftAreaContent;
  final Widget rightAreaContent;
  final bool isSelected;
  Slice2({
    super.key,
    required this.onPress,
    required this.leftAreaContent,
    required this.rightAreaContent,
    required this.isSelected,
    // this.height,
    // this.contentHorizontalPadding,
    this.statusColor,
    // this.leftWidth,
  });

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    // Size screenSize = MediaQuery.of(context).size;
    //  double? containerHeight = height ?? 250;
    return GestureDetector(
      onTap: onPress,
      child: Material(
        borderRadius: AppBorderRadius.circularBorderNormal,
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.card,
        elevation: 5.0,
        child: IntrinsicHeight(
          child: Container(
            //  margin: EdgeInsets.all(2),
            padding: EdgeInsets.all(1),
            // width: double.infinity,
            // height: containerHeight,
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: theme.onPrimary, width: 1.5) : const Border(),
              borderRadius: AppBorderRadius.circularBorderNormal,
            ),
            child: Row(
              children: [
                // Left Container
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent, width: 1.5),
                      color: statusColor ?? theme.onPrimary,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
                    ),
                    //   height: containerHeight,
                    // width: leftWidth ?? screenSize.width * 0.20,
                    // color: statusColor ?? theme.onPrimary,
                    child: leftAreaContent,
                  ),
                ),
                // Right Child
                Expanded(
                  flex: 5,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    // height: containerHeight,
                    // padding: EdgeInsets.symmetric(
                    //   vertical: AppPaddings.appMainPaddingLarge,
                    //   horizontal: contentHorizontalPadding ?? AppPaddings.appMainPaddingLarge,
                    // ),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      border: Border.all(color: Colors.transparent, width: 1.5),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                    ),
                    child: rightAreaContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
