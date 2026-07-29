import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:cashly_lao/features/transactions/domain/entities/transaction_type.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

/// Forces the same error the native SDK returns before an offline
/// transaction can start. The inherited datasource still uses the real
/// [FakeFirebaseFirestore] batch path, so assertions below exercise the
/// cached-read + queued-write fallback rather than a mock implementation.
class _OfflineTransactionRemoteDataSource
    extends FirestoreTransactionRemoteDataSource {
  _OfflineTransactionRemoteDataSource({
    required super.firestore,
    required super.firebaseAuth,
  });

  @override
  Future<T> runAtomicTransaction<T>(TransactionHandler<T> transactionHandler) {
    return Future<T>.error(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'The client is offline.',
      ),
    );
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late FirestoreTransactionRemoteDataSource dataSource;
  late FirestoreTransactionRemoteDataSource offlineDataSource;

  Future<String> seedAccount(double balance) async {
    final ref = firestore
        .collection('users')
        .doc('uid-1')
        .collection('accounts')
        .doc();
    await ref.set({'balance': balance});
    return ref.id;
  }

  Future<double> readBalance(String accountId) async {
    final doc = await firestore
        .collection('users')
        .doc('uid-1')
        .collection('accounts')
        .doc(accountId)
        .get();
    return (doc.data()!['balance'] as num).toDouble();
  }

  Future<void> settleQueuedWrite() async {
    // FakeFirestore applies a WriteBatch asynchronously, just like the
    // native SDK's local persistence queue. Two turns keep this test focused
    // on the visible local result without depending on implementation timing.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    dataSource = FirestoreTransactionRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
    offlineDataSource = _OfflineTransactionRemoteDataSource(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  group('offline mutation fallback', () {
    test(
      'queues a create from cached account data and updates local state',
      () async {
        final accountId = await seedAccount(100);

        final created = await offlineDataSource.createTransaction(
          accountId: accountId,
          categoryId: 'cat-1',
          type: TransactionType.expense,
          amount: 30,
          date: DateTime(2026, 3, 10),
          note: 'Queued coffee',
        );
        await settleQueuedWrite();

        expect(await readBalance(accountId), 70);
        final transaction = await firestore
            .collection('users')
            .doc('uid-1')
            .collection('transactions')
            .doc(created.id)
            .get();
        expect(transaction.exists, isTrue);
        expect(transaction.data()!['note'], 'Queued coffee');
      },
    );

    test('queues an update using the cached old transaction shape', () async {
      final accountId = await seedAccount(100);
      final created = await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      await offlineDataSource.updateTransaction(
        id: created.id,
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 50,
        date: DateTime(2026, 3, 10),
        note: 'Queued correction',
      );
      await settleQueuedWrite();

      expect(await readBalance(accountId), 50);
      final transaction = await firestore
          .collection('users')
          .doc('uid-1')
          .collection('transactions')
          .doc(created.id)
          .get();
      expect(transaction.data()!['amount'], 50);
      expect(transaction.data()!['note'], 'Queued correction');
    });

    test('queues a delete using the cached transaction shape', () async {
      final accountId = await seedAccount(100);
      final created = await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.income,
        amount: 40,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      await offlineDataSource.deleteTransaction(created.id);
      await settleQueuedWrite();

      expect(await readBalance(accountId), 100);
      final transaction = await firestore
          .collection('users')
          .doc('uid-1')
          .collection('transactions')
          .doc(created.id)
          .get();
      expect(transaction.exists, isFalse);
    });

    test(
      'refuses an offline edit or delete when the transaction is not cached',
      () async {
        final accountId = await seedAccount(100);

        await expectLater(
          offlineDataSource.updateTransaction(
            id: 'not-cached',
            accountId: accountId,
            categoryId: 'cat-1',
            type: TransactionType.expense,
            amount: 10,
            date: DateTime(2026, 3, 10),
            note: '',
          ),
          throwsA(isA<ServerException>()),
        );

        await expectLater(
          offlineDataSource.deleteTransaction('not-cached'),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('createTransaction', () {
    test('increases the account balance for income', () async {
      final accountId = await seedAccount(100);

      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.income,
        amount: 50,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      expect(await readBalance(accountId), 150);
    });

    test('decreases the account balance for expense', () async {
      final accountId = await seedAccount(100);

      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: 'Coffee',
      );

      expect(await readBalance(accountId), 70);
    });

    test('throws ServerException when the account does not exist', () async {
      expect(
        () => dataSource.createTransaction(
          accountId: 'missing-account',
          categoryId: 'cat-1',
          type: TransactionType.income,
          amount: 10,
          date: DateTime(2026),
          note: '',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('updateTransaction', () {
    test('reconciles the balance when the account is unchanged', () async {
      final accountId = await seedAccount(100);
      final created = await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountId), 80);

      // Change the expense from 20 to 50 on the same account: balance
      // should drop by the additional 30, landing at 50.
      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 50,
        date: DateTime(2026, 3, 10),
        note: 'updated',
      );

      expect(await readBalance(accountId), 50);
    });

    test('reconciles both balances when the account changes', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(200);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountA), 80);

      // Move the same 20-expense to account B: A should be refunded back
      // to 100, and B should drop by 20 to 180.
      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountB,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      expect(await readBalance(accountA), 100);
      expect(await readBalance(accountB), 180);
    });

    test('reconciles the balance when the type flips income/expense', () async {
      final accountId = await seedAccount(100);
      final created = await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.income,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountId), 120);

      // Flip the same 20 from income to expense: -20 (undo income) - 20
      // (apply expense) = balance drops by 40 total, landing at 80.
      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      expect(await readBalance(accountId), 80);
    });
  });

  group('deleteTransaction', () {
    test('reverses the effect on the account balance', () async {
      final accountId = await seedAccount(100);
      final created = await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.income,
        amount: 40,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountId), 140);

      await dataSource.deleteTransaction(created.id);

      expect(await readBalance(accountId), 100);
      final remaining = await dataSource
          .watchTransactionsForMonth(DateTime(2026, 3))
          .first;
      expect(remaining, isEmpty);
    });

    test('is a no-op when the transaction no longer exists', () async {
      await dataSource.deleteTransaction('does-not-exist');
      // Should not throw.
    });
  });

  group('transfers', () {
    test(
      'createTransaction moves the amount from source to destination',
      () async {
        final accountA = await seedAccount(100);
        final accountB = await seedAccount(50);

        await dataSource.createTransaction(
          accountId: accountA,
          toAccountId: accountB,
          type: TransactionType.transfer,
          amount: 30,
          date: DateTime(2026, 3, 10),
          note: '',
        );

        expect(await readBalance(accountA), 70);
        expect(await readBalance(accountB), 80);
      },
    );

    test('createTransaction throws when the destination account does not '
        'exist', () async {
      final accountA = await seedAccount(100);

      expect(
        () => dataSource.createTransaction(
          accountId: accountA,
          toAccountId: 'missing-account',
          type: TransactionType.transfer,
          amount: 30,
          date: DateTime(2026, 3, 10),
          note: '',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'createTransaction throws when the destination equals the source',
      () async {
        final accountA = await seedAccount(100);

        expect(
          () => dataSource.createTransaction(
            accountId: accountA,
            toAccountId: accountA,
            type: TransactionType.transfer,
            amount: 30,
            date: DateTime(2026, 3, 10),
            note: '',
          ),
          throwsA(isA<ServerException>()),
        );
        // Neither the ServerException path nor any partial write should
        // have touched the balance.
        expect(await readBalance(accountA), 100);
      },
    );

    test('deleteTransaction reverses both balances', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(50);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountA), 70);
      expect(await readBalance(accountB), 80);

      await dataSource.deleteTransaction(created.id);

      expect(await readBalance(accountA), 100);
      expect(await readBalance(accountB), 50);
    });

    test('updateTransaction reconciles both balances when the amount '
        'changes', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(50);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountA), 70);
      expect(await readBalance(accountB), 80);

      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 50,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      // As if a 50 transfer had happened from the original 100/50 start.
      expect(await readBalance(accountA), 50);
      expect(await readBalance(accountB), 100);
    });

    test('updateTransaction reconciles all three balances when the '
        'destination account changes', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(50);
      final accountC = await seedAccount(200);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountA), 70);
      expect(await readBalance(accountB), 80);

      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountA,
        toAccountId: accountC,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      // A stays debited by the same 30; B is refunded; C receives it.
      expect(await readBalance(accountA), 70);
      expect(await readBalance(accountB), 50);
      expect(await readBalance(accountC), 230);
    });

    test('updateTransaction reconciles balances when a transfer becomes an '
        'expense', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(50);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountA), 70);
      expect(await readBalance(accountB), 80);

      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountA,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      // As if only a standalone 20 expense from A had ever happened; B
      // is fully refunded back to its starting balance.
      expect(await readBalance(accountA), 80);
      expect(await readBalance(accountB), 50);
    });

    test('updateTransaction reconciles balances when an expense becomes a '
        'transfer', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(50);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 20,
        date: DateTime(2026, 3, 10),
        note: '',
      );
      expect(await readBalance(accountA), 80);

      await dataSource.updateTransaction(
        id: created.id,
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      // As if only a standalone 30 transfer had ever happened.
      expect(await readBalance(accountA), 70);
      expect(await readBalance(accountB), 80);
    });

    test('updateTransaction throws when edited to the same source and '
        'destination', () async {
      final accountA = await seedAccount(100);
      final accountB = await seedAccount(50);
      final created = await dataSource.createTransaction(
        accountId: accountA,
        toAccountId: accountB,
        type: TransactionType.transfer,
        amount: 30,
        date: DateTime(2026, 3, 10),
        note: '',
      );

      expect(
        () => dataSource.updateTransaction(
          id: created.id,
          accountId: accountA,
          toAccountId: accountA,
          type: TransactionType.transfer,
          amount: 30,
          date: DateTime(2026, 3, 10),
          note: '',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('watchTransactionsForMonth', () {
    test('only returns transactions within the given month', () async {
      final accountId = await seedAccount(1000);

      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 10,
        date: DateTime(2026, 3, 1),
        note: 'in March',
      );
      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 10,
        date: DateTime(2026, 3, 31, 23, 59),
        note: 'still March',
      );
      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 10,
        date: DateTime(2026, 4, 1),
        note: 'April',
      );

      final march = await dataSource
          .watchTransactionsForMonth(DateTime(2026, 3))
          .first;

      expect(march, hasLength(2));
      expect(march.every((t) => t.date.month == 3), isTrue);
    });

    test('orders newest first', () async {
      final accountId = await seedAccount(1000);

      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 10,
        date: DateTime(2026, 3, 5),
        note: '',
      );
      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 10,
        date: DateTime(2026, 3, 20),
        note: '',
      );

      final march = await dataSource
          .watchTransactionsForMonth(DateTime(2026, 3))
          .first;

      expect(march.first.date, DateTime(2026, 3, 20));
      expect(march.last.date, DateTime(2026, 3, 5));
    });
  });

  group('watchTransactionsInRange', () {
    test(
      'returns transactions spanning multiple months within the range',
      () async {
        final accountId = await seedAccount(1000);

        await dataSource.createTransaction(
          accountId: accountId,
          categoryId: 'cat-1',
          type: TransactionType.expense,
          amount: 10,
          date: DateTime(2026, 1, 15),
          note: 'January',
        );
        await dataSource.createTransaction(
          accountId: accountId,
          categoryId: 'cat-1',
          type: TransactionType.expense,
          amount: 10,
          date: DateTime(2026, 3, 15),
          note: 'March',
        );
        await dataSource.createTransaction(
          accountId: accountId,
          categoryId: 'cat-1',
          type: TransactionType.expense,
          amount: 10,
          date: DateTime(2026, 6, 1),
          note: 'Outside range',
        );

        final results = await dataSource
            .watchTransactionsInRange(
              start: DateTime(2026, 1),
              endExclusive: DateTime(2026, 4),
            )
            .first;

        expect(results, hasLength(2));
        expect(results.map((t) => t.note), containsAll(['January', 'March']));
      },
    );

    test('excludes the endExclusive boundary', () async {
      final accountId = await seedAccount(1000);

      await dataSource.createTransaction(
        accountId: accountId,
        categoryId: 'cat-1',
        type: TransactionType.expense,
        amount: 10,
        date: DateTime(2026, 4),
        note: 'right on the boundary',
      );

      final results = await dataSource
          .watchTransactionsInRange(
            start: DateTime(2026, 1),
            endExclusive: DateTime(2026, 4),
          )
          .first;

      expect(results, isEmpty);
    });
  });
}
