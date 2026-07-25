import 'package:flutter/material.dart';

/// Cashly's brand mark: a blue "C" wrapping a green Lao Kip (₭) coin, with a
/// small wallet clasp — see `CLAUDE.md`'s Brand & Design System.
///
/// Rendered from `assets/logo/cashly_mark.png`, exported directly from the
/// approved source artwork (`assets/logo/Logo.ai`) rather than redrawn —
/// several hand-coded `CustomPainter` approximations were tried and
/// rejected as not matching closely enough. The mark's colors are the same
/// in light and dark mode (only the app's neutral chrome changes), so this
/// one asset covers every in-app use: Splash, auth screens, Settings,
/// About. The app icon uses a separately generated white-on-blue variant
/// (see `android/app/src/main/res/mipmap-*/ic_launcher*.png` and
/// `ios/Runner/Assets.xcassets/AppIcon.appiconset/`), not this widget.
class CashlyLogoMark extends StatelessWidget {
  const CashlyLogoMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/cashly_mark.png',
      width: size,
      height: size,
    );
  }
}
