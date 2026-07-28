import 'dart:math' as math;

import '../entities/financial_insight.dart';

/// Why a short-horizon balance comparison can or cannot be trusted.
///
/// Day and week openings are reconstructed from the live aggregate rather
/// than persisted. That is safe only while the included account set and the
/// currency basis are unchanged for the relevant window.
enum ShortHorizonBalanceMovementState {
  reliable,
  insufficientData,
  unsafeCurrencyMovement,
}

/// A bounded balance-movement contribution for the Today or Week score.
///
/// The monthly score keeps the full balance-growth formula. Short-horizon
/// scores intentionally use a modest contribution so one large deposit or
/// withdrawal cannot erase useful budget and spending-pace signals.
class ShortHorizonBalanceMovement {
  const ShortHorizonBalanceMovement({
    required this.period,
    required this.openingBalance,
    required this.currentBalance,
    required this.balanceChange,
    required this.balanceChangePercentage,
    required this.moderatedImpact,
    required this.state,
    required this.hasMeaningfulActivity,
    required this.reason,
  });

  final FinancialWindowKind period;
  final double openingBalance;
  final double currentBalance;
  final double balanceChange;
  final double balanceChangePercentage;

  /// A deliberately small, capped adjustment to a 0-100 score.
  final int moderatedImpact;
  final ShortHorizonBalanceMovementState state;
  final bool hasMeaningfulActivity;
  final String reason;

  bool get isReliable => state == ShortHorizonBalanceMovementState.reliable;

  bool get hasComparableMovement => isReliable && hasMeaningfulActivity;
}

/// Derives balance movement for Today and This Week from an aggregated
/// [FinancialInsightSnapshot].
///
/// Income and expense writes already update account balances atomically, so
/// `currentBalance - (income - expense)` reconstructs the window opening
/// balance when the snapshot is safe. Same-currency transfers are excluded
/// from cash flow and leave an included-currency total unchanged. A
/// cross-currency transfer or account created within the window makes the
/// reconstruction unavailable rather than guessed.
class ShortHorizonBalanceMovementCalculator {
  const ShortHorizonBalanceMovementCalculator();

  static const int maxModeratedImpact = 15;
  static const double _impactPerPercent = .25;

  ShortHorizonBalanceMovement calculate({
    required FinancialInsightSnapshot snapshot,
    required FinancialWindowKind period,
  }) {
    assert(
      period == FinancialWindowKind.today || period == FinancialWindowKind.week,
      'Only Today and Week balance movement is derived here.',
    );
    final window = switch (period) {
      FinancialWindowKind.today => snapshot.today,
      FinancialWindowKind.week => snapshot.week,
      FinancialWindowKind.month => throw ArgumentError.value(
        period,
        'period',
        'Monthly movement uses the persisted Smart Money Score lifecycle.',
      ),
    };
    final label = _periodLabel(period);
    final balance = snapshot.balance;
    final hasMeaningfulActivity = window.income != 0 || window.expense != 0;

    if (balance.activeAccountCount == 0) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.insufficientData,
        reason:
            '$label has no active account balance to compare yet, so Cashly is using current balance, budget, and spending signals.',
      );
    }
    if (_hasCrossCurrencyMovement(balance, period)) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.unsafeCurrencyMovement,
        reason:
            'A transfer between currencies occurred during $label. Cashly is keeping its balance comparison neutral until an exchange-rate basis is available.',
      );
    }
    if (_hasAccountCreatedInPeriod(balance, period)) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.insufficientData,
        reason:
            'An account was added during $label, so Cashly cannot safely reconstruct that opening balance yet.',
      );
    }
    if (!_isFinite(balance.totalBalance, window.income, window.expense)) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.insufficientData,
        reason:
            'Cashly could not verify the balance values for $label, so its balance comparison is neutral.',
      );
    }

    final currentBalance = balance.totalBalance;
    final netCashFlow = window.income - window.expense;
    final openingBalance = currentBalance - netCashFlow;
    final balanceChange = currentBalance - openingBalance;

    if (openingBalance == 0 && !hasMeaningfulActivity) {
      return ShortHorizonBalanceMovement(
        period: period,
        openingBalance: openingBalance,
        currentBalance: currentBalance,
        balanceChange: balanceChange,
        balanceChangePercentage: 0,
        moderatedImpact: 0,
        state: ShortHorizonBalanceMovementState.insufficientData,
        hasMeaningfulActivity: false,
        reason:
            '$label began at zero with no recorded income or expense, so Cashly is using current balance, budget, and spending signals.',
      );
    }

    final double balanceChangePercentage;
    if (openingBalance == 0) {
      // A zero opening has no meaningful percentage denominator. Use the
      // window cash flow only after activity has started, just as the
      // monthly calculator does.
      final scale = math.max(
        math.max(window.income.abs(), window.expense.abs()),
        1,
      );
      balanceChangePercentage = (balanceChange / scale) * 100;
    } else {
      balanceChangePercentage =
          (balanceChange / math.max(openingBalance.abs(), 1)) * 100;
    }
    final moderatedImpact = (balanceChangePercentage * _impactPerPercent)
        .round()
        .clamp(-maxModeratedImpact, maxModeratedImpact)
        .toInt();
    final direction = balanceChange > 0
        ? 'increased'
        : balanceChange < 0
        ? 'decreased'
        : 'stayed level';

    return ShortHorizonBalanceMovement(
      period: period,
      openingBalance: openingBalance,
      currentBalance: currentBalance,
      balanceChange: balanceChange,
      balanceChangePercentage: balanceChangePercentage,
      moderatedImpact: moderatedImpact,
      state: ShortHorizonBalanceMovementState.reliable,
      hasMeaningfulActivity: hasMeaningfulActivity,
      reason:
          '$label balance $direction by ${_roundedPercent(balanceChangePercentage)}. This contributes ${_signedPoints(moderatedImpact)} point${moderatedImpact.abs() == 1 ? '' : 's'} alongside budget and spending signals.',
    );
  }

  ShortHorizonBalanceMovement _unavailable({
    required FinancialWindowKind period,
    required double currentBalance,
    required bool hasMeaningfulActivity,
    required ShortHorizonBalanceMovementState state,
    required String reason,
  }) => ShortHorizonBalanceMovement(
    period: period,
    openingBalance: currentBalance,
    currentBalance: currentBalance,
    balanceChange: 0,
    balanceChangePercentage: 0,
    moderatedImpact: 0,
    state: state,
    hasMeaningfulActivity: hasMeaningfulActivity,
    reason: reason,
  );

  bool _hasCrossCurrencyMovement(
    FinancialBalancePosition balance,
    FinancialWindowKind period,
  ) => switch (period) {
    FinancialWindowKind.today => balance.hasCrossCurrencyTransferToday,
    FinancialWindowKind.week => balance.hasCrossCurrencyTransferThisWeek,
    FinancialWindowKind.month => balance.hasCrossCurrencyTransfer,
  };

  bool _hasAccountCreatedInPeriod(
    FinancialBalancePosition balance,
    FinancialWindowKind period,
  ) => switch (period) {
    FinancialWindowKind.today => balance.hasAccountCreatedToday,
    FinancialWindowKind.week => balance.hasAccountCreatedThisWeek,
    FinancialWindowKind.month => balance.hasAccountCreatedThisMonth,
  };

  bool _isFinite(double a, double b, double c) =>
      a.isFinite && b.isFinite && c.isFinite;

  String _periodLabel(FinancialWindowKind period) => switch (period) {
    FinancialWindowKind.today => 'Today',
    FinancialWindowKind.week => 'This week',
    FinancialWindowKind.month => 'This month',
  };

  String _roundedPercent(double value) => '${value.round()}%';

  String _signedPoints(int value) => value > 0 ? '+$value' : '$value';
}
