import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/domain/usecases/login_usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  final user = UserEntity(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: true,
    createdAt: DateTime(2026),
  );

  test('returns the user on successful login', () async {
    when(
      () => repository.login(email: 'user@example.com', password: 'Str0ngPass'),
    ).thenAnswer((_) async => Right(user));

    final result = await useCase(
      email: 'user@example.com',
      password: 'Str0ngPass',
    );

    expect(result, Right<Failure, UserEntity>(user));
    verify(
      () => repository.login(email: 'user@example.com', password: 'Str0ngPass'),
    ).called(1);
  });

  test('propagates a failure from the repository', () async {
    const failure = AuthFailure('Incorrect email or password.');
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(email: 'user@example.com', password: 'wrong');

    expect(result, const Left<Failure, UserEntity>(failure));
  });
}
