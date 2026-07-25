import 'package:flutter/material.dart';

/// Caps a screen's main content at a comfortable reading width and centers
/// it, so list/dashboard screens don't stretch full-bleed edge to edge on
/// a tablet. A no-op on phone-width screens, since the constraint is
/// wider than the available space there.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({required this.child, super.key, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
