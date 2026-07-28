import 'package:flutter/material.dart';

import '../constants/app_motion.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// Shared bottom-sheet chrome: rounded top corners, a drag handle, and
/// consistent outer padding, so any screen that needs a bottom sheet gets
/// the same shape as everything else instead of a bare [showModalBottomSheet].
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      sheetAnimationStyle: AnimationStyle(
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
        duration: AppMotion.normal,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const SizedBox(height: AppSpacing.md),
              builder(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}
