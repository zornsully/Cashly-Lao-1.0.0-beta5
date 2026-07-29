import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/analytics_logger.dart';
import '../../domain/entities/account_type.dart';
import 'account_providers.dart';

/// Drives the loading/error state for every account *mutation* (create,
/// update, archive, unarchive, delete). The accounts list itself comes
/// from [accountsProvider], which updates on its own as Firestore changes
/// — this controller only reports whether the in-flight action succeeded.
class AccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Failure? get failure => switch (state) {
    AsyncError(:final error) when error is Failure => error,
    _ => null,
  };

  Future<bool> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  }) async {
    final success = await _run(
      () => ref
          .read(createAccountUseCaseProvider)
          .call(
            name: name,
            type: type,
            initialBalance: initialBalance,
            currencyCode: currencyCode,
            icon: icon,
            color: color,
          ),
    );
    if (success) {
      logAnalyticsEvent(() => ref.read(analyticsProvider), 'account_created', {
        'account_type': type.name,
      });
    }
    return success;
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return _run(
      () => ref
          .read(updateAccountUseCaseProvider)
          .call(
            id: id,
            name: name,
            type: type,
            balance: balance,
            icon: icon,
            color: color,
          ),
    );
  }

  Future<bool> archiveAccount(String id) {
    return _run(() => ref.read(archiveAccountUseCaseProvider).call(id));
  }

  Future<bool> unarchiveAccount(String id) {
    return _run(() => ref.read(unarchiveAccountUseCaseProvider).call(id));
  }

  Future<bool> deleteAccount(String id) {
    return _run(() => ref.read(deleteAccountUseCaseProvider).call(id));
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

final accountControllerProvider =
    AsyncNotifierProvider.autoDispose<AccountController, void>(
      AccountController.new,
    );
