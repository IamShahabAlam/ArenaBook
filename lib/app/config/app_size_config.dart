// For Global MediaQuery ------------------------------
// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

late double w, h;

// Device type detection
bool isMobile = w < 600;
bool isTablet = w >= 600 && w < 1024;
bool isDesktop = w >= 1024;

void HeightWidth(BuildContext context) {
  h = MediaQuery.sizeOf(context).height;
  w = MediaQuery.sizeOf(context).width;
}

// For SizedBox Extension -----------------------------------

extension EmptyPadding on num {
  SizedBox get ph => SizedBox(height: h * toDouble());
  SizedBox get pw => SizedBox(width: w * toDouble());
}

// For Updated Responsive Approach ----------------------
extension ResponsiveExtension on num {
  double get sw => w * this / 100;
  double get sh => h * this / 100;
  // double get sp => w * this / 375;
  // SP with adaptive min/max limits
  double get sp {
    int baseWidth = isMobile
        ? 390
        : isTablet
        ? 600
        : 1200;
    double scaled = w * this / baseWidth;
    // Clamp between 0.8x and 1.5x the original size
    double minSize = this * 0.8;
    double maxSize = this * 1.5;
    return scaled.clamp(minSize, maxSize);
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');

  DateTime toDateTime() {
    return DateTime.parse(this);
  }
}

extension WidgetsExt on Widget {
  Widget center() {
    return Center(child: this);
  }

  Widget padding({EdgeInsetsGeometry padding = const EdgeInsets.all(0.0)}) {
    return Padding(padding: padding, child: this);
  }

  Widget fittedBox(double w, [BoxFit fit = BoxFit.scaleDown]) {
    return SizedBox(
      // height: h,
      width: w,
      child: FittedBox(fit: fit, child: this),
    );
  }

  // Animations ------------------------------------

  Widget animateToTop({int? duration = 500, int? delay = 500}) {
    return animate().fade().slide(
      begin: const Offset(0, 1),
      end: Offset.zero,
      curve: Curves.easeIn,
      duration: Duration(milliseconds: duration!),
      delay: Duration(milliseconds: delay!),
    );
  }

  Widget animateToBottom({int? duration = 500, int? delay = 500}) {
    return animate()
        .moveY(
          curve: Curves.easeIn,
          duration: Duration(milliseconds: duration!),
          delay: Duration(milliseconds: delay!),
        )
        .fadeIn();
  }

  // Widget animateToLeft({int? duration = 500, int? delay = 500}) {
  //   return animate().fade().slide(
  //       begin: const Offset(0, 1), end: Offset.zero, curve: Curves.easeIn, duration: Duration(milliseconds: duration!), delay: Duration(milliseconds: delay!));
  // }

  Widget animateToRight({int? duration = 500, int? delay = 500}) {
    return animate()
        .slideX(
          curve: Curves.easeIn,
          duration: Duration(milliseconds: duration!),
          delay: Duration(milliseconds: delay!),
        )
        .fadeIn();
  }

  Widget animateToVerticalExpand({int? duration = 500, int? delay = 500}) {
    return animate()
        .scaleY(
          curve: Curves.easeIn,
          duration: Duration(milliseconds: duration!),
          delay: Duration(milliseconds: delay!),
        )
        .fadeIn();
  }

  Widget animateToFadeIn({int? duration = 500, int? delay = 500}) {
    return animate()
        .fadeIn(
          curve: Curves.easeIn,
          duration: Duration(milliseconds: duration!),
          delay: Duration(milliseconds: delay!),
        )
        .fadeIn();
  }
}
