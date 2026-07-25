import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_entity.dart';
import 'package:cashly_lao/features/accounts/domain/entities/account_type.dart';
import 'package:cashly_lao/features/accounts/domain/repositories/account_repository.dart';
import 'package:cashly_lao/features/accounts/domain/usecases/create_account_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late _MockAccountRepository repository;
  late CreateAccountUseCase useCase;

  setUp(() {
    repository = _MockAccountRepository();
    useCase = CreateAccountUseCase(repository);
  });

  final account = AccountEntity(
    id: 'acc-1',
    name: 'Cash',
    type: AccountType.cash,
    balance: 100,
    currencyCode: 'LAK',
    icon: AppIconKey.cash,
    color: AppColorKey.emerald,
    isArchived: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('delegates to the repository and returns the created account', () async {
    when(
      () => repository.createAccount(
        name: 'Cash',
        type: AccountType.cash,
        initialBalance: 100,
        currencyCode: 'LAK',
        icon: AppIconKey.cash,
        color: AppColorKey.emerald,
      ),
    ).thenAnswer((_) async => Right(account));

    final result = await useCase(
      name: 'Cash',
      type: AccountType.cash,
      initialBalance: 100,
      currencyCode: 'LAK',
      icon: AppIconKey.cash,
      color: AppColorKey.emerald,
    );

    expect(result, Right<Failure, AccountEntity>(account));
  });
}
