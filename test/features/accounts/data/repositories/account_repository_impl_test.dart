import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/accounts/data/datasources/account_remote_datasource.dart';
import 'package:cashly_lao/features/accounts/data/models/account_model.dart';
import 'package:cashly_lao/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRemoteDataSource extends Mock
    implements AccountRemoteDataSource {}

void main() {
  late _MockAccountRemoteDataSource dataSource;
  late AccountRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AccountType.cash);
    registerFallbackValue(AppIconKey.cash);
    registerFallbackValue(AppColorKey.emerald);
  });

  setUp(() {
    dataSource = _MockAccountRemoteDataSource();
    repository = AccountRepositoryImpl(dataSource);
  });

  AccountModel account({required String id, required bool isArchived}) {
    return AccountModel(
      id: id,
      name: 'Account $id',
      type: AccountType.cash,
      balance: 100,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
      isArchived: isArchived,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('watchAccounts', () {
    test('filters out archived accounts by default', () {
      when(() => dataSource.watchAccounts()).thenAnswer(
        (_) => Stream.value([
          account(id: '1', isArchived: false),
          account(id: '2', isArchived: true),
        ]),
      );

      expect(
        repository.watchAccounts(),
        emits(
          predicate<List<dynamic>>(
            (accounts) => accounts.length == 1 && accounts.first.id == '1',
          ),
        ),
      );
    });

    test('includes archived accounts when includeArchived is true', () {
      when(() => dataSource.watchAccounts()).thenAnswer(
        (_) => Stream.value([
          account(id: '1', isArchived: false),
          account(id: '2', isArchived: true),
        ]),
      );

      expect(
        repository.watchAccounts(includeArchived: true),
        emits(predicate<List<dynamic>>((accounts) => accounts.length == 2)),
      );
    });
  });

  test('createAccount maps a ServerException to Left(ServerFailure)', () async {
    when(
      () => dataSource.createAccount(
        name: any(named: 'name'),
        type: any(named: 'type'),
        initialBalance: any(named: 'initialBalance'),
        currencyCode: any(named: 'currencyCode'),
        icon: any(named: 'icon'),
        color: any(named: 'color'),
      ),
    ).thenThrow(const ServerException('Could not create the account.'));

    final result = await repository.createAccount(
      name: 'Cash',
      type: AccountType.cash,
      initialBalance: 0,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
    );

    expect(
      result,
      const Left<Failure, dynamic>(
        ServerFailure('Could not create the account.'),
      ),
    );
  });

  test('deleteAccount returns Right(unit) on success', () async {
    when(() => dataSource.deleteAccount('1')).thenAnswer((_) async {});

    final result = await repository.deleteAccount('1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('deleteAccount maps a ServerException to Left(ServerFailure)', () async {
    when(() => dataSource.deleteAccount('1')).thenThrow(
      const ServerException(
        "This account has transactions and can't be deleted — archive it "
        'instead.',
      ),
    );

    final result = await repository.deleteAccount('1');

    expect(
      result,
      const Left<Failure, Unit>(
        ServerFailure(
          "This account has transactions and can't be deleted — archive "
          'it instead.',
        ),
      ),
    );
  });
}
