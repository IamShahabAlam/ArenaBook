import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class NuemorphContainer extends StatelessWidget {
  NuemorphContainer({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.marginAll,
    this.border,
    this.margin,
    this.padding,
    this.paddingAll,
    this.isGradient = true,
    this.isShadow = true,
    this.radius,
  });

  Widget child;
  BoxBorder? border;
  EdgeInsetsGeometry? margin, padding;
  bool isGradient = true;
  bool? isShadow;
  BorderRadius? radius;

  double? height, width, marginAll, paddingAll;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: padding ?? EdgeInsets.all(paddingAll ?? 0),
        margin: margin ?? EdgeInsets.all(marginAll ?? 0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.theme.colorScheme.tertiary,
          borderRadius: radius ?? BorderRadius.circular(6.0),
          border: border,
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isGradient
                  ? [context.theme.colorScheme.tertiary, context.theme.colorScheme.surface]
                  : [
                      context.theme.colorScheme.secondary,
                      context.theme.colorScheme.secondary,
                    ]),
          boxShadow: isShadow == true
              ? [
                  BoxShadow(
                    color: context.theme.colorScheme.shadow,
                    offset: const Offset(6.0, 6.0),
                    blurRadius: 8,
                    spreadRadius: 0.0,
                  ),
                ]
              : [],
        ),
        child: child);
  }
}
