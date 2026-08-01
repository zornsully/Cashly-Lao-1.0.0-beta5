import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../domain/entities/transaction_type.dart';
import 'transaction_providers.dart';

/// Drives the loading/error state for every transaction *mutation*
/// (create, update, delete). The list itself comes from
/// [transactionsProvider], which updates on its own as Firestore changes.
class TransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> createTransaction({
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) async {
    final success = await _run(
      () => ref
          .read(createTransactionUseCaseProvider)
          .call(
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            toAccountId: toAccountId,
            amount: amount,
            date: date,
            note: note,
          ),
    );
    if (success) {
      logAnalyticsEvent(
        () => ref.read(analyticsProvider),
        'transaction_created',
        {'transaction_type': type.name},
      );
    }
    return success;
  }

  Future<bool> updateTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
    String? categoryId,
    String? toAccountId,
  }) {
    return _run(
      () => ref
          .read(updateTransactionUseCaseProvider)
          .call(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            toAccountId: toAccountId,
            amount: amount,
            date: date,
            note: note,
          ),
    );
  }

  Future<bool> deleteTransaction(String id) {
    return _run(() => ref.read(deleteTransactionUseCaseProvider).call(id));
  }

  Future<bool> _run<R>(Future<Either<Failure, R>> Function() action) async {
    // This provider is `autoDispose`, but every call site invokes it via
    // `ref.read(...).notifier` (e.g. a popup-menu delete action) rather
    // than `ref.watch`, so nothing keeps it alive for the duration of the
    // mutation. Without this, Riverpod is free to dispose the provider
    // while `action()` is still in flight, and the final `state = ...`
    // write below throws `UnmountedRefException` -- after the underlying
    // Firestore write already succeeded, so the mutation itself isn't
    // lost, but the caller's success/failure branch (including the
    // failure snackbar) never runs. Pinning it alive for exactly this
    // call's duration, then releasing the pin, fixes that without
    // changing this controller's disposal behavior otherwise.
    final keepAliveLink = ref.keepAlive();
    try {
      state = const AsyncLoading();
      final result = await action();
      return result.match(
        (failure) {
          state = AsyncError<void>(failure, StackTrace.current);
          return false;
        },
        (_) {
          state = const AsyncData(null);
          return true;
        },
      );
    } finally {
      keepAliveLink.close();
    }
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider.autoDispose<TransactionController, void>(
      TransactionController.new,
    );
