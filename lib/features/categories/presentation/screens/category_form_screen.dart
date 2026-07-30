import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/color_picker_field.dart';
import '../../../../core/widgets/icon_picker_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../providers/category_controller.dart';

/// Shared Add/Edit form. Pass [existing] when editing so the fields are
/// pre-filled and the submit action updates instead of creates. Pass
/// [initialType] when creating so the form opens on the tab the user was
/// already viewing (Income or Expense).
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.existing, this.initialType});

  final CategoryEntity? existing;
  final CategoryType? initialType;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryType _type;
  late AppIconKey _icon;
  late AppColorKey _color;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _type = existing?.type ?? widget.initialType ?? CategoryType.expense;
    _icon = existing?.icon ?? AppIconKey.other;
    _color = existing?.color ?? AppColorKey.emerald;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final controller = ref.read(categoryControllerProvider.notifier);

    final success = _isEditing
        ? await controller.updateCategory(
            id: widget.existing!.id,
            name: name,
            type: _type,
            icon: _icon,
            color: _color,
          )
        : await controller.createCategory(
            name: name,
            type: _type,
            icon: _icon,
            color: _color,
          );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      context.pop();
    } else {
      final message =
          controller.failure?.message ?? l10n.saveCategoryFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(categoryControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDefault = widget.existing?.isDefault ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.categoryFormEditTitle : l10n.addCategoryButton,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDefault) ...[
                      Row(
                        children: [
                          AppBadge(label: l10n.defaultBadgeLabel),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.defaultCategoryLockedHelper,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    AppTextField(
                      label: l10n.categoryNameLabel,
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      prefixIcon: AppSymbols.labelOutline,
                      validator: (value) => Validators.requiredField(
                        context,
                        value,
                        label: l10n.categoryNameLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.categoryTypeLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<CategoryType>(
                      segments: [
                        ButtonSegment(
                          value: CategoryType.expense,
                          label: Text(l10n.expenseLabel),
                          icon: const Icon(AppSymbols.arrowUpward),
                        ),
                        ButtonSegment(
                          value: CategoryType.income,
                          label: Text(l10n.incomeLabel),
                          icon: const Icon(AppSymbols.arrowDownward),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selection) =>
                          setState(() => _type = selection.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    IconPickerField(
                      selected: _icon,
                      swatch: _color.color,
                      label: l10n.iconLabel,
                      onChanged: (icon) => setState(() => _icon = icon),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ColorPickerField(
                      selected: _color,
                      label: l10n.colorLabel,
                      onChanged: (color) => setState(() => _color = color),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _isEditing
                          ? l10n.saveChangesButton
                          : l10n.addCategoryButton,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
