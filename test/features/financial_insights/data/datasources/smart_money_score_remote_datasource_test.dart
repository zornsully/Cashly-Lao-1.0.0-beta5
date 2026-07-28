import 'package:cashly_lao/features/financial_insights/data/datasources/smart_money_score_remote_datasource.dart';
import 'package:cashly_lao/features/financial_insights/domain/entities/smart_money_score.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late FirestoreSmartMoneyScoreRemoteDataSource dataSource;

  SmartMoneyScoreOpening opening({
    double balance = 1000,
    String currencyCode = 'LAK',
    DateTime? monthStart,
  }) => SmartMoneyScoreOpening(
    monthStart: monthStart ?? DateTime(2026, 7),
    currencyCode: currencyCode,
    openingBalance: balance,
    baselineState: SmartMoneyScoreBaselineState.reliable,
  );

  SmartMoneyScoreCalculation calculation({int score = 105}) =>
      SmartMoneyScoreCalculation(
        calculatedAt: DateTime(2026, 7, 20, 9),
        currentBalance: 1050,
        balanceChange: 50,
        balanceChangePercentage: 5,
        income: 100,
        expense: 50,
        netCashFlow: 50,
        financialBehaviourModifier: 0,
        score: score,
        isReliable: true,
        hasMeaningfulActivity: true,
        reasons: const ['Balance increased by 5%.'],
        behaviourBreakdown: const SmartMoneyScoreBehaviourBreakdown(
          incomeExpenseImpact: 3,
          savingsImpact: 2,
          budgetImpact: 0,
          spendingTrendImpact: 0,
          lowBalanceImpact: 0,
          billImpact: 0,
          appliedModifier: 5,
        ),
      );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreSmartMoneyScoreRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test('uses one deterministic record for each currency/month reset', () async {
    final first = await dataSource.ensureMonthlyOpening(opening());
    final second = await dataSource.ensureMonthlyOpening(opening(balance: 999));

    expect(first.id, '2026-07_LAK');
    expect(second.opening.openingBalance, 1000);

    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('smartMoneyScores')
        .doc('2026-07_LAK')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['openingBalance'], 1000);
    expect(doc.data()!['monthKey'], '2026-07');
  });

  test(
    'rejects a non-calendar-month opening before it reaches Firestore',
    () async {
      final invalidOpening = SmartMoneyScoreOpening(
        monthStart: DateTime(2026, 7, 2),
        currencyCode: 'LAK',
        openingBalance: 1000,
        baselineState: SmartMoneyScoreBaselineState.reliable,
      );

      expect(
        () => dataSource.ensureMonthlyOpening(invalidOpening),
        throwsA(isA<ServerException>()),
      );
    },
  );

  test(
    'keeps different currencies and months as independent history',
    () async {
      await dataSource.ensureMonthlyOpening(opening(currencyCode: 'LAK'));
      await dataSource.ensureMonthlyOpening(opening(currencyCode: 'USD'));
      await dataSource.ensureMonthlyOpening(
        opening(monthStart: DateTime(2026, 8)),
      );

      final history = await dataSource.watchHistory().first;
      expect(history, hasLength(3));
      expect(history.map((record) => record.id), contains('2026-07_LAK'));
      expect(history.map((record) => record.id), contains('2026-07_USD'));
      expect(history.map((record) => record.id), contains('2026-08_LAK'));
    },
  );

  test(
    'stores calculation inputs without changing the opening baseline',
    () async {
      final month = await dataSource.ensureMonthlyOpening(opening());
      await dataSource.saveMonthlyCalculation(
        month: month,
        calculation: calculation(),
      );

      final history = await dataSource.watchHistory().first;
      final stored = history.single;
      expect(stored.opening.openingBalance, 1000);
      expect(stored.latestCalculation, isNotNull);
      expect(stored.latestCalculation!.score, 105);
      expect(stored.latestCalculation!.netCashFlow, 50);
      expect(stored.latestCalculation!.reasons.single, contains('5%'));
      expect(stored.latestCalculation!.behaviourBreakdown!.appliedModifier, 5);
    },
  );
}
