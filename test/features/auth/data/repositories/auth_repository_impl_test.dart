import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cashly_lao/features/auth/data/models/user_model.dart';
import 'package:cashly_lao/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockAuthRemoteDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource);
  });

  final userModel = UserModel(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: false,
    createdAt: DateTime(2026),
    displayName: 'Somchai',
  );

  group('login', () {
    test('returns Right(user) on success', () async {
      when(
        () =>
            dataSource.login(email: 'user@example.com', password: 'Str0ngPass'),
      ).thenAnswer((_) async => userModel);

      final result = await repository.login(
        email: 'user@example.com',
        password: 'Str0ngPass',
      );

      expect(result, Right(userModel));
    });

    test('maps AuthException to Left(AuthFailure)', () async {
      when(
        () => dataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          'Incorrect email or password.',
          code: 'invalid-credential',
        ),
      );

      final result = await repository.login(
        email: 'user@example.com',
        password: 'bad',
      );

      expect(
        result,
        const Left<Failure, dynamic>(
          AuthFailure(
            'Incorrect email or password.',
            code: 'invalid-credential',
          ),
        ),
      );
    });

    test('maps unexpected errors to Left(UnknownFailure)', () async {
      when(
        () => dataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('boom'));

      final result = await repository.login(
        email: 'user@example.com',
        password: 'bad',
      );

      expect(result, const Left<Failure, dynamic>(UnknownFailure()));
    });
  });

  group('register', () {
    test('maps ServerException to Left(ServerFailure)', () async {
      when(
        () => dataSource.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenThrow(
        const ServerException('Could not create your profile record.'),
      );

      final result = await repository.register(
        email: 'user@example.com',
        password: 'Str0ngPass',
        displayName: 'Somchai',
      );

      expect(
        result,
        const Left<Failure, dynamic>(
          ServerFailure('Could not create your profile record.'),
        ),
      );
    });
  });

  group('signInWithGoogle', () {
    test('returns Right(user) on success', () async {
      when(
        () => dataSource.signInWithGoogle(),
      ).thenAnswer((_) async => userModel);

      final result = await repository.signInWithGoogle();

      expect(result, Right(userModel));
    });

    test('maps a cancelled sign-in to Left(AuthFailure)', () async {
      when(() => dataSource.signInWithGoogle()).thenThrow(
        const AuthException(
          'Sign-in was cancelled.',
          code: 'google-sign-in-cancelled',
        ),
      );

      final result = await repository.signInWithGoogle();

      expect(
        result,
        const Left<Failure, dynamic>(
          AuthFailure(
            'Sign-in was cancelled.',
            code: 'google-sign-in-cancelled',
          ),
        ),
      );
    });
  });

  group('logout', () {
    test('returns Right(unit) on success', () async {
      when(() => dataSource.logout()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => dataSource.logout()).called(1);
    });
  });

  group('updateDisplayName', () {
    test('returns Right(unit) on success', () async {
      when(
        () => dataSource.updateDisplayName('New Name'),
      ).thenAnswer((_) async {});

      final result = await repository.updateDisplayName('New Name');

      expect(result, const Right<Failure, Unit>(unit));
    });
  });

  group('deleteAccount', () {
    test('returns Right(unit) on success', () async {
      when(
        () => dataSource.deleteAccount(password: 'correct-password'),
      ).thenAnswer((_) async {});

      final result = await repository.deleteAccount(
        password: 'correct-password',
      );

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('maps AuthException to Left(AuthFailure)', () async {
      when(
        () => dataSource.deleteAccount(password: any(named: 'password')),
      ).thenThrow(
        const AuthException(
          'Please sign in again to complete this action.',
          code: 'wrong-password',
        ),
      );

      final result = await repository.deleteAccount(password: 'wrong');

      expect(
        result,
        const Left<Failure, dynamic>(
          AuthFailure(
            'Please sign in again to complete this action.',
            code: 'wrong-password',
          ),
        ),
      );
    });
  });
}
