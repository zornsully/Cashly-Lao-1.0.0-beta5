import 'package:cashly_lao/features/auth/domain/entities/user_entity.dart';
import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_controller.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
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
}
