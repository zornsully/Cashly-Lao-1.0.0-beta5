import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/entities/category_type.dart'
    show CategoryType;
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_controller.dart';

/// Shared Add/Edit form. Pass [existing] when editing so the fields are
/// pre-filled and the submit action updates instead of creates (correctly
/// reconciling account balances either way — see
/// [TransactionRemoteDataSource]).
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.existing, this.initialType});

  final TransactionEntity? existing;

  /// Lets a contextual entry point (for example the desktop dashboard's
  /// "Add income" action) open the existing form with the matching type.
  /// An existing transaction always wins so edit flows cannot be changed by
  /// a stale route extra.
  final TransactionType? initialType;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late DateTime _date;
  String? _accountId;
  String? _categoryId;
  String? _toAccountId;

  bool get _isEditing => widget.existing != null;
  bool get _isTransfer => _type == TransactionType.transfer;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? widget.initialType ?? TransactionType.expense;
    _date = existing?.date ?? DateTime.now();
    _accountId = existing?.accountId;
    _categoryId = existing?.categoryId;
    _toAccountId = existing?.toAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _categoryId = null;
      if (type != TransactionType.transfer) _toAccountId = null;
    });
  }

  void _onAccountChanged(String? value) {
    setState(() {
      _accountId = value;
      if (_toAccountId == null) return;

      // A transfer can't target the same account it moves money out of,
      // or an account in a different currency (Cashly never mixes
      // currencies — see CLAUDE.md) — clear an invalid destination
      // rather than leave it silently selected against the new source.
      final accounts = ref.read(accountsProvider(true)).value ?? [];
      final newSource = accounts.where((a) => a.id == value).firstOrNull;
      final currentDestination = accounts
          .where((a) => a.id == _toAccountId)
          .firstOrNull;
      final stillValid =
          newSource != null &&
          currentDestination != null &&
          _toAccountId != value &&
          currentDestination.currencyCode == newSource.currencyCode;
      if (!stillValid) _toAccountId = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();
    final controller = ref.read(transactionControllerProvider.notifier);
    final categoryId = _isTransfer ? null : _categoryId;
    final toAccountId = _isTransfer ? _toAccountId : null;

    final success = _isEditing
        ? await controller.updateTransaction(
            id: widget.existing!.id,
            accountId: _accountId!,
            categoryId: categoryId,
            type: _type,
            toAccountId: toAccountId,
            amount: amount,
            date: _date,
            note: note,
          )
        : await controller.createTransaction(
            accountId: _accountId!,
            categoryId: categoryId,
            type: _type,
            toAccountId: toAccountId,
            amount: amount,
            date: _date,
            note: note,
          );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      context.pop();
    } else {
      final message =
          controller.failure?.message ?? l10n.saveTransactionFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  String _accountLabel(AppLocalizations l10n, AccountEntity account) =>
      account.isArchived
      ? l10n.archivedSuffixFormat(account.name)
      : account.name;

  String _categoryLabel(AppLocalizations l10n, CategoryEntity category) =>
      category.isArchived
      ? l10n.archivedSuffixFormat(category.name)
      : category.name;

  /// [DropdownButtonFormField] asserts that its current value matches one
  /// of [items] exactly. If this transaction's account/category was since
  /// deleted (possible if it was removed elsewhere while still referenced
  /// here), the id in [currentValue] won't be in [knownIds] — inject a
  /// disabled placeholder so the form still renders instead of crashing,
  /// and the user is prompted to pick a replacement before saving.
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

  /// [CategoryEntity] is tagged with its own [CategoryType], distinct from
  /// (but conceptually identical to) [TransactionType] — this maps between
  /// them so the category dropdown only offers categories matching the
  /// transaction's current type. Null for a transfer, which has no
  /// category at all.
  CategoryType? get _categoryType => switch (_type) {
    TransactionType.income => CategoryType.income,
    TransactionType.expense => CategoryType.expense,
    TransactionType.transfer => null,
  };

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionControllerProvider).isLoading;
    final accounts = ref.watch(accountsProvider(true)).value ?? [];
    final categories =
        ref
            .watch(
              categoriesProvider((type: _categoryType, includeArchived: true)),
            )
            .value ??
        [];
    final fromAccount = accounts.where((a) => a.id == _accountId).firstOrNull;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.transactionFormEditTitle
              : l10n.addTransactionButton,
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
                    SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text(l10n.expenseLabel),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text(l10n.incomeLabel),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: TransactionType.transfer,
                          label: Text(l10n.transferLabel),
                          icon: const Icon(AppSymbols.currencyExchange),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (selection) =>
                          _onTypeChanged(selection.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.amountLabel,
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: AppSymbols.payments,
                      validator: (value) =>
                          Validators.positiveAmount(context, value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _accountId,
                      decoration: InputDecoration(
                        labelText: _isTransfer
                            ? l10n.fromAccountLabel
                            : l10n.accountFieldLabel,
                        prefixIcon: const Icon(AppSymbols.accountBalanceWallet),
                      ),
                      items: _withOrphanFallback(
                        items: [
                          for (final account in accounts)
                            DropdownMenuItem(
                              value: account.id,
                              child: Text(_accountLabel(l10n, account)),
                            ),
                        ],
                        knownIds: accounts.map((a) => a.id).toSet(),
                        currentValue: _accountId,
                        missingLabel: l10n.unavailableAccountLabel,
                      ),
                      validator: (value) =>
                          value == null ? l10n.pleaseSelectAccountError : null,
                      onChanged: _onAccountChanged,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_isTransfer)
                      DropdownButtonFormField<String>(
                        initialValue: _toAccountId,
                        decoration: InputDecoration(
                          labelText: l10n.toAccountLabel,
                          prefixIcon: const Icon(
                            AppSymbols.accountBalanceWallet,
                          ),
                          // Cashly never mixes currencies (see CLAUDE.md) —
                          // moving "30" out of a USD account has to land as
                          // 30 USD somewhere, not 30 of whatever currency a
                          // different account happens to use.
                          helperText: fromAccount == null
                              ? l10n.pickFromAccountFirstMessage
                              : l10n.transferSameCurrencyHelperText,
                        ),
                        items: _withOrphanFallback(
                          items: [
                            for (final account in accounts)
                              if (account.id != _accountId &&
                                  (fromAccount == null ||
                                      account.currencyCode ==
                                          fromAccount.currencyCode))
                                DropdownMenuItem(
                                  value: account.id,
                                  child: Text(_accountLabel(l10n, account)),
                                ),
                          ],
                          knownIds: accounts
                              .where(
                                (a) =>
                                    a.id != _accountId &&
                                    (fromAccount == null ||
                                        a.currencyCode ==
                                            fromAccount.currencyCode),
                              )
                              .map((a) => a.id)
                              .toSet(),
                          currentValue: _toAccountId,
                          missingLabel: l10n.unavailableAccountLabel,
                        ),
                        validator: (value) {
                          if (value == null) {
                            return l10n.pleaseSelectDestinationAccountError;
                          }
                          if (value == _accountId) {
                            return l10n.cantTransferToSameAccountError;
                          }
                          final destination = accounts
                              .where((a) => a.id == value)
                              .firstOrNull;
                          if (fromAccount != null &&
                              destination != null &&
                              destination.currencyCode !=
                                  fromAccount.currencyCode) {
                            return l10n.transferSameCurrencyError;
                          }
                          return null;
                        },
                        onChanged: (value) =>
                            setState(() => _toAccountId = value),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: InputDecoration(
                          labelText: l10n.categoryFieldLabel,
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: _withOrphanFallback(
                          items: [
                            for (final category in categories)
                              DropdownMenuItem(
                                value: category.id,
                                child: Text(_categoryLabel(l10n, category)),
                              ),
                          ],
                          knownIds: categories.map((c) => c.id).toSet(),
                          currentValue: _categoryId,
                          missingLabel: l10n.unavailableCategoryLabel,
                        ),
                        validator: (value) => value == null
                            ? l10n.pleaseSelectCategoryError
                            : null,
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.dateLabel,
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DateFormat.yMMMd().format(_date)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.noteOptionalLabel,
                      controller: _noteController,
                      prefixIcon: Icons.notes_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _isEditing
                          ? l10n.saveChangesButton
                          : l10n.addTransactionButton,
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
