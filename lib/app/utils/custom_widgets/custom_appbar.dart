// ignore_for_file: unused_local_variable, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:arenabook/app/config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_textstyle.dart';
import 'common_text.dart';
import 'nuemorph_container.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  CustomAppBar({super.key, this.leading, this.title, this.action, this.isAction = true, this.isTitleWidget = false, this.titleWidget});

  Widget? leading, action, titleWidget;
  String? title;
  bool isAction = true, isTitleWidget = false;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return Stack(
      children: [
        AppBar(
          scrolledUnderElevation: 0.0,
          elevation: 0,
          leading: NuemorphContainer(
            marginAll: 8.0,
            height: 40.0,
            width: 40.0,
            child: leading ?? Container(),
            /*
            InkWell(
                          onTap: () {
                            Get.focusScope!.unfocus();
                            _.showDateSelectionDialog(context);
                            // _.onPressDateRangePicker(context);
                          },
                          child: const Icon(
                            Icons.calendar_month,
                            size: 25,
                          ),
                        ),
                        */
          ),
          title: isTitleWidget ? titleWidget : CommonText(text: title!, color: theme.onSecondary, fontSize: 18, weight: FontWeight.w600),
          actions: [
            isAction
                ? NuemorphContainer(
                    marginAll: 8.0,
                    height: 40.0,
                    width: 40.0,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [action ?? Container()]),
                  )
                : Container(),
          ],
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

class EmptyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  EmptyAppBar({super.key});

  Widget? leading, action, titleWidget;
  String? title;
  bool isAction = true, isTitleWidget = false;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return Container();
  }
}

class ScafoldedAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  ScafoldedAppBar({super.key, this.leading, this.title, this.action, this.isAction = true, this.isLeading = true});

  Widget? leading, action;
  Widget? title;
  bool isAction = true, isLeading = true;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark, statusBarColor: Colors.transparent),
      scrolledUnderElevation: 0.0,
      leading: isLeading ? Container(child: leading ?? Container()) : Container(),
      title: title,
      actions: [isAction ? SizedBox(height: 50.0, width: 70.0, child: action ?? Container()) : Container()],
      backgroundColor: Colors.transparent, // context.colors.secondary,
      centerTitle: true,
      titleTextStyle: AppTextStyles.appBarTextStyle,
      elevation: 0.0,
    );
  }
}
