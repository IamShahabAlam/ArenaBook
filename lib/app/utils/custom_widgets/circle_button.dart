// ignore_for_file: must_be_immutable

import 'package:flutter/Material.dart';
import 'package:get/get.dart';
import 'package:arenabook/app/config/app_size_config.dart';

// class CircleButton extends StatelessWidget {
//   CircleButton({
//     required this.onTap,
//     required this.icon,
//     super.key,
//   });
//   Function() onTap;
//   IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: CircleAvatar(
//         backgroundColor: context.colors.primary,
//         child: Icon(icon, color: context.colors.surfaceTint, size: 26).center(),
//       ),
//     );
//   }
// }

class CircleButton extends StatelessWidget {
  CircleButton({
    required this.onTap,
    required this.icon,
    this.color,
    this.iconColor,
    this.circleSize = 40.0,
    super.key,
  });
  Function() onTap;
  IconData icon;
  Color? color, iconColor;
  double? circleSize;

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: circleSize,
        width: circleSize,
        decoration: BoxDecoration(color: color ?? theme.onPrimary, shape: BoxShape.circle),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 26).center(),
          ),
        ),
      ),
    );
  }
}
