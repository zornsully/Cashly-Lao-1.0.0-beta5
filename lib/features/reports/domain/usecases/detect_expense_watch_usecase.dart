import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../entities/expense_watch_item.dart';

/// Detects spending patterns worth a user's attention, entirely on-device
/// from transactions already streamed to the client — no cloud service, no
/// machine learning, three deterministic heuristics:
///
/// - **Large**: a single expense well above what its category has recently
///   cost, on average.
/// - **Repeated**: two or more same-amount expenses in the same category
///   and account within a few days of each other — a common signature of
///   an accidental duplicate charge.
/// - **Rising**: a category whose total spend this period is well above
///   its own trailing average.
///
/// Every threshold below is a deliberate, fixed constant rather than a
/// user setting or a learned parameter — this keeps detection predictable
/// and testable. Revisit as a Settings-configurable value only if real
/// usage shows the fixed thresholds are wrong for typical spending
/// patterns.
class DetectExpenseWatchUseCase {
  const DetectExpenseWatchUseCase();

  /// A transaction is "large" once it exceeds this multiple of its
  /// category's trailing average amount.
  static const double _largeAmountMultiplier = 2.0;

  /// A category is "rising" once its current-period total exceeds this
  /// multiple of its trailing average.
  static const double _risingCategoryMultiplier = 1.5;

  /// The "large" heuristic needs at least this many trailing samples in a
  /// category before trusting its average — otherwise a category's very
  /// first-ever transaction would always look "unusually large" against
  /// an average of one.
  static const int _minTrailingSamplesForLarge = 2;

  /// How close together two same-amount transactions must be to count as
  /// "repeated" rather than an unrelated coincidence.
  static const Duration _repeatedWindow = Duration(days: 3);

  /// Two amounts within this absolute difference count as "the same" —
  /// tolerant of negligible floating-point drift, not a percentage
  /// tolerance (transaction amounts are user-entered fixed decimals).
  static const double _sameAmountEpsilon = 0.005;

  /// [trailingTransactions] is the window immediately before the current
  /// period (never overlapping it) used as the "normal" baseline for both
  /// the Large and Rising heuristics. [trailingPeriodCount] is how many
  /// equivalent periods that window spans (e.g. 3 for a trailing 3-month
  /// window behind a 1-month current period) — the caller controls this
  /// explicitly so the average is always "per period," not skewed by an
  /// arbitrarily long or short trailing fetch.
  List<ExpenseWatchItem> call({
    required List<TransactionEntity> currentPeriodTransactions,
    required List<TransactionEntity> trailingTransactions,
    required int trailingPeriodCount,
    required List<AccountEntity> accounts,
    required List<CategoryEntity> categories,
  }) {
    final accountsById = {for (final account in accounts) account.id: account};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    final currentExpenses = currentPeriodTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final trailingExpenses = trailingTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final items = <ExpenseWatchItem>[
      ..._detectLarge(
        currentExpenses,
        trailingExpenses,
        accountsById,
        categoriesById,
      ),
      ..._detectRepeated(currentExpenses, categoriesById),
      ..._detectRising(
        currentExpenses,
        trailingExpenses,
        trailingPeriodCount,
        accountsById,
        categoriesById,
      ),
    ];
    return items;
  }

  String _categoryCurrencyKey(String categoryId, String currencyCode) =>
      '$categoryId|$currencyCode';

  List<LargeExpenseWatchItem> _detectLarge(
    List<TransactionEntity> currentExpenses,
    List<TransactionEntity> trailingExpenses,
    Map<String, AccountEntity> accountsById,
    Map<String, CategoryEntity> categoriesById,
  ) {
    final trailingAmountsByKey = <String, List<double>>{};
    for (final transaction in trailingExpenses) {
      final account = accountsById[transaction.accountId];
      if (account == null || transaction.categoryId == null) continue;
      final key = _categoryCurrencyKey(
        transaction.categoryId!,
        account.currencyCode,
      );
      trailingAmountsByKey.putIfAbsent(key, () => []).add(transaction.amount);
    }

    final items = <LargeExpenseWatchItem>[];
    for (final transaction in currentExpenses) {
      final account = accountsById[transaction.accountId];
      final category = transaction.categoryId == null
          ? null
          : categoriesById[transaction.categoryId];
      if (account == null || category == null) continue;

      final key = _categoryCurrencyKey(category.id, account.currencyCode);
      final trailingAmounts = trailingAmountsByKey[key] ?? const [];
      if (trailingAmounts.length < _minTrailingSamplesForLarge) continue;

      final average =
          trailingAmounts.reduce((a, b) => a + b) / trailingAmounts.length;
      if (average > 0 &&
          transaction.amount > average * _largeAmountMultiplier) {
        items.add(
          LargeExpenseWatchItem(
            transaction: transaction,
            category: category,
            categoryAverageAmount: average,
          ),
        );
      }
    }
    return items;
  }

  List<RepeatedExpenseWatchItem> _detectRepeated(
    List<TransactionEntity> currentExpenses,
    Map<String, CategoryEntity> categoriesById,
  ) {
    final byGroup = <String, List<TransactionEntity>>{};
    for (final transaction in currentExpenses) {
      if (transaction.categoryId == null) continue;
      final key = '${transaction.categoryId}|${transaction.accountId}';
      byGroup.putIfAbsent(key, () => []).add(transaction);
    }

    final items = <RepeatedExpenseWatchItem>[];
    for (final group in byGroup.values) {
      final sorted = [...group]..sort((a, b) => a.date.compareTo(b.date));
      final claimed = <String>{};

      for (var i = 0; i < sorted.length; i++) {
        if (claimed.contains(sorted[i].id)) continue;
        final cluster = [sorted[i]];

        for (var j = i + 1; j < sorted.length; j++) {
          if (claimed.contains(sorted[j].id)) continue;
          final sameAmount =
              (sorted[j].amount - sorted[i].amount).abs() < _sameAmountEpsilon;
          final withinWindow =
              sorted[j].date.difference(sorted[i].date) <= _repeatedWindow;
          if (sameAmount && withinWindow) cluster.add(sorted[j]);
        }

        if (cluster.length >= 2) {
          for (final transaction in cluster) {
            claimed.add(transaction.id);
          }
          final category = categoriesById[cluster.first.categoryId];
          if (category != null) {
            items.add(
              RepeatedExpenseWatchItem(
                transactions: cluster,
                category: category,
                amount: cluster.first.amount,
              ),
            );
          }
        }
      }
    }
    return items;
  }

  List<RisingCategoryWatchItem> _detectRising(
    List<TransactionEntity> currentExpenses,
    List<TransactionEntity> trailingExpenses,
    int trailingPeriodCount,
    Map<String, AccountEntity> accountsById,
    Map<String, CategoryEntity> categoriesById,
  ) {
    if (trailingPeriodCount <= 0) return const [];

    final currentTotalsByKey = <String, double>{};
    for (final transaction in currentExpenses) {
      final account = accountsById[transaction.accountId];
      if (account == null || transaction.categoryId == null) continue;
      final key = _categoryCurrencyKey(
        transaction.categoryId!,
        account.currencyCode,
      );
      currentTotalsByKey.update(
        key,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final trailingTotalsByKey = <String, double>{};
    for (final transaction in trailingExpenses) {
      final account = accountsById[transaction.accountId];
      if (account == null || transaction.categoryId == null) continue;
      final key = _categoryCurrencyKey(
        transaction.categoryId!,
        account.currencyCode,
      );
      trailingTotalsByKey.update(
        key,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final items = <RisingCategoryWatchItem>[];
    for (final entry in currentTotalsByKey.entries) {
      final trailingTotal = trailingTotalsByKey[entry.key] ?? 0;
      final trailingAverage = trailingTotal / trailingPeriodCount;
      if (trailingAverage <= 0) continue;
      if (entry.value <= trailingAverage * _risingCategoryMultiplier) continue;

      final separatorIndex = entry.key.indexOf('|');
      final categoryId = entry.key.substring(0, separatorIndex);
      final currencyCode = entry.key.substring(separatorIndex + 1);
      final category = categoriesById[categoryId];
      if (category == null) continue;

      items.add(
        RisingCategoryWatchItem(
          category: category,
          currencyCode: currencyCode,
          currentAmount: entry.value,
          averageAmount: trailingAverage,
          percentIncrease:
              ((entry.value - trailingAverage) / trailingAverage) * 100,
        ),
      );
    }
    return items;
  }
}
