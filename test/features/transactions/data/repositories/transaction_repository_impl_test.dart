import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:cashly_lao/features/transactions/data/models/transaction_model.dart';
import 'package:cashly_lao/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}

void main() {
  late _MockTransactionRemoteDataSource dataSource;
  late TransactionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TransactionType.expense);
  });

  setUp(() {
    dataSource = _MockTransactionRemoteDataSource();
    repository = TransactionRepositoryImpl(dataSource);
  });

  final transaction = TransactionModel(
    id: 'txn-1',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    type: TransactionType.expense,
    amount: 25,
    date: DateTime(2026, 3, 10),
    note: '',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('createTransaction returns Right(transaction) on success', () async {
    when(
      () => dataSource.createTransaction(
        accountId: any(named: 'accountId'),
        categoryId: any(named: 'categoryId'),
        type: any(named: 'type'),
        amount: any(named: 'amount'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => transaction);

    final result = await repository.createTransaction(
      accountId: 'acc-1',
      categoryId: 'cat-1',
      type: TransactionType.expense,
      amount: 25,
      date: DateTime(2026, 3, 10),
      note: '',
    );

    expect(result, Right(transaction));
  });

  test(
    'createTransaction maps ServerException to Left(ServerFailure)',
    () async {
      when(
        () => dataSource.createTransaction(
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
          type: any(named: 'type'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenThrow(const ServerException('That account no longer exists.'));

      final result = await repository.createTransaction(
        accountId: 'missing',
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 25,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      expect(
        result,
        const Left<Failure, dynamic>(
          ServerFailure('That account no longer exists.'),
        ),
      );
    },
  );

  test('createTransaction passes toAccountId through for a transfer, with '
      'no categoryId', () async {
    final transfer = TransactionModel(
      id: 'txn-2',
      accountId: 'acc-1',
      toAccountId: 'acc-2',
      type: TransactionType.transfer,
      amount: 30,
      date: DateTime(2026, 3, 10),
      note: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(
      () => dataSource.createTransaction(
        accountId: 'acc-1',
        categoryId: null,
        type: TransactionType.transfer,
        toAccountId: 'acc-2',
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      ),
    ).thenAnswer((_) async => transfer);

    final result = await repository.createTransaction(
      accountId: 'acc-1',
      toAccountId: 'acc-2',
      type: TransactionType.transfer,
      amount: 30,
      date: DateTime(2026, 3, 10),
      note: '',
    );

    expect(result, Right(transfer));
  });

  test('deleteTransaction returns Right(unit) on success', () async {
    when(() => dataSource.deleteTransaction('txn-1')).thenAnswer((_) async {});

    final result = await repository.deleteTransaction('txn-1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('watchTransactionsForMonth passes the month straight through', () {
    final month = DateTime(2026, 3);
    when(
      () => dataSource.watchTransactionsForMonth(month),
    ).thenAnswer((_) => Stream.value([transaction]));

    expect(
      repository.watchTransactionsForMonth(month),
      emits(predicate<List<dynamic>>((t) => t.length == 1)),
    );
  });
}
