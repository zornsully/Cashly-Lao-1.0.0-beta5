import 'package:cashly_lao/core/providers/firebase_providers.dart';
import 'package:cashly_lao/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cashly_lao/features/auth/data/models/user_model.dart';
import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_controller.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

final _fixtureUser = UserEntity(
  uid: 'uid-1',
  email: 'user@example.com',
  emailVerified: true,
  createdAt: DateTime(2026),
);

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('starts ready before any auth action is requested', () {
    expect(container.read(authControllerProvider).isLoading, isFalse);
  });

  // Regression guard for the same class of bug the Analytics safety net hit
  // earlier: reading a Firebase-SDK-level provider (messagingProvider, here
  // via the FCM unregister step) can throw *synchronously during provider
  // construction*, before any surrounding try/catch in the same call has a
  // chance to run. logout() must still succeed in a test environment with
  // no Firebase app initialized and none of the FCM providers overridden —
  // exactly the scenario a real widget test exercises today.
  test('logout succeeds even though no Firebase app is initialized for the '
      'FCM token unregister step', () async {
    when(() => repository.logout()).thenAnswer((_) async => const Right(unit));

    final result = await container
        .read(authControllerProvider.notifier)
        .logout();

    expect(result, isTrue);
    verify(() => repository.logout()).called(1);
  });

  // Regression guard for a real production bug: `_run()`'s try block only
  // ever caught TimeoutException, so any other exception thrown while
  // evaluating `action()` -- most plausibly a provider dependency of the
  // use case (like authRepositoryProvider) throwing during construction,
  // exactly the same class of bug the FCM test above already covers for a
  // different provider -- escaped `_run()` uncaught and left `state`
  // parked at AsyncLoading() forever, permanently disabling every login
  // control on the screen with no way to recover short of a page reload.
  test('login recovers to an error state instead of staying stuck when its '
      'use-case provider throws during construction', () async {
    final brokenContainer = ProviderContainer(
      overrides: [
        loginUseCaseProvider.overrideWith(
          (ref) => throw StateError('simulated provider construction failure'),
        ),
      ],
    );
    addTearDown(brokenContainer.dispose);

    final result = await brokenContainer
        .read(authControllerProvider.notifier)
        .login(email: 'user@example.com', password: 'Str0ngPass');

    expect(result, isFalse);
    final state = brokenContainer.read(authControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isTrue);
  });

  // Regression guard for https://github.com/firebase/flutterfire/issues/18548:
  // a bare TypeError escaping the repository (the signature of that upstream
  // bug on web) should be retried once, transparently, instead of surfacing
  // as a user-facing error on the first occurrence.
  test('login retries once and succeeds when the repository throws a bare '
      'TypeError on the first attempt', () async {
    var callCount = 0;
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) throw TypeError();
      return Right(_fixtureUser);
    });

    final result = await container
        .read(authControllerProvider.notifier)
        .login(email: 'user@example.com', password: 'Str0ngPass');

    expect(result, isTrue);
    expect(callCount, 2);
    final state = container.read(authControllerProvider);
    expect(state.hasError, isFalse);
  });

  test('login still recovers to an error state (not stuck) when the TypeError '
      'persists after the retry', () async {
    var callCount = 0;
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      throw TypeError();
    });

    final result = await container
        .read(authControllerProvider.notifier)
        .login(email: 'user@example.com', password: 'Str0ngPass');

    expect(result, isFalse);
    expect(callCount, 2);
    final state = container.read(authControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isTrue);
  });

  test(
    'login does not retry a non-TypeError exception from the repository',
    () async {
      var callCount = 0;
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        throw StateError('not a TypeError');
      });

      final result = await container
          .read(authControllerProvider.notifier)
          .login(email: 'user@example.com', password: 'Str0ngPass');

      expect(result, isFalse);
      expect(callCount, 1);
    },
  );

  // Documents the exact Riverpod mechanic that makes a plain retry
  // insufficient on its own: a `Provider` that throws during construction
  // caches that error forever, so re-reading it (without invalidating
  // first) just rethrows the same cached failure instead of ever calling
  // `create` again.
  test('a plain Provider that throws during construction stays in that error '
      'state until invalidated', () {
    var buildCount = 0;
    final flaky = Provider<int>((ref) {
      buildCount++;
      if (buildCount == 1) throw TypeError();
      return 42;
    });
    final isolatedContainer = ProviderContainer();
    addTearDown(isolatedContainer.dispose);

    // Riverpod always surfaces a failed build as a `ProviderException`
    // wrapping the original error, even on the very first read.
    expect(() => isolatedContainer.read(flaky), throwsA(isA<Object>()));
    expect(buildCount, 1);
    // Reading again *without* invalidating returns the cached failure --
    // `create` is not re-invoked (buildCount stays at 1).
    expect(() => isolatedContainer.read(flaky), throwsA(isA<Object>()));
    expect(buildCount, 1);

    isolatedContainer.invalidate(flaky);

    expect(isolatedContainer.read(flaky), 42);
    expect(buildCount, 2);
  });

  // Regression guard for the real production scenario behind
  // flutterfire#18548: it's `firebaseAuthProvider` itself (not the
  // repository) that fails on its first read. Proves AuthController's
  // retry invalidates it (and the real `ref.watch` chain down through
  // authRemoteDataSourceProvider/authRepositoryProvider/
  // loginUseCaseProvider) rather than just re-reading the same cached
  // failure.
  test('login recovers when firebaseAuthProvider itself -- not the repository '
      '-- is the provider that throws on first read', () async {
    var authBuildCount = 0;
    final dataSource = _MockAuthRemoteDataSource();
    when(
      () => dataSource.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => UserModel(
        uid: 'uid-1',
        email: 'user@example.com',
        emailVerified: true,
        createdAt: DateTime(2026),
      ),
    );

    final chainContainer = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWith((ref) {
          authBuildCount++;
          if (authBuildCount == 1) throw TypeError();
          return _MockFirebaseAuth();
        }),
        // Mocks only the Firebase-SDK boundary; keeps the real
        // `ref.watch(firebaseAuthProvider)` dependency edge so
        // invalidation really does cascade through this provider.
        authRemoteDataSourceProvider.overrideWith((ref) {
          ref.watch(firebaseAuthProvider);
          return dataSource;
        }),
      ],
    );
    addTearDown(chainContainer.dispose);

    final result = await chainContainer
        .read(authControllerProvider.notifier)
        .login(email: 'user@example.com', password: 'Str0ngPass');

    expect(result, isTrue);
    expect(authBuildCount, 2);
  });
}
