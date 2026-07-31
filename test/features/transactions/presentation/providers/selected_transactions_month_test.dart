import 'package:cashly_lao/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for [SelectedTransactionsMonth]'s year-boundary
/// handling — this notifier drives which month's transactions this app's
/// core screen shows, so a rollover bug here would be a real, high-impact
/// correctness issue.
void main() {
  test('previousMonth from January rolls back to December of the '
      'previous year', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(selectedTransactionsMonthProvider.notifier).state = DateTime(
      2026,
      1,
    );
    container.read(selectedTransactionsMonthProvider.notifier).previousMonth();

    expect(
      container.read(selectedTransactionsMonthProvider),
      DateTime(2025, 12),
    );
  });

  test('nextMonth from December rolls forward to January of the next year', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(selectedTransactionsMonthProvider.notifier).state = DateTime(
      2026,
      12,
    );
    container.read(selectedTransactionsMonthProvider.notifier).nextMonth();

    expect(
      container.read(selectedTransactionsMonthProvider),
      DateTime(2027, 1),
    );
  });
}
