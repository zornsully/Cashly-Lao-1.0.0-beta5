import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/error/failure.dart';
import '../repositories/user_preferences_repository.dart';

class UpdateLanguageUseCase {
  const UpdateLanguageUseCase(this._repository);

  final UserPreferencesRepository _repository;

  Future<Either<Failure, Unit>> call(AppLanguage language) {
    return _repository.updateLanguage(language);
  }
}
