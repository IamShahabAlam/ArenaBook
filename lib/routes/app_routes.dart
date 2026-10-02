import 'package:get/get.dart';

import 'app_pages.dart';
import '../presentation/general/auth_views/login/login_controller.dart';
import '../presentation/general/auth_views/login/login_view.dart';
import '../presentation/general/dashboard/dashboard_controller.dart';
import '../presentation/general/dashboard/dashboard_view.dart';
import '../presentation/general/splash/splash_controller.dart';
import '../presentation/general/splash/splash_view.dart';

// Every screen = PageNames entry + GetPage here (+ its Binding at the bottom of the controller file).
List<GetPage> appRoutes() => [
  //splash screen
  GetPage(
    name: PageNames.splashscreen,
    page: () => const SplashView(),
    binding: SplashBinding(),
    transition: Transition.leftToRightWithFade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  //login screen
  GetPage(
    name: PageNames.loginScreen,
    page: () => const LoginScreen(),
    binding: LoginBinding(),
    transition: Transition.leftToRightWithFade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  // dashboard screen
  GetPage(
    name: PageNames.dashBoardScreen,
    page: () => const DashBoardScreen(),
    binding: DashBoardBinding(),
    transition: Transition.leftToRightWithFade,
    transitionDuration: const Duration(milliseconds: 500),
  ),
];
