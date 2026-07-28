import 'package:cashly_lao/features/auth/domain/repositories/auth_repository.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_controller.dart';
import 'package:cashly_lao/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

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
}
