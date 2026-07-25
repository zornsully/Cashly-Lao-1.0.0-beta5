import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class UpdateDisplayNameUseCase {
  const UpdateDisplayNameUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String displayName) {
    return _repository.updateDisplayName(displayName);
  }
}
