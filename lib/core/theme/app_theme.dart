import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../constants/app_elevation.dart';
import '../constants/app_radius.dart';
import 'app_semantic_colors.dart';

/// Cashly's brand palette — see `CLAUDE.md`'s Brand & Design System for the
/// full rationale. Every value here traces back to that single source of
/// truth; nothing in this file should be a value chosen ad hoc.
abstract final class _BrandColors {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color neutralGray = Color(0xFFF7F9FC);
  static const Color accentGold = Color(0xFFF59E0B);

  /// Not part of the named palette (which has no error color) — chosen to
  /// match the same source system as the rest of the palette (Tailwind's
  /// red-600) rather than Material's default red.
  static const Color errorRed = Color(0xFFDC2626);

  /// A darker step down the same green (Tailwind's emerald-700) for use as
  /// text/icon color in light mode only — see `AppSemanticColors`'s doc
  /// comment for why `secondaryGreen` itself isn't safe for that. Not a
  /// second brand color: `secondary` in [ColorScheme] stays pinned to
  /// `secondaryGreen` everywhere else (fills, dots, tints).
  static const Color secondaryGreenAccessibleForeground = Color(0xFF047857);

  /// A lighter step up the same blue (Tailwind's blue-500, one step above
  /// `primaryBlue`'s blue-600) for use as small/bold body text in dark mode
  /// only — see `AppSemanticColors`'s doc comment. `primary` in
  /// [ColorScheme] stays pinned to `primaryBlue` everywhere else.
  static const Color primaryBlueAccessibleForeground = Color(0xFF3B82F6);

  /// Tailwind red-700 — a darker step down `errorRed` for text in light
  /// mode, where the pinned red-600 clears AA by only a hair. `error` in
  /// [ColorScheme] stays pinned to `errorRed` everywhere else.
  static const Color errorRedAccessibleForegroundLight = Color(0xFFB91C1C);

  /// Tailwind red-400 — a lighter step up `errorRed` for text in dark mode,
  /// where red-600 falls short of AA more clearly (~3.7:1).
  static const Color errorRedAccessibleForegroundDark = Color(0xFFF87171);
}

/// Central place for Material 3 light/dark themes. Every screen should pull
/// colors and text styles from `Theme.of(context)` rather than hardcoding
/// values, so this is the only file that needs to change for a rebrand.
///
/// Depth is expressed as real soft drop-shadows (see `AppElevation`)
/// rather than Material 3's default flat/tonal-tint elevation — closer to
/// the Revolut/Monzo/Copilot Money benchmark than to stock Material.
/// `surfaceTintColor: Colors.transparent` shows up throughout this file
/// specifically to opt out of that default tonal tint in favor of shadows.
abstract final class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  /// The pure color computation, split out from [_buildTheme] so it's
  /// reachable without also constructing the rest of the theme — see
  /// `test/core/theme/app_theme_contrast_test.dart`, which needs exactly
  /// this and nothing else to verify real contrast ratios.
  static ColorScheme colorSchemeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // Seeded from the primary blue for a harmonious, accessible tonal
    // palette (outlines, surface containers, etc.), with the brand's
    // named roles pinned to their exact spec values rather than left to
    // seed-derived approximations. The brand colors stay the same across
    // light/dark — only the neutral surface tone (gray vs. navy) changes —
    // matching how Revolut/Monzo keep a consistent brand accent regardless
    // of theme.
    return ColorScheme.fromSeed(
      seedColor: _BrandColors.primaryBlue,
      brightness: brightness,
      primary: _BrandColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: _BrandColors.secondaryGreen,
      onSecondary: Colors.white,
      // Gold sits at a lightness where dark text reads with far better
      // contrast than white — unlike primary/secondary, which are dark
      // enough for white text.
      tertiary: _BrandColors.accentGold,
      onTertiary: _BrandColors.darkNavy,
      error: _BrandColors.errorRed,
      onError: Colors.white,
      // Dark mode's surface is Dark Navy, never pure black — a deliberate
      // choice so elevated surfaces still read as "lifted" against it.
      surface: isDark ? _BrandColors.darkNavy : _BrandColors.neutralGray,
      onSurface: isDark ? _BrandColors.neutralGray : _BrandColors.darkNavy,
    );
  }

  /// See [colorSchemeFor] — same reasoning, split out for testability.
  static AppSemanticColors semanticColorsFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AppSemanticColors(
      positiveForeground: isDark
          ? _BrandColors.secondaryGreen
          : _BrandColors.secondaryGreenAccessibleForeground,
      primaryForeground: isDark
          ? _BrandColors.primaryBlueAccessibleForeground
          : _BrandColors.primaryBlue,
      negativeForeground: isDark
          ? _BrandColors.errorRedAccessibleForegroundDark
          : _BrandColors.errorRedAccessibleForegroundLight,
    );
  }

  /// Material 3's default type scale reads a touch large next to benchmark
  /// apps like Revolut/Monzo/Copilot Money — a gentle, uniform scale-down
  /// keeps the whole scale's proportions (display > headline > title >
  /// body > label) intact rather than shrinking one size in isolation.
  /// Applied both to [TextTheme] (below) and to the button themes further
  /// down, which hardcode their own font size rather than deriving it from
  /// [TextTheme].
  static const double _textScaleFactor = 0.92;

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = colorSchemeFor(brightness);

    // `ThemeData.light()/.dark().textTheme` alone has a null `fontSize` on
    // every field: Material 3's font *geometry* (englishLike/dense/tall)
    // is normally merged in later by Flutter itself, based on the current
    // locale's script category, once the theme actually reaches a
    // `BuildContext` — it's never present on a `ThemeData` built outside a
    // widget tree, like this one. Reconstructing that merge explicitly
    // here (geometry first, then the brightness-appropriate color
    // overlay) is what gives every field a real, non-null size to scale.
    // `englishLike` applies uniformly regardless of locale, which is
    // consistent with how this app already treats Lao — via font
    // *fallback* below, not per-locale geometry switching.
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: colorScheme,
    );
    final baseTextTheme = typography.englishLike.merge(
      isDark ? typography.white : typography.black,
    );
    // Fallback is glyph-based, not locale-based: Manrope has no Lao
    // glyphs, so any Lao character in a string — regardless of the
    // app's current locale — automatically renders via Noto Sans Lao
    // instead, while Latin text keeps using Manrope. No per-locale font
    // switching needed. All three families are bundled local assets (see
    // pubspec.yaml) rather than fetched via `google_fonts` at runtime — a
    // network-dependent app-startup theme build is a real crash risk (a
    // failed/slow fetch on first launch previously left `TextTheme.apply`
    // building on a style with a null `fontSize`), not just a slower one.
    final textTheme = baseTextTheme.apply(
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['Plus Jakarta Sans', 'Noto Sans Lao'],
      fontSizeFactor: _textScaleFactor,
    );

    final shadowColor = _BrandColors.darkNavy;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: AppElevation.cardElevation,
          shadowColor: shadowColor.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: TextStyle(
            fontSize: 16 * _textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: TextStyle(
            fontSize: 16 * _textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.cardElevation,
        shadowColor: shadowColor.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: AppElevation.dialogElevation,
        shadowColor: shadowColor.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppElevation.sheetElevation,
        modalElevation: AppElevation.sheetElevation,
        shadowColor: shadowColor.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: AppElevation.sheetElevation,
        shadowColor: shadowColor.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: BorderSide.none,
      ),
      // A subtle fade+scale on every route push/pop instead of Android's
      // default instant cut or Material 2's abrupt slide-up — Motion is a
      // first-class design-system requirement (see CLAUDE.md), not
      // polish layered on at the end. iOS/macOS keep their native
      // slide-from-edge convention, which already reads as premium and
      // platform-appropriate.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [semanticColorsFor(brightness)],
    );
  }
}
