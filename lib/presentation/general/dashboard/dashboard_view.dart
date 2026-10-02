import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/app_assets.dart';
import '../../../app/service/getx_service/theme_manager.dart';
import '../../../app/utils/custom_functions/functions.dart';
import '../../../app/utils/custom_widgets/custom_appbar.dart';
import '../../../app/utils/custom_widgets/empty_msg.dart';
import 'dashboard_controller.dart';

class DashBoardScreen extends GetView<DashBoardController> {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Functions.homeOrExitRoute();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Dashboard',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => IconButton(
                  onPressed: controller.toggleTheme,
                  icon: Icon(ThemeManager.to.isDarkMode.value ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
              ),
              IconButton(onPressed: controller.logout, icon: const Icon(Icons.logout)),
            ],
          ),
        ),
        body: EmptyMsg(title: 'Starter Ready', msg: 'Start building your features here', img: AppAssets.lottie.listLottie),
      ),
    );
  }
}
