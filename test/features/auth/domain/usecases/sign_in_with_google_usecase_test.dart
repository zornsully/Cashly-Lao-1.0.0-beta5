import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignInWithGoogleUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = SignInWithGoogleUseCase(repository);
  });

  final user = UserEntity(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: true,
    createdAt: DateTime(2026),
    providerIds: const ['google.com'],
  );

  test('returns the user on successful Google sign-in', () async {
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => Right(user));

    final result = await useCase();

    expect(result, Right<Failure, UserEntity>(user));
    verify(() => repository.signInWithGoogle()).called(1);
  });

  test('propagates a failure from the repository', () async {
    const failure = AuthFailure(
      'Sign-in was cancelled.',
      code: 'google-sign-in-cancelled',
    );
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left<Failure, UserEntity>(failure));
  });
}
