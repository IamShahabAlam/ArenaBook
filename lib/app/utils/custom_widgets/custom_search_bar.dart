// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app/config/app_size_config.dart';

class CustomSearchBar extends StatelessWidget {
  final String text;
  ValueChanged<String>? onChanged;
  final String hintText;
  IconData? icon;
  IconButton? btn;
  bool? autofocus;
  Function()? onTapOutside;
  Function()? onTapPreIcon;
  // TicketListController controller;
  TextEditingController controller;
  bool? showShadow;
  Color? bgColor;

  CustomSearchBar(
      {super.key,
      required this.text,
      this.onChanged,
      this.icon,
      required this.hintText,
      this.btn,
      this.autofocus,
      required this.controller,
      this.onTapOutside,
      this.onTapPreIcon,
      this.bgColor,
      this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);

    final styleActive = TextStyle(color: theme.onSecondary);
    final styleHint = TextStyle(color: theme.onTertiary);
    final style = text.isEmpty ? styleHint : styleActive;
    return Container(
      height: 50,
      // margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: bgColor ?? theme.secondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: showShadow!
            ? [
                BoxShadow(
                  color: theme.primary,
                  offset: const Offset(-3.0, -3.0),
                  blurRadius: 4,
                  spreadRadius: 0,
                  //     offset: true,
                ),
                BoxShadow(
                  color: theme.shadow,
                  offset: const Offset(3.0, 3.0),
                  blurRadius: 4,
                  spreadRadius: 0.0,
                  //  inset: true,
                ),
              ]
            : [],
      ),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(0),
      //   color: Colors.transparent,
      // ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        onTapOutside: (_) {
          onTapOutside;
        },
        autofocus: autofocus ?? false,
        controller: controller, //controller.searchController,
        cursorColor: theme.onPrimary,
        decoration: InputDecoration(
          // ignore: prefer_const_constructors
          //  suffixIcon:widget.btn,
          icon: IconButton(
              onPressed: onTapPreIcon == null
                  ? () {}
                  : () {
                      onTapPreIcon!();
                    },
              icon: Icon(icon, color: style.color)),
          suffixIcon: text.isNotEmpty
              ? GestureDetector(
                  child: Icon(Icons.arrow_drop_down, color: style.color),
                  onTap: () {
                    controller.clear(); // controller.searchController.clear();
                    onChanged!('');
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                )
              : null,
          hintText: hintText,
          hintStyle: style,
          border: InputBorder.none,
        ),
        style: style,
        onChanged: onChanged,
      ),
    );
  }
}
