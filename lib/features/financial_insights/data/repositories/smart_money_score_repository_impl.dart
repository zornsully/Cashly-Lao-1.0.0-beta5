import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/repository_guard.dart';
import '../../domain/entities/smart_money_score.dart';
import '../../domain/repositories/smart_money_score_repository.dart';
import '../datasources/smart_money_score_remote_datasource.dart';

class SmartMoneyScoreRepositoryImpl
    with RepositoryGuard
    implements SmartMoneyScoreRepository {
  const SmartMoneyScoreRepositoryImpl(this._remoteDataSource);

  final SmartMoneyScoreRemoteDataSource _remoteDataSource;

  @override
  Stream<List<SmartMoneyScoreMonth>> watchHistory() =>
      _remoteDataSource.watchHistory();

  @override
  Future<Either<Failure, SmartMoneyScoreMonth>> ensureMonthlyOpening(
    SmartMoneyScoreOpening candidate,
  ) => guard(() => _remoteDataSource.ensureMonthlyOpening(candidate));

  @override
  Future<Either<Failure, Unit>> saveMonthlyCalculation({
    required SmartMoneyScoreMonth month,
    required SmartMoneyScoreCalculation calculation,
  }) => guardUnit(
    () => _remoteDataSource.saveMonthlyCalculation(
      month: month,
      calculation: calculation,
    ),
  );
}
