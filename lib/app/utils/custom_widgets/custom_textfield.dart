import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../config/app_border_radius.dart';
import '../../config/app_size_config.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final ScrollController? scrollController;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool? readOnly;
  final String hintText;
  final String? errorText;
  final Widget? sufixIcon, suffixWidget;
  final Widget? preIcon;
  final bool? obscureText;
  final bool? autofocus;
  final Function()? onTapPre;
  final Function()? onTapSuff;
  final Function(PointerDownEvent)? onTapOutside;
  final Function(String? value)? onChanged;
  final FocusNode? focusNode;
  final int? maxlength;
  final List<TextInputFormatter>? inputformatter;
  final Color? errorColor;
  final String? prefixText;
  final String? suffixText;
  final int? maxLines;
  final EdgeInsetsGeometry? contentpadding;
  final Color? borderColor;
  final bool? showBorder;
  final Color? fillColor;
  final bool? isSuffixWidget;
  final bool? isDense;
  final Function(String value)? onFieldSubmitted;
  const CustomTextField({
    required this.textEditingController,
    required this.hintText,
    this.onFieldSubmitted,
    this.autofocus,
    this.validator,
    this.readOnly,
    this.preIcon,
    this.obscureText,
    this.onTapPre,
    this.sufixIcon,
    this.onTapSuff,
    this.onTapOutside,
    this.focusNode,
    this.keyboardType,
    this.maxlength,
    this.inputformatter,
    this.errorText,
    this.errorColor,
    this.onChanged,
    this.prefixText,
    this.suffixText,
    this.maxLines = 1,
    this.contentpadding,
    this.borderColor,
    this.showBorder = false,
    this.fillColor,
    this.scrollController,
    this.suffixWidget,
    this.isSuffixWidget = false,
    this.isDense,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);
    return TextFormField(
      scrollController: scrollController,
      clipBehavior: Clip.hardEdge,
      autofocus: autofocus ?? false,
      // enabled: readOnly ?? false,
      onTapOutside: onTapOutside,

      maxLines: maxLines,
      maxLength: maxlength,
      inputFormatters: inputformatter,
      keyboardType: keyboardType,
      controller: textEditingController,
      readOnly: readOnly ?? false,
      focusNode: focusNode,
      validator: validator,
      obscureText: obscureText ?? false,
      cursorColor: theme.onPrimary,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        // prefixText: prefixText,
        // suffixText: suffixText,

        // prefixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: theme.onPrimary),
        // suffixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: theme.onPrimary),
        prefixIcon: preIcon == null ? null : GestureDetector(onTap: onTapPre, child: preIcon),
        suffixIcon: sufixIcon == null ? null : GestureDetector(onTap: onTapSuff, child: sufixIcon),
        // suffix: GestureDetector(onTap: onTapSuff, child: isSuffixWidget! == true ? suffixWidget ?? const SizedBox.shrink() : const SizedBox.shrink()),
        contentPadding: contentpadding, // contentpadding ?? const EdgeInsets.only(left: 15, right: 15, top: 5),
        isDense: isDense ?? true,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circularBorderHigh,
          borderSide: showBorder == false ? BorderSide.none : BorderSide(width: 1, color: borderColor ?? theme.onPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circularBorderHigh,
          borderSide: showBorder == false ? BorderSide.none : BorderSide(width: 1, color: borderColor ?? theme.onPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circularBorderHigh,
          borderSide: showBorder == false ? BorderSide.none : BorderSide(width: 1, color: borderColor ?? theme.onPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circularBorderHigh,
          borderSide: showBorder == false ? BorderSide.none : BorderSide(width: 1, color: borderColor ?? theme.onPrimary),
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.circularBorderHigh,
          borderSide: showBorder == false ? BorderSide.none : BorderSide(width: 1, color: borderColor ?? theme.onPrimary),
        ),
        fillColor: fillColor ?? Colors.transparent,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
        // floatingLabelAlignment: FloatingLabelAlignment.start,
        // floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintText: hintText,
        hintStyle: TextStyle(color: theme.outline),
        filled: true,
        errorText: errorText,
      ),
    );
  }
}
