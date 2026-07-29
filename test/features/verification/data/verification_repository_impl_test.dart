import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/verification/data/datasources/verification_remote_data_source.dart';
import 'package:oshi_log/features/verification/data/dto/verification_dto.dart';
import 'package:oshi_log/features/verification/data/repositories/verification_repository_impl.dart';
import 'package:oshi_log/features/verification/domain/entities/verification_entities.dart';

class MockVerificationRemoteDataSource extends Mock
    implements VerificationRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const VerificationRequestDto());
    registerFallbackValue(
      const VerificationKeyRegisterRequestDto(
        keyId: 'key',
        deviceId: 'device',
        publicKeyJwk: {'kty': 'RSA'},
      ),
    );
  });

  test('verifyPlace forwards token payload to remote data source', () async {
    final remoteDataSource = MockVerificationRemoteDataSource();
    final repository = VerificationRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.verifyPlace(
        projectId: any(named: 'projectId'),
        placeId: any(named: 'placeId'),
        request: any(named: 'request'),
      ),
    ).thenAnswer(
      (_) async => const Result.success(
        VerificationResultDto(placeId: 'place-1', result: 'VERIFIED'),
      ),
    );

    final result = await repository.verifyPlace(
      projectId: 'project-1',
      placeId: 'place-1',
      token: 'token-1',
      verificationMethod: 'AUTO',
    );

    expect(result, isA<Success<VerificationResult>>());

    final capturedRequest =
        verify(
              () => remoteDataSource.verifyPlace(
                projectId: 'project-1',
                placeId: 'place-1',
                request: captureAny(named: 'request'),
              ),
            ).captured.single
            as VerificationRequestDto;

    expect(capturedRequest.token, 'token-1');
    expect(capturedRequest.verificationMethod, 'AUTO');
  });

  test('verifyLiveEvent forwards verificationMethod to remote data source',
      () async {
    final remoteDataSource = MockVerificationRemoteDataSource();
    final repository = VerificationRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.verifyLiveEvent(
        projectId: any(named: 'projectId'),
        liveEventId: any(named: 'liveEventId'),
        request: any(named: 'request'),
      ),
    ).thenAnswer(
      (_) async => const Result.success(
        VerificationResultDto(liveEventId: 'live-1', result: 'RECORDED'),
      ),
    );

    final result = await repository.verifyLiveEvent(
      projectId: 'project-1',
      liveEventId: 'live-1',
      verificationMethod: 'MANUAL',
    );

    expect(result, isA<Success<VerificationResult>>());

    final capturedRequest =
        verify(
              () => remoteDataSource.verifyLiveEvent(
                projectId: 'project-1',
                liveEventId: 'live-1',
                request: captureAny(named: 'request'),
              ),
            ).captured.single
            as VerificationRequestDto;

    expect(capturedRequest.verificationMethod, 'MANUAL');
  });

  test('registerDeviceKey forwards JWK payload to remote data source',
      () async {
    final remoteDataSource = MockVerificationRemoteDataSource();
    final repository = VerificationRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.registerDeviceKey(
        request: any(named: 'request'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        VerificationDeviceKeyDto(
          keyId: 'device-key-1',
          deviceId: 'ios-15-pro-001',
          algorithm: 'RS256',
          isActive: true,
          createdAt: DateTime.parse('2026-02-11T13:10:00+09:00'),
          lastUsedAt: null,
          revokedAt: null,
        ),
      ),
    );

    final result = await repository.registerDeviceKey(
      keyId: 'device-key-1',
      deviceId: 'ios-15-pro-001',
      publicKeyJwk: const {'kty': 'RSA', 'kid': 'device-key-1'},
    );

    expect(result, isA<Success<VerificationDeviceKey>>());

    final capturedRequest =
        verify(
              () => remoteDataSource.registerDeviceKey(
                request: captureAny(named: 'request'),
              ),
            ).captured.single
            as VerificationKeyRegisterRequestDto;

    expect(capturedRequest.keyId, 'device-key-1');
    expect(capturedRequest.deviceId, 'ios-15-pro-001');
    expect(capturedRequest.publicKeyJwk, isNotNull);
    expect(capturedRequest.publicKeyPem, isNull);
  });
}
