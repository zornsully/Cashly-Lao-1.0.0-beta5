import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/user_preferences_repository.dart';

class UpdateAppLockEnabledUseCase {
  const UpdateAppLockEnabledUseCase(this._repository);

  final UserPreferencesRepository _repository;

  Future<Either<Failure, Unit>> call(bool enabled) {
    return _repository.updateAppLockEnabled(enabled);
  }
}
