import 'package:flutter/material.dart';

/// ArenaBook design tokens. Widgets read colours ONLY through `context.arena`, never hard-coded,
/// so dark and light mode can't drift apart (the prototype's light-mode glitches came from
/// CSS overrides that recoloured every `.text-white`, even on coloured buttons).
///
/// Rule of thumb: `*Text` tokens are for text/icons on [surface]; plain accent tokens are for fills.
/// Light mode uses darker `*Text` shades so they keep >= 4.5:1 contrast on white.
@immutable
class ArenaColors extends ThemeExtension<ArenaColors> {
  const ArenaColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSunken,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cricket,
    required this.cricketText,
    required this.padel,
    required this.padelText,
    required this.limeText,
    required this.warning,
    required this.warningText,
    required this.danger,
    required this.dangerText,
    required this.onAccent,
    required this.avatarBackground,
    required this.navBar,
    required this.overlay,
  });

  final Color background; // app body
  final Color surface; // cards, sheets, dialogs
  final Color surfaceMuted; // inputs, unselected chips
  final Color surfaceSunken; // inner panels (invoice body, segmented track)
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cricket; // emerald fill
  final Color cricketText;
  final Color padel; // blue fill
  final Color padelText;
  final Color limeText;
  final Color warning; // amber fill
  final Color warningText;
  final Color danger; // red fill
  final Color dangerText;
  final Color onAccent; // text/icons on emerald, lime & amber fills
  final Color avatarBackground; // sport icon circles stay dark in both modes (spec)
  final Color navBar;
  final Color overlay; // modal barrier

  static const emerald = Color(0xFF10B981);
  static const lime = Color(0xFFA3E635);
  static const blue = Color(0xFF3B82F6);

  /// Primary call-to-action gradient (same in both modes; [onAccent] text on top).
  static const ctaGradient = LinearGradient(colors: [emerald, lime]);

  static const dark = ArenaColors(
    background: Color(0xFF0B0F17),
    surface: Color(0xFF161D2A),
    surfaceMuted: Color(0xFF0F172A),
    surfaceSunken: Color(0xFF070A12),
    border: Color(0xFF242F42),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    cricket: emerald,
    cricketText: Color(0xFF34D399),
    padel: blue,
    padelText: Color(0xFF60A5FA),
    limeText: Color(0xFFA3E635),
    warning: Color(0xFFF59E0B),
    warningText: Color(0xFFFBBF24),
    danger: Color(0xFFEF4444),
    dangerText: Color(0xFFF87171),
    onAccent: Color(0xFF020617),
    avatarBackground: Color(0xFF020617),
    navBar: Color(0xF00F1520),
    overlay: Color(0xCC000000),
  );

  static const light = ArenaColors(
    background: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF8FAFC),
    surfaceSunken: Color(0xFFF1F5F9),
    border: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    cricket: emerald,
    cricketText: Color(0xFF047857),
    padel: blue,
    padelText: Color(0xFF1D4ED8),
    limeText: Color(0xFF4D7C0F),
    warning: Color(0xFFF59E0B),
    warningText: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
    dangerText: Color(0xFFB91C1C),
    onAccent: Color(0xFF020617),
    avatarBackground: Color(0xFF0F172A),
    navBar: Color(0xF5FFFFFF),
    overlay: Color(0x99000000),
  );

  /// Icon colour inside the always-dark sport avatar (bright shades in both modes).
  Color get cricketOnAvatar => const Color(0xFF34D399);
  Color get padelOnAvatar => const Color(0xFF60A5FA);

  @override
  ArenaColors copyWith() => this;

  @override
  ArenaColors lerp(ArenaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ArenaColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      cricket: l(cricket, other.cricket),
      cricketText: l(cricketText, other.cricketText),
      padel: l(padel, other.padel),
      padelText: l(padelText, other.padelText),
      limeText: l(limeText, other.limeText),
      warning: l(warning, other.warning),
      warningText: l(warningText, other.warningText),
      danger: l(danger, other.danger),
      dangerText: l(dangerText, other.dangerText),
      onAccent: l(onAccent, other.onAccent),
      avatarBackground: l(avatarBackground, other.avatarBackground),
      navBar: l(navBar, other.navBar),
      overlay: l(overlay, other.overlay),
    );
  }
}

extension ArenaThemeContext on BuildContext {
  ArenaColors get arena => Theme.of(this).extension<ArenaColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

class ArenaTheme {
  ArenaTheme._();

  static const bodyFont = 'PlusJakartaSans';
  static const displayFont = 'Outfit';

  static ThemeData get dark => _build(Brightness.dark, ArenaColors.dark);
  static ThemeData get light => _build(Brightness.light, ArenaColors.light);

  static ThemeData _build(Brightness brightness, ArenaColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.cricket,
      onPrimary: c.onAccent,
      secondary: c.padel,
      onSecondary: Colors.white,
      tertiary: c.warning,
      onTertiary: c.onAccent,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surfaceSunken,
      surfaceContainerLow: c.surfaceMuted,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.border,
      outlineVariant: c.border,
      shadow: Colors.black,
      scrim: c.overlay,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.surface,
    );

    TextStyle body(double size, FontWeight weight, [Color? color]) =>
        TextStyle(fontFamily: bodyFont, fontSize: size, fontWeight: weight, color: color ?? c.textPrimary, height: 1.3);
    TextStyle display(double size, FontWeight weight) =>
        TextStyle(fontFamily: displayFont, fontSize: size, fontWeight: weight, color: c.textPrimary, height: 1.15, letterSpacing: -0.2);

    // Sizes are a little larger than the web prototype's 9-10px labels, which are below
    // comfortable reading size on a phone.
    final textTheme = TextTheme(
      displaySmall: display(26, FontWeight.w800),
      headlineSmall: display(22, FontWeight.w800),
      titleLarge: display(18, FontWeight.w700),
      titleMedium: display(15, FontWeight.w700),
      titleSmall: body(13, FontWeight.w700),
      bodyLarge: body(14, FontWeight.w500),
      bodyMedium: body(13, FontWeight.w500),
      bodySmall: body(12, FontWeight.w500, c.textSecondary),
      labelLarge: body(13, FontWeight.w700),
      labelMedium: body(12, FontWeight.w600),
      labelSmall: body(11, FontWeight.w600, c.textSecondary),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.textSecondary, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: body(13, FontWeight.w500, c.textMuted),
        labelStyle: body(12, FontWeight.w600, c.textSecondary),
        counterStyle: body(11, FontWeight.w500, c.textMuted),
        errorStyle: body(11, FontWeight.w600, c.dangerText),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.cricket, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.danger, width: 1.5)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.border),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
        barrierColor: c.overlay,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.overlay,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
        dragHandleColor: c.border,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent, scrimColor: c.overlay),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: body(13, FontWeight.w600, c.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.surfaceMuted,
        headerForegroundColor: c.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.cricket, selectionColor: c.cricket.withValues(alpha: 0.3), selectionHandleColor: c.cricket),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.cricketText, textStyle: body(13, FontWeight.w700)),
      ),
      scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(c.textMuted.withValues(alpha: 0.4))),
    );
  }
}
