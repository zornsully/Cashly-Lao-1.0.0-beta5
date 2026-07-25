import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_color_key.dart';
import '../../../../core/constants/app_icon_key.dart';
import '../../../../core/error/failure.dart';
import '../entities/account_entity.dart';
import '../entities/account_type.dart';
import '../repositories/account_repository.dart';

class CreateAccountUseCase {
  const CreateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, AccountEntity>> call({
    required String name,
    required AccountType type,
    required double initialBalance,
    required String currencyCode,
    required AppIconKey icon,
    required AppColorKey color,
  }) {
    return _repository.createAccount(
      name: name,
      type: type,
      initialBalance: initialBalance,
      currencyCode: currencyCode,
      icon: icon,
      color: color,
    );
  }
}
