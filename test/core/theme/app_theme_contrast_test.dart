import 'dart:math' as math;

import 'package:cashly_lao/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative luminance, straight from the spec:
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double _relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between two colors — always ≥ 1, order-independent.
double _contrastRatio(Color a, Color b) {
  final lA = _relativeLuminance(a);
  final lB = _relativeLuminance(b);
  final lighter = math.max(lA, lB);
  final darker = math.min(lA, lB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Guards the theme's actual foreground/background color pairs against WCAG
/// AA regressions — computed from the real [AppTheme] output (via
/// [AppTheme.colorSchemeFor]/[AppTheme.semanticColorsFor] rather than
/// [AppTheme.light]/[AppTheme.dark], so this stays focused on colors alone
/// rather than also depending on the rest of the theme), not from
/// separately-maintained hex literals.
///
/// `colorScheme.secondary`/`primary`/`error` are each used in two different
/// ways across the app: as fills (a colored background with a white/dark
/// "on" color on top — Material's own contrast-safe pairing) and, directly,
/// as small/bold body text sitting on the plain surface (income/expense
/// figures, the Reports net figure, DestructiveButton's label) — a pairing
/// the brand hex values alone don't clear WCAG AA for in every theme. Those
/// text-on-surface cases go through `AppSemanticColors` instead, which is
/// what this test is really guarding.
void main() {
  const normalTextMin = 4.5;
  const largeTextOrIconMin = 3.0;

  for (final isDark in [false, true]) {
    final label = isDark ? 'dark' : 'light';
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colors = AppTheme.colorSchemeFor(brightness);
    final semantic = AppTheme.semanticColorsFor(brightness);

    test('$label: body text (onSurface on surface)', () {
      expect(
        _contrastRatio(colors.onSurface, colors.surface),
        greaterThanOrEqualTo(normalTextMin),
      );
    });

    test('$label: primary as button fill (onPrimary on primary)', () {
      expect(
        _contrastRatio(colors.onPrimary, colors.primary),
        greaterThanOrEqualTo(normalTextMin),
      );
    });

    test('$label: primary as icon/border color on surface (non-text)', () {
      expect(
        _contrastRatio(colors.primary, colors.surface),
        greaterThanOrEqualTo(largeTextOrIconMin),
      );
    });

    test(
      '$label: AppSemanticColors.primaryForeground as text on surface '
      '(Reports net figure)',
      () {
        expect(
          _contrastRatio(semantic.primaryForeground, colors.surface),
          greaterThanOrEqualTo(normalTextMin),
        );
      },
    );

    test('$label: error as button fill (onError on error)', () {
      expect(
        _contrastRatio(colors.onError, colors.error),
        greaterThanOrEqualTo(normalTextMin),
      );
    });

    test(
      '$label: error as icon/border/progress-bar color on surface '
      '(non-text)',
      () {
        expect(
          _contrastRatio(colors.error, colors.surface),
          greaterThanOrEqualTo(largeTextOrIconMin),
        );
      },
    );

    test(
      '$label: AppSemanticColors.negativeForeground as text on surface '
      '(expense figures, DestructiveButton)',
      () {
        expect(
          _contrastRatio(semantic.negativeForeground, colors.surface),
          greaterThanOrEqualTo(normalTextMin),
        );
      },
    );

    test('$label: tertiary as button/badge fill (onTertiary on tertiary)', () {
      expect(
        _contrastRatio(colors.onTertiary, colors.tertiary),
        greaterThanOrEqualTo(normalTextMin),
      );
    });

    test(
      '$label: tertiaryContainer as SyncStatusBanner fill '
      '(onTertiaryContainer on tertiaryContainer)',
      () {
        expect(
          _contrastRatio(colors.onTertiaryContainer, colors.tertiaryContainer),
          greaterThanOrEqualTo(normalTextMin),
        );
      },
    );

    test(
      '$label: AppSemanticColors.positiveForeground as text on surface '
      '(income figures)',
      () {
        expect(
          _contrastRatio(semantic.positiveForeground, colors.surface),
          greaterThanOrEqualTo(normalTextMin),
        );
      },
    );
  }
}
