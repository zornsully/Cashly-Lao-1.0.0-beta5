import '../entities/financial_insight.dart';
import '../entities/smart_money_score.dart';

/// Reconstructs a calendar month's opening balance from the live aggregate.
///
/// The transaction datasource already applies income and expense deltas to
/// account balances atomically. Therefore, when the account set and currency
/// movement are safe, `current - (income - expense)` is the balance at the
/// start of the month even if the user first opens Cashly later in that month.
/// This avoids a late first sign-in silently resetting a monthly score.
class DeriveSmartMoneyScoreOpeningUseCase {
  const DeriveSmartMoneyScoreOpeningUseCase();

  SmartMoneyScoreOpening call(FinancialInsightSnapshot snapshot) {
    final monthStart = DateTime(
      snapshot.generatedAt.year,
      snapshot.generatedAt.month,
    );
    final balance = snapshot.balance;
    final month = snapshot.month;

    if (balance.activeAccountCount == 0) {
      return SmartMoneyScoreOpening(
        monthStart: monthStart,
        currencyCode: snapshot.currencyCode,
        openingBalance: balance.totalBalance,
        baselineState: SmartMoneyScoreBaselineState.insufficientData,
        baselineNote:
            'Cashly needs an active account before it can compare this month\'s balance.',
      );
    }
    if (balance.hasCrossCurrencyTransfer) {
      return SmartMoneyScoreOpening(
        monthStart: monthStart,
        currencyCode: snapshot.currencyCode,
        openingBalance: balance.totalBalance,
        baselineState: SmartMoneyScoreBaselineState.unsafeCurrencyMovement,
        baselineNote:
            'A transfer between currencies needs an exchange-rate record before this month can be compared safely.',
      );
    }
    if (balance.hasAccountCreatedThisMonth) {
      return SmartMoneyScoreOpening(
        monthStart: monthStart,
        currencyCode: snapshot.currencyCode,
        openingBalance: balance.totalBalance,
        baselineState: SmartMoneyScoreBaselineState.insufficientData,
        baselineNote:
            'An account was added after this month began, so Cashly cannot reconstruct a reliable opening balance yet.',
      );
    }
    if (!balance.totalBalance.isFinite ||
        !month.income.isFinite ||
        !month.expense.isFinite) {
      return SmartMoneyScoreOpening(
        monthStart: monthStart,
        currencyCode: snapshot.currencyCode,
        openingBalance: 0,
        baselineState: SmartMoneyScoreBaselineState.insufficientData,
        baselineNote:
            'Cashly could not verify the values needed for this month\'s opening balance.',
      );
    }

    return SmartMoneyScoreOpening(
      monthStart: monthStart,
      currencyCode: snapshot.currencyCode,
      openingBalance: balance.totalBalance - (month.income - month.expense),
      baselineState: SmartMoneyScoreBaselineState.reliable,
    );
  }
}
