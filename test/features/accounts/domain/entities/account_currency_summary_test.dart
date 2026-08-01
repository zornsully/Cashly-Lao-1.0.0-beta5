import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_currency_summary.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 1);
  AccountEntity account(String id, String currency, double balance) =>
      AccountEntity(
        id: id,
        name: id,
        type: AccountType.bank,
        balance: balance,
        currencyCode: currency,
        icon: AppIconKey.bank,
        color: AppColorKey.emerald,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

  test(
    'keeps currencies separate and treats negative balances as liabilities',
    () {
      final summaries = buildAccountCurrencySummaries([
        account('lak-positive', 'LAK', 8103630),
        account('lak-negative', 'LAK', -1903045),
        account('usd-positive', 'USD', 806.79),
      ]);

      expect(summaries, hasLength(2));
      final lak = summaries.first;
      expect(lak.currencyCode, 'LAK');
      expect(lak.assets, 8103630);
      expect(lak.liabilities, 1903045);
      expect(lak.netWorth, 6200585);
      expect(lak.assetShareFor(lak.accounts[0]), 1);
      expect(lak.assetShareFor(lak.accounts[1]), isNull);
      expect(summaries[1].netWorth, 806.79);
    },
  );

  test('hides asset share when there are no positive assets', () {
    final summary = buildAccountCurrencySummaries([
      account('overdrawn', 'LAK', -10),
      account('zero', 'LAK', 0),
    ]).single;
    expect(summary.assets, 0);
    expect(summary.assetShareFor(summary.accounts.first), isNull);
    expect(summary.assetShareFor(summary.accounts.last), isNull);
  });
}
