import '../../../accounts/domain/entities/account_entity.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/financial_insight.dart';

/// Converts application records into compact, currency-safe snapshots for an
/// insight engine. The engine never needs direct access to transaction notes
/// or account names.
class BuildFinancialInsightSnapshotsUseCase {
  const BuildFinancialInsightSnapshotsUseCase();

  List<FinancialInsightSnapshot> call({
    required DateTime asOf,
    required List<TransactionEntity> transactions,
    required List<AccountEntity> accounts,
    required List<CategoryEntity> categories,
    required List<BudgetEntity> budgets,
  }) {
    final accountCurrency = {
      for (final account in accounts) account.id: account.currencyCode,
    };
    // Archived accounts stay available for historical transaction analysis,
    // but only active accounts make up the current balance buffer.
    final activeBalanceByCurrency = <String, double>{};
    final activeAccountCountByCurrency = <String, int>{};
    final hasAccountCreatedThisMonthByCurrency = <String, bool>{};
    final hasAccountCreatedTodayByCurrency = <String, bool>{};
    final hasAccountCreatedThisWeekByCurrency = <String, bool>{};
    final currentMonth = DateTime(asOf.year, asOf.month);
    final todayStart = DateTime(asOf.year, asOf.month, asOf.day);
    final weekStart = todayStart.subtract(Duration(days: asOf.weekday - 1));
    final scoreWindowEnd = DateTime(asOf.year, asOf.month, asOf.day + 1);
    for (final account in accounts.where((account) => !account.isArchived)) {
      activeBalanceByCurrency.update(
        account.currencyCode,
        (balance) => balance + account.balance,
        ifAbsent: () => account.balance,
      );
      activeAccountCountByCurrency.update(
        account.currencyCode,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (account.createdAt.isAfter(currentMonth) &&
          account.createdAt.isBefore(scoreWindowEnd)) {
        hasAccountCreatedThisMonthByCurrency[account.currencyCode] = true;
      }
      if (account.createdAt.isAfter(todayStart) &&
          account.createdAt.isBefore(scoreWindowEnd)) {
        hasAccountCreatedTodayByCurrency[account.currencyCode] = true;
      }
      if (account.createdAt.isAfter(weekStart) &&
          account.createdAt.isBefore(scoreWindowEnd)) {
        hasAccountCreatedThisWeekByCurrency[account.currencyCode] = true;
      }
    }
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    // A transfer that crosses currencies has no exchange-rate field in the
    // transaction schema. Mark the affected currency snapshots so the Smart
    // Money Score lifecycle can keep a neutral result instead of inventing a
    // balance change from incompatible amounts.
    final hasCrossCurrencyTransferByCurrency = <String, bool>{};
    final hasCrossCurrencyTransferTodayByCurrency = <String, bool>{};
    final hasCrossCurrencyTransferThisWeekByCurrency = <String, bool>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.transfer ||
          transaction.toAccountId == null ||
          !transaction.date.isBefore(scoreWindowEnd)) {
        continue;
      }
      final sourceCurrency = accountCurrency[transaction.accountId];
      final destinationCurrency = accountCurrency[transaction.toAccountId!];
      if (sourceCurrency == null ||
          destinationCurrency == null ||
          sourceCurrency == destinationCurrency) {
        continue;
      }
      void markAffectedCurrencies(Map<String, bool> values) {
        values[sourceCurrency] = true;
        values[destinationCurrency] = true;
      }

      if (!transaction.date.isBefore(currentMonth)) {
        markAffectedCurrencies(hasCrossCurrencyTransferByCurrency);
      }
      if (!transaction.date.isBefore(todayStart)) {
        markAffectedCurrencies(hasCrossCurrencyTransferTodayByCurrency);
      }
      if (!transaction.date.isBefore(weekStart)) {
        markAffectedCurrencies(hasCrossCurrencyTransferThisWeekByCurrency);
      }
    }
    final currencies = <String>{
      ...accountCurrency.values,
      ...budgets
          .where((budget) => _isSameMonth(budget.month, currentMonth))
          .map((budget) => budget.currencyCode),
    }.toList()..sort();

    return [
      for (final currency in currencies)
        _snapshotForCurrency(
          asOf: asOf,
          currencyCode: currency,
          transactions: transactions
              .where(
                (transaction) =>
                    accountCurrency[transaction.accountId] == currency,
              )
              .toList(),
          categoryNames: categoryNames,
          balance: FinancialBalancePosition(
            totalBalance: activeBalanceByCurrency[currency] ?? 0,
            activeAccountCount: activeAccountCountByCurrency[currency] ?? 0,
            hasCrossCurrencyTransfer:
                hasCrossCurrencyTransferByCurrency[currency] ?? false,
            hasAccountCreatedThisMonth:
                hasAccountCreatedThisMonthByCurrency[currency] ?? false,
            hasCrossCurrencyTransferToday:
                hasCrossCurrencyTransferTodayByCurrency[currency] ?? false,
            hasCrossCurrencyTransferThisWeek:
                hasCrossCurrencyTransferThisWeekByCurrency[currency] ?? false,
            hasAccountCreatedToday:
                hasAccountCreatedTodayByCurrency[currency] ?? false,
            hasAccountCreatedThisWeek:
                hasAccountCreatedThisWeekByCurrency[currency] ?? false,
          ),
          budgets: budgets
              .where(
                (budget) =>
                    budget.currencyCode == currency &&
                    _isSameMonth(budget.month, currentMonth),
              )
              .toList(),
        ),
    ];
  }

  FinancialInsightSnapshot _snapshotForCurrency({
    required DateTime asOf,
    required String currencyCode,
    required List<TransactionEntity> transactions,
    required Map<String, String> categoryNames,
    required FinancialBalancePosition balance,
    required List<BudgetEntity> budgets,
  }) {
    final todayStart = _dateOnly(asOf);
    final tomorrow = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );
    final monthStart = DateTime(asOf.year, asOf.month);
    final previousMonthStart = DateTime(asOf.year, asOf.month - 1);
    final monthToDateDays = tomorrow.difference(monthStart).inDays;
    final previousMonthEnd = DateTime(asOf.year, asOf.month);
    final comparableMonthEnd = _minDate(
      previousMonthStart.add(Duration(days: monthToDateDays)),
      previousMonthEnd,
    );

    final today = _window(
      kind: FinancialWindowKind.today,
      transactions: transactions,
      start: todayStart,
      endExclusive: tomorrow,
      previousStart: todayStart.subtract(const Duration(days: 1)),
      previousEndExclusive: todayStart,
    );
    final week = _window(
      kind: FinancialWindowKind.week,
      transactions: transactions,
      start: weekStart,
      endExclusive: tomorrow,
      previousStart: weekStart.subtract(const Duration(days: 7)),
      previousEndExclusive: weekStart,
    );
    final month = _window(
      kind: FinancialWindowKind.month,
      transactions: transactions,
      start: monthStart,
      endExclusive: tomorrow,
      previousStart: previousMonthStart,
      previousEndExclusive: comparableMonthEnd,
    );
    final categoryTrends = _categoryTrends(
      transactions: transactions,
      categoryNames: categoryNames,
      currentStart: weekStart,
      currentEnd: tomorrow,
      previousStart: weekStart.subtract(const Duration(days: 7)),
      previousEnd: weekStart,
      monthStart: monthStart,
      monthEnd: tomorrow,
    );
    final monthExpensesByCategory = _expenseByCategory(
      transactions,
      monthStart,
      tomorrow,
    );

    return FinancialInsightSnapshot(
      generatedAt: asOf,
      currencyCode: currencyCode,
      today: today,
      week: week,
      month: month,
      categoryTrends: categoryTrends,
      budgets: [
        for (final budget in budgets)
          FinancialBudgetStatus(
            categoryId: budget.categoryId,
            categoryName: categoryNames[budget.categoryId] ?? 'Uncategorized',
            limit: budget.limitAmount,
            spent: monthExpensesByCategory[budget.categoryId] ?? 0,
          ),
      ],
      balance: balance,
    );
  }

  FinancialSpendingWindow _window({
    required FinancialWindowKind kind,
    required List<TransactionEntity> transactions,
    required DateTime start,
    required DateTime endExclusive,
    required DateTime previousStart,
    required DateTime previousEndExclusive,
  }) {
    final current = _inRange(transactions, start, endExclusive);
    final previous = _inRange(
      transactions,
      previousStart,
      previousEndExclusive,
    );
    return FinancialSpendingWindow(
      kind: kind,
      expense: _sum(current, TransactionType.expense),
      income: _sum(current, TransactionType.income),
      previousExpense: _sum(previous, TransactionType.expense),
      transactionCount: current.length,
    );
  }

  List<FinancialCategoryTrend> _categoryTrends({
    required List<TransactionEntity> transactions,
    required Map<String, String> categoryNames,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) {
    final current = _expenseByCategory(transactions, currentStart, currentEnd);
    final previous = _expenseByCategory(
      transactions,
      previousStart,
      previousEnd,
    );
    final month = _expenseByCategory(transactions, monthStart, monthEnd);
    final categoryIds = {...current.keys, ...previous.keys};
    final trends = [
      for (final id in categoryIds)
        FinancialCategoryTrend(
          categoryId: id,
          categoryName: categoryNames[id] ?? 'Uncategorized',
          currentExpense: current[id] ?? 0,
          previousExpense: previous[id] ?? 0,
          monthExpense: month[id] ?? 0,
        ),
    ]..sort((a, b) => b.currentExpense.compareTo(a.currentExpense));
    return trends;
  }

  Map<String, double> _expenseByCategory(
    List<TransactionEntity> transactions,
    DateTime start,
    DateTime endExclusive,
  ) {
    final values = <String, double>{};
    for (final transaction in _inRange(transactions, start, endExclusive)) {
      if (transaction.type != TransactionType.expense ||
          transaction.categoryId == null) {
        continue;
      }
      values.update(
        transaction.categoryId!,
        (amount) => amount + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return values;
  }

  List<TransactionEntity> _inRange(
    List<TransactionEntity> transactions,
    DateTime start,
    DateTime endExclusive,
  ) => transactions
      .where(
        (transaction) =>
            !transaction.date.isBefore(start) &&
            transaction.date.isBefore(endExclusive),
      )
      .toList();

  double _sum(List<TransactionEntity> transactions, TransactionType type) =>
      transactions
          .where((transaction) => transaction.type == type)
          .fold(0, (sum, transaction) => sum + transaction.amount);

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
