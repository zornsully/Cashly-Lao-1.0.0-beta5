import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';

/// A single-arc progress ring for one savings goal — the "how close am I"
/// visual on the Detail screen. Deliberately not rendered per-card on the
/// list (see this feature's footprint notes) — only Detail shows one of
/// these at a time.
class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    required this.percentage,
    required this.color,
    required this.isCompleted,
    super.key,
    this.diameter = 160,
    this.child,
  });

  final double percentage;
  final Color color;
  final bool isCompleted;
  final double diameter;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Overshoot is real (a contribution can push past the target) but a
    // ring sweeping past a full circle would read as a rendering bug, not
    // progress — clamp the *visual* fraction while text elsewhere still
    // shows the true, unclamped percentage.
    final rawFraction = percentage / 100;
    final fraction = rawFraction < 0
        ? 0.0
        : (rawFraction > 1 ? 1.0 : rawFraction);
    final ringColor = isCompleted ? theme.colorScheme.tertiary : color;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: fraction),
        duration: AppMotion.slow,
        curve: AppMotion.enter,
        builder: (context, animatedFraction, _) {
          return CustomPaint(
            painter: _RingPainter(
              fraction: animatedFraction,
              color: ringColor,
              trackColor: theme.colorScheme.surfaceContainerHighest,
            ),
            child: child == null
                ? null
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(child: child),
                  ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  static const double _strokeWidth = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, 0, 2 * pi, false, trackPaint);

    if (fraction <= 0) return;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, fraction * 2 * pi, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
