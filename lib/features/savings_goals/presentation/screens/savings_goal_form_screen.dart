import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/color_picker_field.dart';
import '../../../../core/widgets/icon_picker_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/goal_contribution_frequency.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../providers/savings_goal_controller.dart';
import '../providers/savings_goal_providers.dart';
import '../utils/goal_contribution_frequency_label.dart';

/// Shared Add/Edit form. A goal's linked account is fixed once created (see
/// `SavingsGoalRepository.updateGoal`) — everything else can change.
class SavingsGoalFormScreen extends ConsumerStatefulWidget {
  const SavingsGoalFormScreen({super.key, this.existing});

  final SavingsGoalEntity? existing;

  @override
  ConsumerState<SavingsGoalFormScreen> createState() =>
      _SavingsGoalFormScreenState();
}

class _SavingsGoalFormScreenState extends ConsumerState<SavingsGoalFormScreen> {
  static const _createNewAccountSentinel = '__create_new_account__';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _autoContributionAmountController;
  String? _accountId;
  late AppIconKey _icon;
  late AppColorKey _color;
  late bool _autoContributionEnabled;
  late GoalContributionFrequency _frequency;

  bool get _isEditing => widget.existing != null;

  /// [DropdownButtonFormField] asserts that its current value matches
  /// exactly one of [items]. A create-mode submit can briefly leave
  /// `_accountId` pointing at an account this same rebuild just excluded
  /// from `eligibleAccounts` (the just-created goal now claims it as
  /// "already backs an active goal") in the one frame before
  /// `context.pop()` actually leaves this screen — inject a disabled
  /// placeholder for that frame instead of crashing. Same pattern as
  /// `transaction_form_screen.dart`'s `_withOrphanFallback`.
  List<DropdownMenuItem<String>> _withOrphanFallback({
    required List<DropdownMenuItem<String>> items,
    required Set<String> knownIds,
    required String? currentValue,
    required String missingLabel,
  }) {
    if (currentValue == null || knownIds.contains(currentValue)) {
      return items;
    }
    return [
      ...items,
      DropdownMenuItem(
        value: currentValue,
        enabled: false,
        child: Text(missingLabel),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _targetAmountController = TextEditingController(
      text: existing != null ? existing.targetAmount.toStringAsFixed(2) : '',
    );
    _autoContributionAmountController = TextEditingController(
      text: existing?.autoContributionAmount != null
          ? existing!.autoContributionAmount!.toStringAsFixed(2)
          : '',
    );
    _accountId = existing?.accountId;
    _icon = existing?.icon ?? AppIconKey.savings;
    _color = existing?.color ?? AppColorKey.emerald;
    _autoContributionEnabled = existing?.hasAutoContribution ?? false;
    _frequency =
        existing?.autoContributionFrequency ??
        GoalContributionFrequency.monthly;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _autoContributionAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final targetAmount = double.parse(_targetAmountController.text.trim());
    final autoContributionAmount = _autoContributionEnabled
        ? double.parse(_autoContributionAmountController.text.trim())
        : null;
    final autoContributionFrequency = _autoContributionEnabled
        ? _frequency
        : null;
    final controller = ref.read(savingsGoalControllerProvider.notifier);

    final success = _isEditing
        ? await controller.updateGoal(
            id: widget.existing!.id,
            name: name,
            targetAmount: targetAmount,
            icon: _icon,
            color: _color,
            autoContributionAmount: autoContributionAmount,
            autoContributionFrequency: autoContributionFrequency,
          )
        : await controller.createGoal(
            name: name,
            targetAmount: targetAmount,
            accountId: _accountId!,
            icon: _icon,
            color: _color,
            autoContributionAmount: autoContributionAmount,
            autoContributionFrequency: autoContributionFrequency,
          );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      context.pop();
    } else {
      final message =
          controller.failure?.message ?? l10n.saveGoalFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(savingsGoalControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final accounts = ref.watch(accountsProvider(false)).value ?? [];
    // Each account backs at most one *active* goal (see the plan's money
    // model) — excluded here so the picker only ever offers a valid choice,
    // on top of the authoritative check in the datasource.
    final activeGoals = ref.watch(savingsGoalsProvider(false)).value ?? [];
    final linkedAccountIds = {
      for (final goal in activeGoals)
        if (widget.existing == null || goal.id != widget.existing!.id)
          goal.accountId,
    };
    final eligibleAccounts = accounts
        .where((account) => !linkedAccountIds.contains(account.id))
        .toList();
    final linkedAccount = widget.existing == null
        ? null
        : accounts.where((a) => a.id == widget.existing!.accountId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.goalFormEditTitle : l10n.addGoalButton),
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
                    AppTextField(
                      label: l10n.goalNameLabel,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: AppSymbols.savings,
                      validator: (value) => Validators.requiredField(
                        context,
                        value,
                        label: l10n.goalNameLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.targetAmountLabel,
                      controller: _targetAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: AppSymbols.payments,
                      validator: (value) =>
                          Validators.positiveAmount(context, value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isEditing)
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            AppSymbols.accountBalanceWallet,
                          ),
                          title: Text(
                            linkedAccount?.name ??
                                l10n.unavailableAccountLabel,
                          ),
                          subtitle: Text(l10n.linkedAccountLockedMessage),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _accountId,
                        decoration: InputDecoration(
                          labelText: l10n.linkedAccountLabel,
                          prefixIcon: const Icon(
                            AppSymbols.accountBalanceWallet,
                          ),
                        ),
                        items: _withOrphanFallback(
                          items: [
                            for (final account in eligibleAccounts)
                              DropdownMenuItem(
                                value: account.id,
                                child: Text(account.name),
                              ),
                            DropdownMenuItem(
                              value: _createNewAccountSentinel,
                              child: Text(l10n.createNewAccountOption),
                            ),
                          ],
                          knownIds: {
                            ...eligibleAccounts.map((account) => account.id),
                            _createNewAccountSentinel,
                          },
                          currentValue: _accountId,
                          missingLabel: l10n.unavailableAccountLabel,
                        ),
                        onChanged: (value) {
                          if (value == _createNewAccountSentinel) {
                            context.push(AppRoutes.accountNew);
                            return;
                          }
                          setState(() => _accountId = value);
                        },
                        validator: (value) =>
                            value == null || value == _createNewAccountSentinel
                            ? l10n.pleaseSelectAccountError
                            : null,
                      ),
                      if (eligibleAccounts.isEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.noEligibleAccountsMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.autoContributionSectionTitle),
                      subtitle: Text(l10n.autoContributionToggleLabel),
                      value: _autoContributionEnabled,
                      onChanged: (value) =>
                          setState(() => _autoContributionEnabled = value),
                    ),
                    if (_autoContributionEnabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: l10n.autoContributionAmountLabel,
                        controller: _autoContributionAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: AppSymbols.payments,
                        validator: (value) =>
                            Validators.positiveAmount(context, value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.autoContributionFrequencyLabel,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<GoalContributionFrequency>(
                        segments: [
                          for (final frequency
                              in GoalContributionFrequency.values)
                            ButtonSegment(
                              value: frequency,
                              label: Text(frequency.localizedLabel(l10n)),
                            ),
                        ],
                        selected: {_frequency},
                        onSelectionChanged: (selection) =>
                            setState(() => _frequency = selection.first),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _isEditing
                          ? l10n.saveChangesButton
                          : l10n.addGoalButton,
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
