import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/account_type.dart';
import '../repositories/account_repository.dart';

class UpdateAccountUseCase {
  const UpdateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return _repository.updateAccount(
      id: id,
      name: name,
      type: type,
      balance: balance,
      icon: icon,
      color: color,
    );
  }
}
