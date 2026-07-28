import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/smart_money_score.dart';
import '../../domain/services/financial_insight_engine.dart';
import '../../domain/services/rule_based_financial_insight_engine.dart';
import '../../domain/usecases/build_financial_insight_snapshots_usecase.dart';
import '../../domain/usecases/derive_smart_money_score_opening_usecase.dart';
import 'smart_money_score_providers.dart';

final financialInsightEngineProvider = Provider<FinancialInsightEngine>((ref) {
  return const RuleBasedFinancialInsightEngine();
});

/// Re-emits at the next local calendar boundary so a dashboard left open
/// overnight moves into the new day/month and creates its new deterministic
/// opening record. Firestore remains the cross-device source of truth.
class _FinancialInsightReferenceDate extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    _scheduleNextBoundary();
    return DateTime.now();
  }

  void _scheduleNextBoundary() {
    _timer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(tomorrow.difference(now), () {
      state = DateTime.now();
      _scheduleNextBoundary();
    });
  }
}

final _financialInsightReferenceDateProvider =
    NotifierProvider<_FinancialInsightReferenceDate, DateTime>(
      _FinancialInsightReferenceDate.new,
    );

const _buildSnapshots = BuildFinancialInsightSnapshotsUseCase();
const _deriveMonthlyOpening = DeriveSmartMoneyScoreOpeningUseCase();

/// Live dashboard insights. This provider intentionally depends on aggregate
/// application data only; swapping [financialInsightEngineProvider] later can
/// add an LLM without changing the dashboard or its data sources.
final financialInsightsProvider = FutureProvider<List<FinancialInsight>>((
  ref,
) async {
  final asOf = ref.watch(_financialInsightReferenceDateProvider);
  final currentMonth = DateTime(asOf.year, asOf.month);
  final previousMonth = DateTime(asOf.year, asOf.month - 1);
  final accounts = await ref.watch(accountsProvider(true).future);
  final categories = await ref.watch(
    categoriesProvider((type: null, includeArchived: true)).future,
  );
  final currentTransactions = await ref.watch(
    transactionsForMonthProvider(currentMonth).future,
  );
  final previousTransactions = await ref.watch(
    transactionsForMonthProvider(previousMonth).future,
  );
  final budgets = await ref.watch(budgetsForMonthProvider(currentMonth).future);

  final snapshots = _buildSnapshots(
    asOf: asOf,
    accounts: accounts,
    categories: categories,
    transactions: [...currentTransactions, ...previousTransactions],
    budgets: budgets,
  );
  // An account in a second currency should not create a full empty check-in
  // card. Keep currencies with recent money activity, an active budget, or a
  // negative active balance; if everything is new, retain one gentle
  // onboarding card instead.
  final visibleSnapshots = snapshots
      .where(
        (snapshot) =>
            snapshot.hasActivity ||
            snapshot.budgets.isNotEmpty ||
            snapshot.hasNegativeBalance,
      )
      .toList();
  final snapshotsToAnalyze = visibleSnapshots.isNotEmpty
      ? visibleSnapshots
      : snapshots.take(1).toList();

  final scoreRepository = ref.watch(smartMoneyScoreRepositoryProvider);
  final scoreCalculator = ref.watch(smartMoneyScoreCalculatorProvider);
  final lifecycleSnapshots = await Future.wait(
    snapshotsToAnalyze.map((snapshot) async {
      final candidateOpening = _deriveMonthlyOpening(snapshot);
      var opening = candidateOpening;
      SmartMoneyScoreMonth? persistedMonth;

      // The dashboard remains useful offline: if the shared baseline cannot
      // be reached, calculate from the same deterministic candidate and let
      // Firestore reconcile it when the connection returns. A successful
      // transaction always wins over a local candidate, protecting the
      // original opening balance across devices.
      if (candidateOpening.isReliable) {
        final openingResult = await scoreRepository.ensureMonthlyOpening(
          candidateOpening,
        );
        openingResult.match(
          (_) {
            // Do not turn a temporary sync failure into a broken dashboard.
          },
          (month) {
            persistedMonth = month;
            opening = month.opening;
          },
        );
      }

      final calculation = scoreCalculator.calculate(
        snapshot: snapshot,
        opening: opening,
      );
      if (persistedMonth != null) {
        await scoreRepository.saveMonthlyCalculation(
          month: persistedMonth!,
          calculation: calculation,
        );
      }
      return snapshot.copyWith(monthlyScoreCalculation: calculation);
    }),
  );

  final engine = ref.watch(financialInsightEngineProvider);
  return Future.wait(lifecycleSnapshots.map(engine.analyze));
});
