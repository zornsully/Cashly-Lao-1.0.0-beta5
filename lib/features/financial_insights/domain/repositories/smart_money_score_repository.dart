import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/smart_money_score.dart';

/// Shared persistence boundary for Smart Money Score history.
///
/// A Firestore implementation keeps the opening baseline in the user's
/// backend rather than on one device. The interface stays platform-neutral so
/// future server-authoritative scoring can replace the client implementation
/// without changing dashboard consumers.
abstract interface class SmartMoneyScoreRepository {
  Stream<List<SmartMoneyScoreMonth>> watchHistory();

  /// Creates the deterministic monthly record only if it does not already
  /// exist, returning the original opening when another device won the race.
  Future<Either<Failure, SmartMoneyScoreMonth>> ensureMonthlyOpening(
    SmartMoneyScoreOpening candidate,
  );

  /// Persists the most recent explainable calculation without changing the
  /// opening baseline or historical month identity.
  Future<Either<Failure, Unit>> saveMonthlyCalculation({
    required SmartMoneyScoreMonth month,
    required SmartMoneyScoreCalculation calculation,
  });
}
