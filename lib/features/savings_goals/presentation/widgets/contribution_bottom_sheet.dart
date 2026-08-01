import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../providers/savings_goal_controller.dart';

/// Opened via `AppBottomSheet.show` from the goal Detail screen's contribute
/// button (or a due-reminder banner, with [prefillAmount] set from the
/// goal's auto-contribution schedule). Making a contribution is just an
/// ordinary transfer into the goal's linked account — see
/// `ContributeToGoalUseCase` — so this only needs to collect which other
/// account the money comes from, and how much.
class ContributionBottomSheet extends ConsumerStatefulWidget {
  const ContributionBottomSheet({
    required this.goal,
    required this.currency,
    super.key,
    this.prefillAmount,
  });

  final SavingsGoalEntity goal;
  final AppCurrency currency;
  final double? prefillAmount;

  @override
  ConsumerState<ContributionBottomSheet> createState() =>
      _ContributionBottomSheetState();
}

class _ContributionBottomSheetState
    extends ConsumerState<ContributionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _sourceAccountId;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillAmount;
    _amountController = TextEditingController(
      text: prefill == null
          ? ''
          : prefill.toStringAsFixed(widget.currency.decimalDigits),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final sourceAccountId = _sourceAccountId!;
    final amount = double.parse(_amountController.text.trim());
    final controller = ref.read(savingsGoalControllerProvider.notifier);

    final success = await controller.contribute(
      goal: widget.goal,
      sourceAccountId: sourceAccountId,
      amount: amount,
    );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final message =
          controller.failure?.message ?? l10n.contributionFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLoading = ref.watch(savingsGoalControllerProvider).isLoading;
    final accounts = ref.watch(accountsProvider(false)).value ?? [];
    final eligibleAccounts = accounts
        .where(
          (account) =>
              account.id != widget.goal.accountId &&
              account.currencyCode == widget.currency.code,
        )
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.contributeButton, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _sourceAccountId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.contributionSourceAccountLabel,
              prefixIcon: const Icon(AppSymbols.accountBalanceWallet),
            ),
            items: [
              for (final account in eligibleAccounts)
                DropdownMenuItem(value: account.id, child: Text(account.name)),
            ],
            validator: (value) =>
                value == null ? l10n.pleaseSelectAccountError : null,
            onChanged: (value) => setState(() => _sourceAccountId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: l10n.contributionAmountLabel,
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: AppSymbols.payments,
            validator: (value) => Validators.positiveAmount(context, value),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.confirmContributionButton,
            isLoading: isLoading,
            onPressed: eligibleAccounts.isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
