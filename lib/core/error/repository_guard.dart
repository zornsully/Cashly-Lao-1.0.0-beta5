import 'package:fpdart/fpdart.dart';

import 'exceptions.dart';
import 'failure.dart';

/// Shared try/catch → [Either] translation for repository implementations.
/// Every feature's `*RepositoryImpl` mixes this in instead of hand-rolling
/// the same `AuthException`/`ServerException`/catch-all mapping.
mixin RepositoryGuard {
  Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, Unit>> guardUnit(Future<void> Function() action) {
    return guard(() async {
      await action();
      return unit;
    });
  }
}
