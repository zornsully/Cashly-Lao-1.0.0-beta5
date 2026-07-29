import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl with RepositoryGuard implements AccountRepository {
  const AccountRepositoryImpl(this._remoteDataSource);

  final AccountRemoteDataSource _remoteDataSource;

  @override
  Stream<List<AccountEntity>> watchAccounts({bool includeArchived = false}) {
    return _remoteDataSource.watchAccounts().map(
      (accounts) => includeArchived
          ? accounts
          : accounts.where((account) => !account.isArchived).toList(),
    );
  }

  @override
  Future<Either<Failure, AccountEntity>> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return guard(
      () => _remoteDataSource.createAccount(
        name: name,
        type: type,
        initialBalance: initialBalance,
        currencyCode: currencyCode,
        icon: icon,
        color: color,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return guardUnit(
      () => _remoteDataSource.updateAccount(
        id: id,
        name: name,
        type: type,
        balance: balance,
        icon: icon,
        color: color,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> archiveAccount(String id) {
    return guardUnit(() => _remoteDataSource.archiveAccount(id));
  }

  @override
  Future<Either<Failure, Unit>> unarchiveAccount(String id) {
    return guardUnit(() => _remoteDataSource.unarchiveAccount(id));
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount(String id) {
    return guardUnit(() => _remoteDataSource.deleteAccount(id));
  }
}
