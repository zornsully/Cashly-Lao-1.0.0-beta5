import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_entity.dart';
import 'package:cashly_lao/features/categories/domain/entities/category_type.dart';
import 'package:cashly_lao/features/categories/presentation/screens/category_form_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3);

  CategoryEntity category({required bool isDefault}) {
    return CategoryEntity(
      id: 'cat-1',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isDefault: isDefault,
      isArchived: false,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows a Default badge and explanation when editing a default category',
    (tester) async {
      await pump(
        tester,
        CategoryFormScreen(existing: category(isDefault: true)),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.defaultBadgeLabel), findsOneWidget);
      expect(find.text(l10n.defaultCategoryLockedHelper), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'does not show the Default badge when editing a non-default category',
    (tester) async {
      await pump(
        tester,
        CategoryFormScreen(existing: category(isDefault: false)),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.defaultCategoryLockedHelper), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not show the Default badge when creating a new category', (
    tester,
  ) async {
    await pump(
      tester,
      const CategoryFormScreen(initialType: CategoryType.expense),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.defaultCategoryLockedHelper), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
