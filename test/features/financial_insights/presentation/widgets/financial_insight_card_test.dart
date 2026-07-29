import 'package:cashly_lao/features/financial_insights/domain/entities/financial_insight.dart';
import 'package:cashly_lao/features/financial_insights/presentation/widgets/financial_insight_card.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = FinancialSpendingWindow(
    kind: FinancialWindowKind.today,
    expense: 90000,
    income: 0,
    previousExpense: 40000,
    transactionCount: 1,
  );
  const week = FinancialSpendingWindow(
    kind: FinancialWindowKind.week,
    expense: 430500,
    income: 0,
    previousExpense: 300000,
    transactionCount: 4,
  );
  const month = FinancialSpendingWindow(
    kind: FinancialWindowKind.month,
    expense: 430500,
    income: 700000,
    previousExpense: 500000,
    transactionCount: 4,
  );

  const insight = FinancialInsight(
    currencyCode: 'LAK',
    totalBalance: 1200000,
    todayScore: FinancialPeriodScore(
      period: FinancialWindowKind.today,
      value: 68,
      tone: FinancialInsightTone.watch,
      reasons: ['Today is higher than your earlier weekly pace.'],
    ),
    weekScore: FinancialPeriodScore(
      period: FinancialWindowKind.week,
      value: 82,
      tone: FinancialInsightTone.watch,
      reasons: ['This week is a little above the previous week.'],
    ),
    monthScore: FinancialPeriodScore(
      period: FinancialWindowKind.month,
      value: 94,
      tone: FinancialInsightTone.positive,
      reasons: ['Income covers this month\'s spending.'],
    ),
    tone: FinancialInsightTone.watch,
    headline: 'Today is spending faster than this week\'s pace.',
    explanation: 'One quick check can keep the day in your control.',
    scoreReasons: ['Today is higher than your earlier weekly pace.'],
    actions: [
      FinancialInsightAction(
        title: 'Check the next expense before you buy',
        detail: 'A quick pause can keep today closer to your usual pace.',
      ),
    ],
    today: today,
    week: week,
    month: month,
  );

  testWidgets('shows daily, weekly, and monthly scores on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinancialInsightCard(insight: insight),
          ),
        ),
      ),
    );

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('68'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.text('94'), findsNWidgets(2));
    expect(find.text('Current balance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
