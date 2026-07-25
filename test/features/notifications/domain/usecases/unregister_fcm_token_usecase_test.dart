import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/notifications/domain/repositories/fcm_token_repository.dart';
import 'package:cashly_lao/features/notifications/domain/usecases/unregister_fcm_token_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFcmTokenRepository extends Mock implements FcmTokenRepository {}

void main() {
  late _MockFcmTokenRepository repository;
  late UnregisterFcmTokenUseCase useCase;

  setUp(() {
    repository = _MockFcmTokenRepository();
    useCase = UnregisterFcmTokenUseCase(repository);
  });

  test('delegates to the repository with the given token', () async {
    when(
      () => repository.unregisterToken('token-a'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(token: 'token-a');

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.unregisterToken('token-a')).called(1);
  });
}
