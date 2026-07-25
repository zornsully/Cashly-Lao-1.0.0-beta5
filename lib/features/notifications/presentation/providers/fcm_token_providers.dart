import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/fcm_token_remote_datasource.dart';
import '../../data/repositories/fcm_token_repository_impl.dart';
import '../../domain/repositories/fcm_token_repository.dart';
import '../../domain/usecases/register_fcm_token_usecase.dart';
import '../../domain/usecases/unregister_fcm_token_usecase.dart';

final fcmTokenRemoteDataSourceProvider = Provider<FcmTokenRemoteDataSource>((ref) {
  return FirestoreFcmTokenRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  return FcmTokenRepositoryImpl(ref.watch(fcmTokenRemoteDataSourceProvider));
});

final registerFcmTokenUseCaseProvider = Provider<RegisterFcmTokenUseCase>((ref) {
  return RegisterFcmTokenUseCase(ref.watch(fcmTokenRepositoryProvider));
});

final unregisterFcmTokenUseCaseProvider = Provider<UnregisterFcmTokenUseCase>((ref) {
  return UnregisterFcmTokenUseCase(ref.watch(fcmTokenRepositoryProvider));
});
