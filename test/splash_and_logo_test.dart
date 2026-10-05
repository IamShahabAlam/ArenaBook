import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:arenabook/app/config/arena_theme.dart';
import 'package:arenabook/app/utils/custom_widgets/arena_logo.dart';
import 'package:arenabook/presentation/general/splash/splash_controller.dart';
import 'package:arenabook/presentation/general/splash/splash_view.dart';

/// Same view, but without the timer that navigates to the shell (not registered in these tests).
class _StaySplashController extends SplashController {
  @override
  void onReady() {}
}

Future<void> pumpSplash(WidgetTester tester, {required bool dark, bool reduceMotion = false, Size size = const Size(320, 640)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  Get.put<SplashController>(_StaySplashController());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ArenaTheme.light,
      darkTheme: ArenaTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const SplashView(),
    ),
  );
}

void main() {
  tearDown(() async => Get.deleteAll(force: true));

  for (final dark in [true, false]) {
    testWidgets('splash renders the stadium logo with the orbit animation (${dark ? 'dark' : 'light'})', (tester) async {
      await pumpSplash(tester, dark: dark);
      // Repeating animations never settle, so step through a full orbit instead of pumpAndSettle.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(ArenaLogo), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // The logo asset must really load (a missing/renamed file would report an error here).
      final image = tester.widget<Image>(find.descendant(of: find.byType(ArenaLogo), matching: find.byType(Image)));
      await tester.runAsync(() => precacheImage(image.image, tester.element(find.byType(ArenaLogo))));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox()); // stop the repeating animations
    });
  }

  testWidgets('with "Remove animations" on, the splash has no endless animation', (tester) async {
    await pumpSplash(tester, dark: true, reduceMotion: true);
    // pumpAndSettle times out if anything keeps animating; the progress bar is the only (finite) one left.
    await tester.pumpAndSettle();
    expect(find.byType(ArenaLogo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ArenaLogo is tinted (white art would vanish on light backgrounds)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ArenaTheme.light,
        home: const Scaffold(body: ArenaLogo(size: 40)),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.color, ArenaColors.light.cricketText);
    expect(image.colorBlendMode, BlendMode.srcIn);
    // Decoded at display size, not the full 1024px asset.
    final provider = image.image as ResizeImage;
    expect(provider.width, (40 * tester.view.devicePixelRatio).ceil());
  });

  // Contract for assets/images/logo.png, so a future logo swap can't silently break the app.
  test('logo.png: 1024px square, white on transparent, with a margin; old mark removed', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await rootBundle.load(ArenaLogo.assetPath);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final img = (await codec.getNextFrame()).image;
    expect([img.width, img.height], [1024, 1024]);

    final px = (await img.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
    int alpha(int x, int y) => px.getUint8((y * img.width + x) * 4 + 3);
    var minX = img.width, maxX = 0, minY = img.height, maxY = 0, opaque = 0;
    for (var y = 0; y < img.height; y += 2) {
      for (var x = 0; x < img.width; x += 2) {
        final i = (y * img.width + x) * 4;
        if (px.getUint8(i + 3) < 128) continue;
        opaque++;
        // Tinting (BlendMode.srcIn) keeps only the alpha, but non-white art would look wrong anywhere it's drawn untinted.
        expect([px.getUint8(i), px.getUint8(i + 1), px.getUint8(i + 2)], [255, 255, 255], reason: 'pixel ($x,$y) is not white');
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    expect([alpha(0, 0), alpha(1023, 0), alpha(0, 1023), alpha(1023, 1023)], [0, 0, 0, 0], reason: 'background must be transparent');
    expect(opaque, greaterThan(10000), reason: 'logo looks empty');
    // At least ~3% clear margin on every side, so the art never touches its avatar's edge.
    for (final edge in [minX, minY, 1023 - maxX, 1023 - maxY]) {
      expect(edge, greaterThanOrEqualTo(30));
    }

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(manifest.listAssets(), isNot(contains('assets/images/logo_mark.png')));
  });
}
