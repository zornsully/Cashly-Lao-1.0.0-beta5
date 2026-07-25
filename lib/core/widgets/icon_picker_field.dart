import 'package:flutter/material.dart';

import '../constants/app_icon_key.dart';

/// A labeled grid of [AppIconKey] choices. Shared by Accounts and (later)
/// Categories so both features pick from the exact same curated icon set
/// with identical styling.
class IconPickerField extends StatelessWidget {
  const IconPickerField({
    required this.selected,
    required this.onChanged,
    required this.swatch,
    required this.label,
    super.key,
  });

  final AppIconKey selected;
  final ValueChanged<AppIconKey> onChanged;

  /// The currently-selected color, used to tint the highlighted icon so the
  /// picker previews how the icon+color combination will actually look.
  final Color swatch;

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final key in AppIconKey.values)
              _IconChoice(
                icon: key.icon,
                isSelected: key == selected,
                color: swatch,
                onTap: () => onChanged(key),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
