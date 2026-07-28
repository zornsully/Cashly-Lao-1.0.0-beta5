import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/notifications/domain/repositories/fcm_token_repository.dart';
import 'package:cashly_lao/features/notifications/domain/usecases/register_fcm_token_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFcmTokenRepository extends Mock implements FcmTokenRepository {}

void main() {
  late _MockFcmTokenRepository repository;
  late RegisterFcmTokenUseCase useCase;

  setUp(() {
    repository = _MockFcmTokenRepository();
    useCase = RegisterFcmTokenUseCase(repository);
  });

  test(
    'delegates to the repository with the given token and platform',
    () async {
      when(
        () => repository.registerToken(token: 'token-a', platform: 'android'),
      ).thenAnswer((_) async => const Right(unit));

      final result = await useCase(token: 'token-a', platform: 'android');

      expect(result, const Right<Failure, Unit>(unit));
      verify(
        () => repository.registerToken(token: 'token-a', platform: 'android'),
      ).called(1);
    },
  );
}
