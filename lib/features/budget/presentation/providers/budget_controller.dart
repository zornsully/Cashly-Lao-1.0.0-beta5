import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import 'budget_providers.dart';

/// Drives the loading/error state for every budget *mutation* (create,
/// update, delete). The list itself comes from [budgetProgressProvider],
/// which updates on its own as Firestore changes.
class BudgetController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> createBudget({
    required String categoryId,
    required DateTime month,
    required double limitAmount,
    required String currencyCode,
  }) async {
    final success = await _run(
      () => ref
          .read(createBudgetUseCaseProvider)
          .call(
            categoryId: categoryId,
            month: month,
            limitAmount: limitAmount,
            currencyCode: currencyCode,
          ),
    );
    if (success) {
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'budget_set');
    }
    return success;
  }

  Future<bool> updateBudget({
    required String id,
    required double limitAmount,
    required String currencyCode,
  }) {
    return _run(
      () => ref
          .read(updateBudgetUseCaseProvider)
          .call(id: id, limitAmount: limitAmount, currencyCode: currencyCode),
    );
  }

  Future<bool> deleteBudget(String id) {
    return _run(() => ref.read(deleteBudgetUseCaseProvider).call(id));
  }

  Future<bool> _run<R>(Future<Either<Failure, R>> Function() action) async {
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
  }
}

final budgetControllerProvider =
    AsyncNotifierProvider.autoDispose<BudgetController, void>(
      BudgetController.new,
    );
