import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_motion.dart';
import '../../domain/entities/savings_goal_progress.dart';
import '../providers/savings_goal_providers.dart';

/// Wraps [child] in a [Stack] with a one-shot confetti burst that plays only
/// at the exact moment a goal's progress crosses from incomplete to
/// complete — never on first opening an already-completed goal. Mounted
/// permanently (invisible at rest, negligible cost) on the goal Detail
/// screen, watching the goal's own progress rather than requiring the
/// parent to wire up a controller.
class GoalCelebrationOverlay extends ConsumerStatefulWidget {
  const GoalCelebrationOverlay({
    required this.goalId,
    required this.child,
    super.key,
  });

  final String goalId;
  final Widget child;

  @override
  ConsumerState<GoalCelebrationOverlay> createState() =>
      _GoalCelebrationOverlayState();
}

class _GoalCelebrationOverlayState
    extends ConsumerState<GoalCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.celebratory,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleProgressChange(
    AsyncValue<SavingsGoalProgress?>? previous,
    AsyncValue<SavingsGoalProgress?> next,
  ) {
    final wasCompleted = previous?.value?.isCompleted ?? false;
    final isCompleted = next.value?.isCompleted ?? false;
    if (!wasCompleted && isCompleted) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      savingsGoalProgressByIdProvider(widget.goalId),
      _handleProgressChange,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isDismissed) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _controller.value,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                      colorScheme.tertiary,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const int _particleCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed seed so every repaint of the *same* burst lays out particles
    // identically (only their fall position/opacity, driven by [progress],
    // changes) rather than reshuffling randomly on every animation tick.
    final random = math.Random(7);

    for (var i = 0; i < _particleCount; i++) {
      final startX = random.nextDouble() * size.width;
      final horizontalDrift = (random.nextDouble() - 0.5) * 60;
      // Staggers each particle's start slightly so the burst doesn't fall
      // as one rigid sheet.
      final fallDelay = random.nextDouble() * 0.3;

      final rawParticleProgress =
          (progress - fallDelay) / (1 - fallDelay);
      final particleProgress = rawParticleProgress < 0
          ? 0.0
          : (rawParticleProgress > 1 ? 1.0 : rawParticleProgress);
      if (particleProgress <= 0) continue;

      final rawOpacity = particleProgress > 0.7
          ? (1 - particleProgress) / 0.3
          : 1.0;
      final opacity = rawOpacity < 0 ? 0.0 : (rawOpacity > 1 ? 1.0 : rawOpacity);
      if (opacity <= 0) continue;

      final dy = particleProgress * (size.height + 40) - 20;
      final dx = startX + horizontalDrift * particleProgress;
      final particleSize = 4.0 + random.nextDouble() * 4;
      final rotation =
          particleProgress * math.pi * 4 * (i.isEven ? 1 : -1);

      final paint = Paint()..color = colors[i % colors.length].withValues(
        alpha: opacity,
      );

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particleSize,
          height: particleSize * 1.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
