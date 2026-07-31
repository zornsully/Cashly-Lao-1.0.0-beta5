import 'package:cashly_lao/features/budget/presentation/providers/budget_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for [SelectedBudgetMonth]'s year-boundary handling —
/// same shape as Transactions'/Reports' own month notifier, tested
/// separately since each is its own independent state.
void main() {
  test('previousMonth from January rolls back to December of the '
      'previous year', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(selectedBudgetMonthProvider.notifier).state = DateTime(
      2026,
      1,
    );
    container.read(selectedBudgetMonthProvider.notifier).previousMonth();

    expect(container.read(selectedBudgetMonthProvider), DateTime(2025, 12));
  });

  test('nextMonth from December rolls forward to January of the next year', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(selectedBudgetMonthProvider.notifier).state = DateTime(
      2026,
      12,
    );
    container.read(selectedBudgetMonthProvider.notifier).nextMonth();

    expect(container.read(selectedBudgetMonthProvider), DateTime(2027, 1));
  });
}
