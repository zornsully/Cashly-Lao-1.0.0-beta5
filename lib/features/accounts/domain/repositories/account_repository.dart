import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/account_entity.dart';
import '../entities/account_type.dart';

abstract interface class AccountRepository {
  /// Emits the user's accounts every time Firestore's copy changes.
  /// Archived accounts are filtered out unless [includeArchived] is true.
  Stream<List<AccountEntity>> watchAccounts({bool includeArchived = false});

  Future<Either<Failure, AccountEntity>> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<Either<Failure, Unit>> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  });

  Future<Either<Failure, Unit>> archiveAccount(String id);

  Future<Either<Failure, Unit>> unarchiveAccount(String id);

  Future<Either<Failure, Unit>> deleteAccount(String id);
}
