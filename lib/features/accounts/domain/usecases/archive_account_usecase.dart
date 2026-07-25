import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/account_repository.dart';

class ArchiveAccountUseCase {
  const ArchiveAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.archiveAccount(id);
  }
}
