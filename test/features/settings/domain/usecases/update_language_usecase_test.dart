import 'package:cashly_lao/core/constants/app_language.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:cashly_lao/features/settings/domain/usecases/update_language_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  late _MockUserPreferencesRepository repository;
  late UpdateLanguageUseCase useCase;

  setUp(() {
    repository = _MockUserPreferencesRepository();
    useCase = UpdateLanguageUseCase(repository);
  });

  test('delegates to the repository and returns its result', () async {
    when(
      () => repository.updateLanguage(AppLanguage.lao),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(AppLanguage.lao);

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.updateLanguage(AppLanguage.lao)).called(1);
  });
}
