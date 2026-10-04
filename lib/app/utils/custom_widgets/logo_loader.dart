// ignore_for_file: must_be_immutable, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../config/app_size_config.dart';
import 'arena_logo.dart';

class LogoLoader extends StatelessWidget {
  String? loadingMsg;
  LogoLoader([this.loadingMsg]);

  @override
  Widget build(BuildContext context) {
    var theme = context.theme.colorScheme;
    HeightWidth(context);
    const double size = 70;
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
                height: size,
                width: size,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: const ArenaLogo(size: size, semanticLabel: 'Loading'))
            .animate(
              onPlay: (icontroller) => icontroller.repeat(),
            )
            .shimmer(
              duration: const Duration(milliseconds: 800),
            ),
        loadingMsg == null
            ? const SizedBox.shrink()
            : Dialog(
                alignment: Alignment.center,
                backgroundColor: theme.tertiary,
                elevation: 12,
                clipBehavior: Clip.antiAlias,
                child: IntrinsicWidth(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
                    child: Text(loadingMsg ?? ''),
                  ),
                ),
              ),
      ],
    ));
  }
}
