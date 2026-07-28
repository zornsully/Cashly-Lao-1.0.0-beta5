import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight.dart';
import 'package:cashly_lao/features/financial_insights/domain/entities/smart_money_score.dart';
import 'package:cashly_lao/features/financial_insights/domain/usecases/derive_smart_money_score_opening_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = DeriveSmartMoneyScoreOpeningUseCase();

  FinancialInsightSnapshot snapshot({
    double balance = 900,
    double income = 200,
    double expense = 300,
    int accountCount = 1,
    bool hasCrossCurrencyTransfer = false,
    bool hasAccountCreatedThisMonth = false,
  }) {
    FinancialSpendingWindow window(FinancialWindowKind kind) =>
        FinancialSpendingWindow(
          kind: kind,
          income: kind == FinancialWindowKind.month ? income : 0,
          expense: kind == FinancialWindowKind.month ? expense : 0,
          previousExpense: 0,
          transactionCount: 1,
        );
    return FinancialInsightSnapshot(
      generatedAt: DateTime(2026, 7, 20),
      currencyCode: 'LAK',
      today: window(FinancialWindowKind.today),
      week: window(FinancialWindowKind.week),
      month: window(FinancialWindowKind.month),
      categoryTrends: const [],
      budgets: const [],
      balance: FinancialBalancePosition(
        totalBalance: balance,
        activeAccountCount: accountCount,
        hasCrossCurrencyTransfer: hasCrossCurrencyTransfer,
        hasAccountCreatedThisMonth: hasAccountCreatedThisMonth,
      ),
    );
  }

  test('reconstructs the opening balance from recorded month cash flow', () {
    final opening = useCase(snapshot());

    // 900 current - (200 income - 300 expense) = 1,000 at month start.
    expect(opening.openingBalance, 1000);
    expect(opening.monthStart, DateTime(2026, 7));
    expect(opening.baselineState, SmartMoneyScoreBaselineState.reliable);
  });

  test('does not guess a baseline around a cross-currency transfer', () {
    final opening = useCase(snapshot(hasCrossCurrencyTransfer: true));

    expect(
      opening.baselineState,
      SmartMoneyScoreBaselineState.unsafeCurrencyMovement,
    );
    expect(opening.baselineNote, contains('exchange-rate'));
  });

  test('does not guess an opening when an account was added mid-month', () {
    final opening = useCase(snapshot(hasAccountCreatedThisMonth: true));

    expect(
      opening.baselineState,
      SmartMoneyScoreBaselineState.insufficientData,
    );
    expect(opening.baselineNote, contains('added after this month began'));
  });

  test('does not create an opening without an active account', () {
    final opening = useCase(snapshot(accountCount: 0));

    expect(
      opening.baselineState,
      SmartMoneyScoreBaselineState.insufficientData,
    );
  });
}
