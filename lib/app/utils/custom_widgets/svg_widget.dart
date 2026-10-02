// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:arenabook/app/utils/utils.dart';

class SvgWidget extends StatelessWidget {
  Color color;
  double? height, width;
  String name;
  SvgWidget({
    required this.color,
    this.height,
    this.width,
    required this.name,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: SvgPicture.asset(
        alignment: Alignment.center,
        Utils.getSvgFilePath(name),
        theme: SvgTheme(currentColor: color),
        height: height,
        width: width,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
    );
  }
}
