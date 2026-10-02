import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/config/app_strings.dart';
import 'app/service/getx_service/theme_manager.dart';
import 'app/service/service_handler.dart/theme_store.dart';
import 'app/utils/custom_widgets/main_error_widget.dart';
import 'presentation/general/init_bindings/init_bindings.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  // Initial Bindings having all the required Controllers's Dependency Injection
  // (awaited, so every store can safely read prefs before the first frame)
  await InitBindings().dependencies();

  runApp(const MyApp());
}

void restartApp() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeStore.to.isDarkMode.value == true;
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeManager.to.defaultLightTheme.value,
        darkTheme: ThemeManager.to.defaultDarkTheme.value,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        title: AppStrings.appName,
        initialRoute: PageNames.splashscreen,
        getPages: appRoutes(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          ErrorWidget.builder = (errorDetails) {
            return MainErrorWidget(error: errorDetails);
          };
          // For Bottom Nav Space Get the padding once, doesn't rebuild on keyboard
          return Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewPadding.bottom),
            // System nav bar
            child: MediaQuery(
              data: mediaQuery.copyWith(viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0)),
              child: child!,
            ),
          );
        },
      );
    });
  }
}
