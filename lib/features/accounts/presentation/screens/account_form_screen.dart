import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/color_picker_field.dart';
import '../../../../core/widgets/icon_picker_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';
import '../providers/account_controller.dart';
import '../utils/account_type_label.dart';

/// Shared Add/Edit form. Pass [existing] when editing so the fields are
/// pre-filled and the submit action updates instead of creates.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.existing});

  final AccountEntity? existing;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _type;
  late AppCurrency _currency;
  late AppIconKey _icon;
  late AppColorKey _color;

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
    _nameController = TextEditingController(text: existing?.name ?? '');
    _balanceController = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(2) : '',
    );
    _type = existing?.type ?? AccountType.cash;
    _currency = existing != null
        ? SupportedCurrencies.byCode(existing.currencyCode)
        : _defaultCurrency;
    _icon = existing?.icon ?? _type.defaultIcon;
    _color = existing?.color ?? AppColorKey.emerald;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onTypeChanged(AccountType type) {
    setState(() {
      // Only auto-swap the icon if the user hasn't customized it away
      // from the previous type's default.
      if (_icon == _type.defaultIcon) {
        _icon = type.defaultIcon;
      }
      _type = type;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final balance = double.parse(_balanceController.text.trim());
    final controller = ref.read(accountControllerProvider.notifier);

    final success = _isEditing
        ? await controller.updateAccount(
            id: widget.existing!.id,
            name: name,
            type: _type,
            balance: balance,
            icon: _icon,
            color: _color,
          )
        : await controller.createAccount(
            name: name,
            type: _type,
            initialBalance: balance,
            currencyCode: _currency.code,
            icon: _icon,
            color: _color,
          );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      context.pop();
    } else {
      final message =
          controller.failure?.message ?? l10n.saveAccountFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.accountFormEditTitle : l10n.addAccountButton,
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
                    AppTextField(
                      label: l10n.accountNameLabel,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: AppSymbols.badge,
                      validator: (value) => Validators.requiredField(
                        context,
                        value,
                        label: l10n.accountNameLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.accountTypeLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final type in AccountType.values)
                          ChoiceChip(
                            label: Text(type.localizedLabel(l10n)),
                            avatar: Icon(type.defaultIcon.icon, size: 18),
                            selected: _type == type,
                            onSelected: (_) => _onTypeChanged(type),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            label: _isEditing
                                ? l10n.currentBalanceLabel
                                : l10n.initialBalanceLabel,
                            controller: _balanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            prefixIcon: AppSymbols.accountBalanceWallet,
                            validator: (value) =>
                                Validators.amount(context, value),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: _isEditing
                              ? InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.currencyLabel,
                                    enabled: false,
                                  ),
                                  child: Text(_currency.code),
                                )
                              : DropdownButtonFormField<AppCurrency>(
                                  initialValue: _currency,
                                  decoration: InputDecoration(
                                    labelText: l10n.currencyLabel,
                                  ),
                                  items: [
                                    for (final currency
                                        in SupportedCurrencies.all)
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
                    if (_isEditing) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.accountCurrencyLockedHelper,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                    PrimaryButton(
                      label: _isEditing
                          ? l10n.saveChangesButton
                          : l10n.addAccountButton,
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
