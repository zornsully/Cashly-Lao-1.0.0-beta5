import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/user_preferences_repository.dart';

class UpdateDefaultCurrencyUseCase {
  const UpdateDefaultCurrencyUseCase(this._repository);

  final UserPreferencesRepository _repository;

  Future<Either<Failure, Unit>> call(String currencyCode) {
    return _repository.updateDefaultCurrency(currencyCode);
  }
}
