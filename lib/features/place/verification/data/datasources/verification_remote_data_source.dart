/// EN: Remote data source for verification APIs.
/// KO: 인증 API 원격 데이터 소스.
library;

import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/place/verification/data/dto/verification_dto.dart';

class VerificationRemoteDataSource {
  VerificationRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<VerificationConfigDto>> fetchConfig() {
    return _apiClient.get<VerificationConfigDto>(
      ApiEndpoints.verificationConfig,
      fromJson: (json) =>
          VerificationConfigDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<VerificationChallengeDto>> fetchChallenge() {
    return _apiClient.get<VerificationChallengeDto>(
      ApiEndpoints.verificationChallenge,
      fromJson: (json) =>
          VerificationChallengeDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<VerificationResultDto>> verifyPlace({
    required String projectId,
    required String placeId,
    required VerificationRequestDto request,
  }) {
    return _apiClient.post<VerificationResultDto>(
      ApiEndpoints.placeVerification(projectId, placeId),
      data: request.toJson(),
      fromJson: (json) =>
          VerificationResultDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<VerificationResultDto>> verifyLiveEvent({
    required String projectId,
    required String liveEventId,
    required VerificationRequestDto request,
  }) {
    return _apiClient.post<VerificationResultDto>(
      ApiEndpoints.liveEventVerification(projectId, liveEventId),
      data: request.toJson(),
      fromJson: (json) =>
          VerificationResultDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<VerificationDeviceKeyDto>> registerDeviceKey({
    required VerificationKeyRegisterRequestDto request,
  }) {
    return _apiClient.post<VerificationDeviceKeyDto>(
      ApiEndpoints.verificationKeys,
      data: request.toJson(),
      fromJson: (json) =>
          VerificationDeviceKeyDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
