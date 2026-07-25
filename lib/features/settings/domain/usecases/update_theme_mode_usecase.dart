import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_theme_mode.dart';
import '../../../../core/error/failure.dart';
import '../repositories/user_preferences_repository.dart';

class UpdateThemeModeUseCase {
  const UpdateThemeModeUseCase(this._repository);

  final UserPreferencesRepository _repository;

  Future<Either<Failure, Unit>> call(AppThemeModePreference mode) {
    return _repository.updateThemeMode(mode);
  }
}
