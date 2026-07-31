import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_entity.dart';
import 'package:cashly_lao/features/budget/domain/entities/budget_progress.dart';
import 'package:cashly_lao/features/budget/presentation/widgets/budget_progress_tile.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3);
  final category = CategoryEntity(
    id: 'cat-1',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
  final lak = SupportedCurrencies.byCode('LAK');

  BudgetProgress progressWith({required double limit, required double spent}) {
    return BudgetProgress(
      budget: BudgetEntity(
        id: 'budget-1',
        categoryId: category.id,
        month: now,
        limitAmount: limit,
        currencyCode: 'LAK',
        createdAt: now,
        updatedAt: now,
      ),
      category: category,
      spentAmount: spent,
    );
  }

  Future<void> pump(WidgetTester tester, BudgetProgress progress) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BudgetProgressTile(progress: progress, onDelete: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the percentage used and remaining amount when on track', (
    tester,
  ) async {
    await pump(tester, progressWith(limit: 1000, spent: 400));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(
      find.text(
        '${l10n.budgetPercentUsedLabel('40')} · '
        '${l10n.remainingAmountMessage(CurrencyFormatter.format(600, lak))}',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows an overspent state with the warning icon and delete button',
    (tester) async {
      await pump(tester, progressWith(limit: 1000, spent: 1200));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(
        find.text(
          '${l10n.budgetPercentUsedLabel('120')} · '
          '${l10n.overspentByMessage(CurrencyFormatter.format(200, lak))}',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip(l10n.deleteBudgetTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
