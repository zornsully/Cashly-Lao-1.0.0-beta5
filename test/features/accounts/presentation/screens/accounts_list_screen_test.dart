import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_currency.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/utils/currency_formatter.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/presentation/providers/account_providers.dart';
import 'package:cashly_lao/features/accounts/presentation/screens/accounts_list_screen.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  final now = DateTime.now();

  final account = AccountEntity(
    id: 'acc-1',
    name: 'Cash Wallet',
    type: AccountType.cash,
    balance: 750,
    currencyCode: 'USD',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    AccountRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders each account\'s name and balance', (tester) async {
    final repository = _MockAccountRepository();
    when(
      () => repository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value([account]));

    await pumpScreen(tester, repository);

    expect(find.text('Cash Wallet'), findsOneWidget);
    expect(
      find.text(
        CurrencyFormatter.format(750, SupportedCurrencies.byCode('USD')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state when there are no accounts yet', (
    tester,
  ) async {
    final repository = _MockAccountRepository();
    when(
      () => repository.watchAccounts(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) => Stream.value(const []));

    await pumpScreen(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.noAccountsYetTitle), findsOneWidget);
  });
}
