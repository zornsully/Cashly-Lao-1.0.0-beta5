import 'package:cashly_lao/core/constants/app_color_key.dart';
import 'package:cashly_lao/core/constants/app_icon_key.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/savings_goals/domain/entities/savings_goal_entity.dart';
import 'package:cashly_lao/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:cashly_lao/features/savings_goals/domain/usecases/contribute_to_goal_usecase.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockSavingsGoalRepository extends Mock
    implements SavingsGoalRepository {}

void main() {
  late _MockTransactionRepository transactionRepository;
  late _MockSavingsGoalRepository goalRepository;
  late ContributeToGoalUseCase useCase;

  setUpAll(() {
    registerFallbackValue(TransactionType.transfer);
  });

  final goal = SavingsGoalEntity(
    id: 'goal-1',
    name: 'Vacation',
    targetAmount: 5000000,
    accountId: 'goal-acc',
    icon: AppIconKey.savings,
    color: AppColorKey.emerald,
    isArchived: false,
    lastContributionAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final transaction = TransactionEntity(
    id: 'txn-1',
    accountId: 'source-acc',
    toAccountId: 'goal-acc',
    type: TransactionType.transfer,
    amount: 200000,
    date: DateTime(2026, 5, 1),
    note: '',
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );

  setUp(() {
    transactionRepository = _MockTransactionRepository();
    goalRepository = _MockSavingsGoalRepository();
    useCase = ContributeToGoalUseCase(
      createTransaction: CreateTransactionUseCase(transactionRepository),
      goalRepository: goalRepository,
    );
  });

  void stubCreateTransaction(Either<Failure, TransactionEntity> result) {
    when(
      () => transactionRepository.createTransaction(
        accountId: any(named: 'accountId'),
        type: any(named: 'type'),
        toAccountId: any(named: 'toAccountId'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubRecordContribution(Either<Failure, Unit> result) {
    when(
      () => goalRepository.recordContribution(
        goalId: any(named: 'goalId'),
        contributedAt: any(named: 'contributedAt'),
      ),
    ).thenAnswer((_) async => result);
  }

  test("creates a transfer into the goal's account and records the "
      'contribution', () async {
    stubCreateTransaction(Right(transaction));
    stubRecordContribution(const Right(unit));

    final result = await useCase(
      goal: goal,
      sourceAccountId: 'source-acc',
      amount: 200000,
    );

    expect(result, Right(transaction));
    verify(
      () => transactionRepository.createTransaction(
        accountId: 'source-acc',
        type: TransactionType.transfer,
        toAccountId: 'goal-acc',
        amount: 200000,
        date: any(named: 'date'),
        note: any(named: 'note'),
        categoryId: any(named: 'categoryId'),
      ),
    ).called(1);
    verify(
      () => goalRepository.recordContribution(
        goalId: 'goal-1',
        contributedAt: any(named: 'contributedAt'),
      ),
    ).called(1);
  });

  test('does not record a contribution when the transfer fails', () async {
    stubCreateTransaction(const Left(ServerFailure('boom')));

    final result = await useCase(
      goal: goal,
      sourceAccountId: 'source-acc',
      amount: 200000,
    );

    expect(result, const Left<Failure, dynamic>(ServerFailure('boom')));
    verifyNever(
      () => goalRepository.recordContribution(
        goalId: any(named: 'goalId'),
        contributedAt: any(named: 'contributedAt'),
      ),
    );
  });

  test('a recordContribution failure does not negate an already-successful '
      'transfer', () async {
    stubCreateTransaction(Right(transaction));
    stubRecordContribution(
      const Left(ServerFailure('could not update timestamp')),
    );

    final result = await useCase(
      goal: goal,
      sourceAccountId: 'source-acc',
      amount: 200000,
    );

    expect(result, Right(transaction));
  });
}
