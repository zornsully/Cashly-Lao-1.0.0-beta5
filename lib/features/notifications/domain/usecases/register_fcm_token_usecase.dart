import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/fcm_token_repository.dart';

class RegisterFcmTokenUseCase {
  const RegisterFcmTokenUseCase(this._repository);

  final FcmTokenRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String token,
    required String platform,
  }) {
    return _repository.registerToken(token: token, platform: platform);
  }
}
