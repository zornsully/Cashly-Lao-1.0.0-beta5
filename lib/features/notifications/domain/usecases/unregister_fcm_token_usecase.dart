import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/fcm_token_repository.dart';

class UnregisterFcmTokenUseCase {
  const UnregisterFcmTokenUseCase(this._repository);

  final FcmTokenRepository _repository;

  Future<Either<Failure, Unit>> call({required String token}) {
    return _repository.unregisterToken(token);
  }
}
