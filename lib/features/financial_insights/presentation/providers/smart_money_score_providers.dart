import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/smart_money_score_remote_datasource.dart';
import '../../data/repositories/smart_money_score_repository_impl.dart';
import '../../domain/entities/smart_money_score.dart';
import '../../domain/repositories/smart_money_score_repository.dart';
import '../../domain/services/smart_money_score_calculator.dart';

final smartMoneyScoreRemoteDataSourceProvider =
    Provider<SmartMoneyScoreRemoteDataSource>((ref) {
      return FirestoreSmartMoneyScoreRemoteDataSource(
        firestore: ref.watch(firestoreProvider),
        firebaseAuth: ref.watch(firebaseAuthProvider),
      );
    });

final smartMoneyScoreRepositoryProvider = Provider<SmartMoneyScoreRepository>(
  (ref) => SmartMoneyScoreRepositoryImpl(
    ref.watch(smartMoneyScoreRemoteDataSourceProvider),
  ),
);

final smartMoneyScoreCalculatorProvider = Provider<SmartMoneyScoreCalculator>((
  ref,
) {
  return const SmartMoneyScoreCalculator();
});

/// Complete per-currency month history, streamed from the shared backend.
/// This is intentionally separate from dashboard rendering so future history
/// or export screens can use the same source of truth.
final smartMoneyScoreHistoryProvider =
    StreamProvider<List<SmartMoneyScoreMonth>>((ref) {
      return ref.watch(smartMoneyScoreRepositoryProvider).watchHistory();
    });
