import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_entity.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:cashly_lao/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:cashly_lao/features/transactions/domain/usecases/create_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockTransactionRepository repository;
  late CreateTransactionUseCase useCase;

  setUp(() {
    repository = _MockTransactionRepository();
    useCase = CreateTransactionUseCase(repository);
  });

  final transaction = TransactionEntity(
    id: 'txn-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.income,
    amount: 500,
    date: DateTime(2026, 3, 1),
    note: 'Freelance payment',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test(
    'delegates to the repository and returns the created transaction',
    () async {
      when(
        () => repository.createTransaction(
          accountId: 'acc-1',
          categoryId: 'cat-1',
          type: TransactionType.income,
          amount: 500,
          date: DateTime(2026, 3, 1),
          note: 'Freelance payment',
        ),
      ).thenAnswer((_) async => Right(transaction));

      final result = await useCase(
        accountId: 'acc-1',
        categoryId: 'cat-1',
        type: TransactionType.income,
        amount: 500,
        date: DateTime(2026, 3, 1),
        note: 'Freelance payment',
      );

      expect(result, Right<Failure, TransactionEntity>(transaction));
    },
  );
}
