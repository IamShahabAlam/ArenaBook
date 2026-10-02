// ignore_for_file: must_be_immutable, unused_local_variable, invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_fontweights.dart';
import '../../config/app_paddings.dart';
import '../custom_functions/functions.dart';

class PopUpDialog extends StatefulWidget {
  final String title;
  final Widget content;
  final bool isAction;
  final bool isCloseBtn;
  final bool isHeader;
  VoidCallback onPressYes;
  final bool? isCancel;
  final Function()? onClose;
  //VoidCallback? onPressNo;
  double? horizontalContentPadding;
  PopUpDialog({
    super.key,
    required this.title,
    required this.content,
    required this.isAction,
    required this.isCloseBtn,
    required this.isHeader,
    required this.onPressYes,
    this.isCancel = false,
    this.onClose,
    this.horizontalContentPadding,
  });

  @override
  State<PopUpDialog> createState() => _PopUpDialogState();
}

class _PopUpDialogState extends State<PopUpDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Get.theme.colorScheme;
    Size screenSize = MediaQuery.of(context).size;
    return AlertDialog(
      elevation: 16.0,
      titlePadding: const EdgeInsets.only(top: 8.0),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppPaddings.appMainPaddingSmall),
      title: widget.isHeader
          ? widget.isCancel == true
              ? Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.onSecondary,
                    ),
                    onPressed: () {
                      Functions.homeOrExitRoute();
                    },
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 40.0,
                  child: widget.isCloseBtn ? Center(child: Text(widget.title)) : Center(child: Text(widget.title)),
                )
          : Container(
              height: 20,
            ),
      content: widget.content,
      contentTextStyle: TextStyle(fontFamily: 'Roboto', fontSize: AppFontSizes.appFontSizeh9, color: theme.onSecondary, letterSpacing: 0.5),
      contentPadding: EdgeInsets.symmetric(
          vertical: AppPaddings.appMainPaddingMedium,
          horizontal: widget.horizontalContentPadding != null ? widget.horizontalContentPadding! : AppPaddings.appMainPaddingSmall),
      titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppFontSizes.appFontSizeh9,
          fontWeight: AppFontWeights.appTextFontWeightBold,
          color: theme.onPrimary,
          letterSpacing: 0.5),
      actions: widget.isAction
          ? [
              TextButton(onPressed: () => widget.onPressYes(), child: const Text("Yes")),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("No")),
            ]
          : [],
    );
  }
}
