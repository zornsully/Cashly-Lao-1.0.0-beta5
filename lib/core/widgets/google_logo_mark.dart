import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Google's official multi-color "G" mark, for the "Continue with Google"
/// button — per Google's Sign-In branding guidelines, this exact mark
/// (not a Material icon substitute) is required to represent the button.
class GoogleLogoMark extends StatelessWidget {
  const GoogleLogoMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/google_logo.svg',
      width: size,
      height: size,
    );
  }
}
