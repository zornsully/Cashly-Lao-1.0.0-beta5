import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/account_repository.dart';

class UnarchiveAccountUseCase {
  const UnarchiveAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.unarchiveAccount(id);
  }
}
