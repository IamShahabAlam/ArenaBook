import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// import 'package:device_preview/device_preview.dart';
import 'app/config/app_strings.dart';
import 'app/config/arena_theme.dart';
import 'app/service/service_handler.dart/theme_store.dart';
import 'app/utils/custom_widgets/main_error_widget.dart';
import 'presentation/general/init_bindings/init_bindings.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicences();
  try {
    // Initial Bindings having all the required Controllers's Dependency Injection
    // (awaited, so every store can safely read prefs and the bookings ledger before the first frame)
    await InitBindings().dependencies();
  } catch (e, stack) {
    // Without storage the app can't work; say so instead of showing a blank screen.
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'startup'));
    runApp(_StartupErrorApp(error: e));
    return;
  }

  runApp(
    // DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()));
    const MyApp(),
  );
}

void restartApp() {
  runApp(const MyApp());
}

/// Bundled fonts are OFL-licensed; list them on the licences page.
void _registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [('Outfit', 'OFL-Outfit.txt'), ('Plus Jakarta Sans', 'OFL-PlusJakartaSans.txt')]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeStore.to.isDarkMode.value;
      return GetMaterialApp(
        // useInheritedMediaQuery: true,
        // locale: DevicePreview.locale(context),
        // builder: DevicePreview.appBuilder,
        debugShowCheckedModeBanner: false,
        theme: ArenaTheme.light,
        darkTheme: ArenaTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        title: AppStrings.appName,
        initialRoute: PageNames.splashscreen,
        getPages: appRoutes(),
        builder: (context, child) {
          ErrorWidget.builder = (errorDetails) => MainErrorWidget(error: errorDetails);
          final colors = isDark ? ArenaColors.dark : ArenaColors.light;
          // Edge-to-edge: transparent system bars, icon brightness follows the theme.
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: colors.navBar,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            child: child!,
          );
        },
      );
    });
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ArenaTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: context.arena.dangerText),
                  const SizedBox(height: 16),
                  Text('ArenaBook could not start', style: context.text.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Local storage could not be opened. Please restart the app. If this keeps happening, contact support before reinstalling so your bookings are not lost.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                  if (kDebugMode) ...[const SizedBox(height: 16), Text('$error', style: context.text.bodySmall)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
