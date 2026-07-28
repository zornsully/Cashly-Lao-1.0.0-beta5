import 'package:cashly_lao/core/error/exceptions.dart';
import 'package:cashly_lao/core/error/failure.dart';
import 'package:cashly_lao/features/notifications/data/datasources/fcm_token_remote_datasource.dart';
import 'package:cashly_lao/features/notifications/data/repositories/fcm_token_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFcmTokenRemoteDataSource extends Mock
    implements FcmTokenRemoteDataSource {}

void main() {
  late _MockFcmTokenRemoteDataSource dataSource;
  late FcmTokenRepositoryImpl repository;

  setUp(() {
    dataSource = _MockFcmTokenRemoteDataSource();
    repository = FcmTokenRepositoryImpl(dataSource);
  });

  test('registerToken returns Right(unit) on success', () async {
    when(
      () => dataSource.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.registerToken(
      token: 'token-a',
      platform: 'android',
    );

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('registerToken maps ServerException to Left(ServerFailure)', () async {
    when(
      () => dataSource.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenThrow(const ServerException('Could not register this device.'));

    final result = await repository.registerToken(
      token: 'token-a',
      platform: 'android',
    );

    expect(
      result,
      const Left<Failure, Unit>(
        ServerFailure('Could not register this device.'),
      ),
    );
  });

  test('unregisterToken returns Right(unit) on success', () async {
    when(() => dataSource.unregisterToken('token-a')).thenAnswer((_) async {});

    final result = await repository.unregisterToken('token-a');

    expect(result, const Right<Failure, Unit>(unit));
  });
}
