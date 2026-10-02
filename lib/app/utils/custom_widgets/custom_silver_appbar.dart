// ignore_for_file: must_be_immutable, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSliverAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(0);
  CustomSliverAppBar({
    super.key,
    this.leading,
    this.title,
    this.action,
    this.isAction = true,
    this.isLeading = true,
    this.isTitleWidget = false,
    this.titleWidget,
    this.bottom,
    this.flexiblespace,
    this.expandedHeight = 0,
    this.bgColor,
    this.bottomheight,
    this.collapsedHeight,
  });
  double? expandedHeight;
  Widget? leading, action, titleWidget, flexiblespace;
  String? title;
  bool isAction = true, isLeading = true, isTitleWidget = false;
  Color? bgColor;
  // PreferredSizeWidget? bottom;
  Widget? bottom;
  Size? bottomheight;
  double? collapsedHeight;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return SliverAppBar(
      toolbarHeight: 1,
      // snap: true,
      collapsedHeight: collapsedHeight ?? 2,
      expandedHeight: expandedHeight!,
      automaticallyImplyLeading: false,
      primary: false,
      shadowColor: const Color.fromARGB(0, 194, 185, 185),
      elevation: 0.0,
      clipBehavior: Clip.hardEdge,
      // stretch: false,
      backgroundColor: bgColor ?? theme.surfaceTint,
      // forceElevated: true,
      scrolledUnderElevation: 0,
      flexibleSpace: flexiblespace,
      pinned: true,
      bottom: PreferredSize(preferredSize: bottomheight ?? const Size.fromHeight(50.0), child: bottom!),
      floating: true,
      leading: isLeading ? leading : null,
      title: isTitleWidget
          ? titleWidget
          : (title != null && title != '')
              ? Text(
                  title!,
                )
              : null,
      actions: isAction
          ? [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  action ?? Container(),
                ],
              )
            ]
          : null,
    );
  }
}
/*
class CustomSliverAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  CustomSliverAppBar({
    super.key,
    this.leading,
    this.title,
    this.action,
    this.isAction = true,
    this.isLeading = true,
    this.isTitleWidget = false,
    this.titleWidget,
    this.bottom,
    this.expandedHeight = 0,
    this.flexiblespace,
  });

  Widget? leading, action, titleWidget, flexiblespace;
  String? title;
  bool isAction = true, isLeading = true, isTitleWidget = false;
  PreferredSizeWidget? bottom;
  double? expandedHeight;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return SliverAppBar(
      toolbarHeight: 56,
      collapsedHeight: expandedHeight!,
      expandedHeight: expandedHeight!,
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      pinned: true,
      floating: false,
      flexibleSpace: flexiblespace,
      clipBehavior: Clip.hardEdge,
      automaticallyImplyLeading: false,
      primary: true,
      bottom: bottom == null ? null : PreferredSize(preferredSize: const Size.fromHeight(50.0), child: bottom!),
      leading: isLeading
          ? NuemorphContainer(
              marginAll: 8.0,
              height: 40.0,
              width: 40.0,
              child: leading ?? Container(),
            )
          : Container(),
      title: isTitleWidget
          ? titleWidget
          : Text(
              title!,
            ),
      actions: [
        isAction
            ? NuemorphContainer(
                marginAll: 8.0,
                height: 40.0,
                width: 40.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    action ?? Container(),
                  ],
                ),
              )
            : Container(),
      ],
    );
  }
}
*/