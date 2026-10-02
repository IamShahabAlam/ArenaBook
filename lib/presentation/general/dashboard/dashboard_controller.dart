import 'package:get/get.dart';

import '../../../app/service/getx_service/theme_manager.dart';
import '../../../app/utils/custom_functions/app_alerts.dart';
import '../../../data/repositories/auth_repository/auth_repo.dart';

class DashBoardController extends GetxController {
  final AuthRepo authRepo = AuthRepo();

  void toggleTheme() => ThemeManager.to.toggleDarkMode();

  void logout() {
    Dialogs.showCustomAlertDialog(
      Get.context!,
      'Do you want to logout?',
      () async {
        Get.back();
        // Tell the backend (fire & forget), then clear local session regardless of the result.
        authRepo.logout();
        await AuthRepo.clearSession();
      },
      () => Get.back(),
    );
  }
}

class DashBoardBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<DashBoardController>(DashBoardController());
  }
}
