import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

/// Named `DeleteUserAccountUseCase` rather than `DeleteAccountUseCase` to
/// avoid colliding with the unrelated financial-account deletion usecase
/// in `features/accounts` — this one deletes the signed-in user's profile
/// and all of their data, not a single `AccountEntity`.
class DeleteUserAccountUseCase {
  const DeleteUserAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call({String? password}) {
    return _repository.deleteAccount(password: password);
  }
}
