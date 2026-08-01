import 'package:flutter/material.dart';

/// Gives authenticated pages a generous desktop workspace without letting
/// ultrawide displays turn financial tables into unreadable full-bleed rows.
/// Individual list/card pages keep their compact mobile padding; this wrapper
/// adds the remaining desktop gutter so their total horizontal padding is 32px.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    super.key,
    this.maxWidth = 1440,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopGutter = constraints.maxWidth >= 1200 ? 16.0 : 0.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: desktopGutter),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
