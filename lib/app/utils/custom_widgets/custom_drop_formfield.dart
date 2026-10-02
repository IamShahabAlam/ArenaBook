import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:arenabook/app/utils/custom_widgets/common_text.dart';

import '../../config/app_border_radius.dart';

class CustomDropDownFormField extends StatelessWidget {
  const CustomDropDownFormField(
      {
      // required this.text,
      // required this.hintText,
      this.value,
      this.items,
      this.onChanged,
      this.errorColor,
      this.errorText,
      this.focusNode,
      this.icon,
      this.inputformatter,
      this.keyboardType,
      this.labelText,
      this.maxlength,
      this.obscureText,
      this.onTap,
      this.readOnly,
      this.validator,
      this.borderColor,
      this.showBorder = false,
      this.showLabel = false,
      this.fillColor,
      super.key});

  // final String text;
  // final String hintText;
  final Object? value;
  final List<DropdownMenuItem<Object>>? items;
  final void Function(Object?)? onChanged;
  final TextInputType? keyboardType;
  final String? Function(Object?)? validator;
  final bool? readOnly;
  final String? labelText;
  final String? errorText;
  final Widget? icon;
  final bool? obscureText;
  final bool? showLabel;
  final Function()? onTap;
  //final Function(String? value)? onChanged;
  final FocusNode? focusNode;
  final int? maxlength;
  final List<TextInputFormatter>? inputformatter;
  final Color? errorColor;
  final Color? borderColor;
  final bool? showBorder;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return DropdownButtonFormField(
      isExpanded: false,
      dropdownColor: theme.primary,
      style: TextStyle(color: theme.onSecondary),
      hint: CommonText(text: labelText ?? '', fontSize: 16, color: theme.outline.withValues(alpha: 0.6)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(left: 15, right: 15),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: showBorder == false ? BorderSide.none : BorderSide(color: errorColor ?? borderColor ?? theme.secondary),
            borderRadius: AppBorderRadius.circularBorderHigh),
        focusedBorder: OutlineInputBorder(
            borderSide: showBorder == false ? BorderSide.none : BorderSide(color: borderColor ?? theme.secondary),
            borderRadius: AppBorderRadius.circularBorderHigh),
        enabledBorder: OutlineInputBorder(
            borderSide: showBorder == false ? BorderSide.none : BorderSide(color: borderColor ?? theme.secondary),
            borderRadius: AppBorderRadius.circularBorderHigh),
        errorBorder: OutlineInputBorder(
            borderSide: showBorder == false ? BorderSide.none : BorderSide(color: errorColor ?? theme.secondary),
            borderRadius: AppBorderRadius.circularBorderHigh),
        errorStyle: const TextStyle(color: Colors.red),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: fillColor ?? theme.secondary,
        errorText: errorText,
        labelText: showLabel! ? labelText : null,
        labelStyle: TextStyle(color: theme.onPrimary, fontSize: 20.0),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator ??
          (p0) {
            return null;
          },
    );
  }
}
