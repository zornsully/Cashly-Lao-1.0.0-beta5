import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/domain/usecases/delete_user_account_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late DeleteUserAccountUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = DeleteUserAccountUseCase(repository);
  });

  test('delegates to the repository and returns its result', () async {
    when(
      () => repository.deleteAccount(password: 'correct-password'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(password: 'correct-password');

    expect(result, const Right<Failure, Unit>(unit));
  });
}
