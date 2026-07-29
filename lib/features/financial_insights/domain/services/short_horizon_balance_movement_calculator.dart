import 'dart:math' as math;

import '../entities/financial_insight.dart';
import '../entities/financial_insight_message.dart';

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
  final FinancialInsightMessage reason;

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
    final isToday = period == FinancialWindowKind.today;
    final balance = snapshot.balance;
    final hasMeaningfulActivity = window.income != 0 || window.expense != 0;

    if (balance.activeAccountCount == 0) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.insufficientData,
        reason: FinancialInsightMessage(
          isToday
              ? FinancialInsightMessageKey.shortHorizonNoActiveAccountToday
              : FinancialInsightMessageKey.shortHorizonNoActiveAccountWeek,
        ),
      );
    }
    if (_hasCrossCurrencyMovement(balance, period)) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.unsafeCurrencyMovement,
        reason: FinancialInsightMessage(
          isToday
              ? FinancialInsightMessageKey.shortHorizonCrossCurrencyToday
              : FinancialInsightMessageKey.shortHorizonCrossCurrencyWeek,
        ),
      );
    }
    if (_hasAccountCreatedInPeriod(balance, period)) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.insufficientData,
        reason: FinancialInsightMessage(
          isToday
              ? FinancialInsightMessageKey.shortHorizonAccountAddedToday
              : FinancialInsightMessageKey.shortHorizonAccountAddedWeek,
        ),
      );
    }
    if (!_isFinite(balance.totalBalance, window.income, window.expense)) {
      return _unavailable(
        period: period,
        currentBalance: balance.totalBalance,
        hasMeaningfulActivity: hasMeaningfulActivity,
        state: ShortHorizonBalanceMovementState.insufficientData,
        reason: FinancialInsightMessage(
          isToday
              ? FinancialInsightMessageKey.shortHorizonUnverifiableToday
              : FinancialInsightMessageKey.shortHorizonUnverifiableWeek,
        ),
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
        reason: FinancialInsightMessage(
          isToday
              ? FinancialInsightMessageKey.shortHorizonZeroOpeningToday
              : FinancialInsightMessageKey.shortHorizonZeroOpeningWeek,
        ),
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
    final movementArgs = {
      'percent': _roundedPercent(balanceChangePercentage),
      'points': _signedPoints(moderatedImpact),
    };
    final movementKey = balanceChange > 0
        ? (isToday
              ? FinancialInsightMessageKey.shortHorizonIncreasedToday
              : FinancialInsightMessageKey.shortHorizonIncreasedWeek)
        : balanceChange < 0
        ? (isToday
              ? FinancialInsightMessageKey.shortHorizonDecreasedToday
              : FinancialInsightMessageKey.shortHorizonDecreasedWeek)
        : (isToday
              ? FinancialInsightMessageKey.shortHorizonStayedLevelToday
              : FinancialInsightMessageKey.shortHorizonStayedLevelWeek);

    return ShortHorizonBalanceMovement(
      period: period,
      openingBalance: openingBalance,
      currentBalance: currentBalance,
      balanceChange: balanceChange,
      balanceChangePercentage: balanceChangePercentage,
      moderatedImpact: moderatedImpact,
      state: ShortHorizonBalanceMovementState.reliable,
      hasMeaningfulActivity: hasMeaningfulActivity,
      reason: FinancialInsightMessage(movementKey, movementArgs),
    );
  }

  ShortHorizonBalanceMovement _unavailable({
    required FinancialWindowKind period,
    required double currentBalance,
    required bool hasMeaningfulActivity,
    required ShortHorizonBalanceMovementState state,
    required FinancialInsightMessage reason,
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

  String _roundedPercent(double value) => '${value.round()}%';

  String _signedPoints(int value) => value > 0 ? '+$value' : '$value';
}
