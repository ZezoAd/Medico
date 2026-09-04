/// The app's two [ThemeData] objects, built from the Aurora tokens.
///
/// Before this file, `main.dart` declared one inline light theme and nothing
/// else, so `Theme.of(context).brightness` reported `light` on every device and
/// three widgets had to read `MediaQuery.platformBrightnessOf` behind the
/// framework's back to find out otherwise. Those widgets now read
/// [AuroraPalette] off the active theme, which means the person's own
/// light/dark/system choice is what they follow.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aurora_tokens.dart';

abstract final class AppTheme {
  /// The warm cream the light theme has always painted its pages in. Pinned
  /// here rather than in [AuroraColors] because this is a light-mode page
  /// colour only: `AuroraColors.background` stays what it is for every other
  /// consumer, and dark mode is untouched.
  static const lightScaffoldBackground = Color(0xFFFAF7F2);

  static ThemeData get light => _build(
    brightness: Brightness.light,
    palette: AuroraPalette.light,
    scaffoldBackground: lightScaffoldBackground,
  );

  static ThemeData get dark =>
      _build(brightness: Brightness.dark, palette: AuroraPalette.dark);

  /// One builder for both, so a surface can never be themed in light and
  /// forgotten in dark — the whole failure mode this file exists to prevent.
  ///
  /// [scaffoldBackground] overrides the page colour for a theme whose shipped
  /// background differs from its palette token; it defaults to the token.
  static ThemeData _build({
    required Brightness brightness,
    required AuroraPalette palette,
    Color? scaffoldBackground,
  }) {
    final isDark = brightness == Brightness.dark;

    // Seeded from the brand green in both, so Material's own components
    // (ripples, cursors, selection handles) stay Aurora-coloured. The surface
    // and text roles are then overridden with the palette, because the
    // generated tonal values are not the locked design's greys.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AuroraColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AuroraColors.primary,
          secondary: AuroraColors.primaryBlue,
          surface: palette.surface,
          onSurface: palette.ink,
          error: AuroraColors.danger,
        );

    final textTheme = _textTheme(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground ?? palette.background,
      canvasColor: scaffoldBackground ?? palette.background,
      dividerColor: palette.divider,
      // Tajawal for the body scale, matching AuroraText.body. Headings stay
      // Noto Kufi at their call sites via AuroraText.display — a TextTheme
      // cannot express "two faces by role" on its own.
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: palette.secondary),
      primaryIconTheme: IconThemeData(color: palette.secondary),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AuroraRadius.xl),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.secondary,
        textColor: palette.ink,
        selectedColor: AuroraColors.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.tonal,
        hintStyle: AuroraText.body(
          size: AuroraFontSize.bodyLg,
          color: palette.muted,
        ),
        labelStyle: AuroraText.body(
          size: AuroraFontSize.body,
          color: palette.secondary,
        ),
        prefixIconColor: palette.secondary,
        suffixIconColor: palette.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.md),
          borderSide: const BorderSide(color: AuroraColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuroraRadius.md),
          borderSide: const BorderSide(color: AuroraColors.danger, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AuroraColors.tonalDark : AuroraColors.ink,
        contentTextStyle: AuroraText.body(
          size: AuroraFontSize.body,
          color: isDark ? AuroraColors.inkDark : Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AuroraColors.primary,
      ),
      // Every widget that resolves a colour from context reads this rather
      // than the ColorScheme — it is the only place the locked Aurora greys
      // live in a form the theme can hand out.
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }

  /// The Tajawal body scale, tinted for [palette].
  ///
  /// Only the roles the app actually renders are filled in. The rest inherit
  /// [ThemeData]'s defaults, tinted by `onSurface` — wrong on none of them,
  /// because nothing in this app draws unstyled Material text at those sizes.
  static TextTheme _textTheme(AuroraPalette palette) {
    TextStyle body(double size, FontWeight weight, Color color) =>
        GoogleFonts.tajawal(fontSize: size, fontWeight: weight, color: color);

    return TextTheme(
      displayLarge: body(AuroraFontSize.display, FontWeight.w700, palette.ink),
      headlineLarge: body(AuroraFontSize.h1, FontWeight.w700, palette.ink),
      headlineMedium: body(AuroraFontSize.h2, FontWeight.w700, palette.ink),
      titleLarge: body(AuroraFontSize.h3, FontWeight.w700, palette.ink),
      titleMedium: body(AuroraFontSize.bodyLg, FontWeight.w600, palette.ink),
      bodyLarge: body(AuroraFontSize.bodyLg, FontWeight.w400, palette.ink),
      bodyMedium: body(AuroraFontSize.body, FontWeight.w400, palette.ink),
      bodySmall: body(
        AuroraFontSize.caption,
        FontWeight.w400,
        palette.secondary,
      ),
      labelLarge: body(AuroraFontSize.body, FontWeight.w600, palette.ink),
      labelSmall: body(AuroraFontSize.micro, FontWeight.w500, palette.muted),
    );
  }
}
