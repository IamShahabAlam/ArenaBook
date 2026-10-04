// ignore_for_file: library_private_types_in_public_api

// Asset names only (no path / extension). Resolve them with Utils.getImagePath / getLottiePath / getSvgFilePath.
class AppAssets {
  static _Images get images => _Images();
  static _Lottie get lottie => _Lottie();
  static _SVG get svg => _SVG();
}

class _Images {
  // ArenaBook stadium mark: white on transparent, cropped square from logo.png (the full-size original).
  // Draw it with the ArenaLogo widget, which tints it to the theme.
  final String logo = "logo_mark";

  final String placeHolder = "placehold";
  final String noImage = 'img'; // jpg format
}

class _Lottie {
  final String errorLottie = 'error_lottie';
  final String infoLottie = 'info_lottie';
  final String successLottie = 'success_lottie';
  final String listLottie = 'list_lottie';
}

class _SVG {}
