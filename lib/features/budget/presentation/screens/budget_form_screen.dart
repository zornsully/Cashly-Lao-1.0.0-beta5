import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_controller.dart';

/// Passed as `extra` to [AppRoutes.budgetNew] — a budget is always created
/// for a specific category and month, chosen by tapping "Set budget" on
/// that category's row in [BudgetsListScreen].
typedef NewBudgetArgs = ({CategoryEntity category, DateTime month});

/// Shared Create/Edit form. A budget's category and month are fixed once
/// created (see [BudgetRepository.updateBudget]) — only the limit and
/// currency can change, so this form only ever collects those two fields.
class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.existing, this.newBudgetArgs});

  final BudgetEntity? existing;
  final NewBudgetArgs? newBudgetArgs;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  late AppCurrency _currency;

  bool get _isEditing => widget.existing != null;

  /// The Settings-chosen default currency, if preferences have already
  /// loaded by the time this form opens; otherwise the app's own fallback.
  AppCurrency get _defaultCurrency {
    final code = ref.read(userPreferencesProvider).value?.defaultCurrencyCode;
    return code != null
        ? SupportedCurrencies.byCode(code)
        : SupportedCurrencies.fallback;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _limitController = TextEditingController(
      text: existing != null ? existing.limitAmount.toStringAsFixed(2) : '',
    );
    _currency = existing != null
        ? SupportedCurrencies.byCode(existing.currencyCode)
        : _defaultCurrency;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final limitAmount = double.parse(_limitController.text.trim());
    final controller = ref.read(budgetControllerProvider.notifier);

    final success = _isEditing
        ? await controller.updateBudget(
            id: widget.existing!.id,
            limitAmount: limitAmount,
            currencyCode: _currency.code,
          )
        : await controller.createBudget(
            categoryId: widget.newBudgetArgs!.category.id,
            month: widget.newBudgetArgs!.month,
            limitAmount: limitAmount,
            currencyCode: _currency.code,
          );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      context.pop();
    } else {
      final message =
          controller.failure?.message ?? l10n.saveBudgetFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(budgetControllerProvider).isLoading;
    final category = widget.newBudgetArgs?.category;
    final month = widget.existing?.month ?? widget.newBudgetArgs!.month;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.budgetFormEditTitle : l10n.setBudgetButton,
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
                    if (category != null)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            category.icon.icon,
                            color: category.color.color,
                          ),
                          title: Text(category.name),
                          subtitle: Text(DateFormat.yMMMM().format(month)),
                        ),
                      )
                    else
                      Card(
                        child: ListTile(
                          leading: const Icon(AppSymbols.calendarToday),
                          title: Text(DateFormat.yMMMM().format(month)),
                          subtitle: Text(l10n.categoryAndMonthLockedMessage),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            label: l10n.monthlyLimitLabel,
                            controller: _limitController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: AppSymbols.savings,
                            validator: (value) =>
                                Validators.positiveAmount(context, value),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<AppCurrency>(
                            initialValue: _currency,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.currencyLabel,
                            ),
                            items: [
                              for (final currency in SupportedCurrencies.all)
                                DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency.code),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _currency = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.budgetCurrencyRestrictionMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _isEditing
                          ? l10n.saveChangesButton
                          : l10n.setBudgetButton,
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
