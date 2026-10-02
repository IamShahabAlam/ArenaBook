// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arenabook/app/config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_textstyle.dart';
import 'common_text.dart';

class CustomAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  CustomAppBar2({
    super.key,
    this.leading,
    this.title,
    this.action,
    this.isAction = true,
    this.isTitleWidget = false,
    this.titleWidget,
    this.centerTitle = true,
    this.leadingWidth = 0.0,
    this.backgroundColor,
  });

  Widget? leading, action, titleWidget;
  String? title;
  bool isAction = true, isTitleWidget = false, centerTitle = true;
  double leadingWidth = 0.0;
  Color? backgroundColor;

  @override
  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return Stack(
      children: [
        AppBarTheme(
          iconTheme: IconThemeData(color: theme.onSecondary),
          child: AppBar(
            actionsIconTheme: IconThemeData(color: theme.onSecondary),
            foregroundColor: theme.onSecondary,
            iconTheme: IconThemeData(color: theme.onSecondary),

            backgroundColor: backgroundColor ?? theme.primary,
            scrolledUnderElevation: 0.0,
            elevation: 0,
            centerTitle: centerTitle,
            leading: leading ?? Container(),
            //leadingWidth: leadingWidth,
            title: isTitleWidget ? titleWidget : CommonText(text: title!, color: theme.onSecondary, fontSize: 18, weight: FontWeight.w600),
            actions: [
              isAction ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [action ?? Container()]) : Container(),
            ],
          ),
        ),

        // BETA BANNER ------------------------------
        Visibility(
          visible: ['beta', 'stage'].any((e) => AppStrings.kappVersionWithDate.toLowerCase().contains(e.toLowerCase())),
          child: Positioned(
            right: -22,
            top: 15,
            child: Transform.rotate(
              angle: 0.75,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: AppStrings.kappVersionWithDate.toLowerCase().contains('beta') ? AppColors.appColorBanner : AppColors.appColorAbsent,
                ),
                child: Text(
                  AppStrings.kappVersionWithDate.toLowerCase().contains('beta') ? 'BETA' : 'STAGE',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bannerTextStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
