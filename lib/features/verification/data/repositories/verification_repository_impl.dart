/// EN: Verification repository implementation.
/// KO: 인증 리포지토리 구현.
library;

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/verification_entities.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_remote_data_source.dart';
import '../dto/verification_dto.dart';
import '../mappers/verification_entities_mappers.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl({
    required VerificationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final VerificationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<VerificationConfig>> getConfig() async {
    try {
      final result = await _remoteDataSource.fetchConfig();

      if (result is Success<VerificationConfigDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<VerificationConfigDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown verification config result',
          code: 'unknown_verification_config',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<VerificationChallenge>> getChallenge() async {
    try {
      final result = await _remoteDataSource.fetchChallenge();

      if (result is Success<VerificationChallengeDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<VerificationChallengeDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown verification challenge result',
          code: 'unknown_verification_challenge',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<VerificationResult>> verifyPlace({
    required String projectId,
    required String placeId,
    String? token,
    String? verificationMethod,
    String? evidence,
  }) async {
    try {
      final request = _buildRequest(
        token: token,
        verificationMethod: verificationMethod,
        evidence: evidence,
      );
      final result = await _remoteDataSource.verifyPlace(
        projectId: projectId,
        placeId: placeId,
        request: request,
      );

      if (result is Success<VerificationResultDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<VerificationResultDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown place verification result',
          code: 'unknown_place_verification',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<VerificationResult>> verifyLiveEvent({
    required String projectId,
    required String liveEventId,
    String? verificationMethod,
    String? token,
    String? evidence,
  }) async {
    try {
      final request = _buildRequest(
        token: token,
        verificationMethod: verificationMethod,
        evidence: evidence,
      );
      final result = await _remoteDataSource.verifyLiveEvent(
        projectId: projectId,
        liveEventId: liveEventId,
        request: request,
      );

      if (result is Success<VerificationResultDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<VerificationResultDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown live event verification result',
          code: 'unknown_live_event_verification',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<VerificationDeviceKey>> registerDeviceKey({
    required String keyId,
    required String deviceId,
    Map<String, dynamic>? publicKeyJwk,
    String? publicKeyPem,
  }) async {
    try {
      final request = VerificationKeyRegisterRequestDto(
        keyId: keyId,
        deviceId: deviceId,
        publicKeyJwk: publicKeyJwk,
        publicKeyPem: publicKeyPem,
      );
      final result = await _remoteDataSource.registerDeviceKey(
        request: request,
      );

      if (result is Success<VerificationDeviceKeyDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<VerificationDeviceKeyDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown device key registration result',
          code: 'unknown_device_key_registration',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  VerificationRequestDto _buildRequest({
    String? token,
    String? verificationMethod,
    String? evidence,
  }) {
    return VerificationRequestDto(
      token: token,
      verificationMethod: verificationMethod,
      evidence: evidence,
    );
  }
}
