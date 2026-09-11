/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/verification_dto.dart';
import '../../domain/entities/verification_entities.dart';

extension VerificationConfigDtoDomainMapper on VerificationConfigDto {
  VerificationConfig toDomain() {
    final dto = this;

    return VerificationConfig(
      jweAlg: dto.jweAlg,
      jwsAlg: dto.jwsAlg,
      publicKeys: List.unmodifiable(dto.publicKeys),
      toleranceMeters: dto.toleranceMeters,
      timeSkewSec: dto.timeSkewSec,
    );
  }
}

extension VerificationChallengeDtoDomainMapper on VerificationChallengeDto {
  VerificationChallenge toDomain() {
    final dto = this;

    return VerificationChallenge(nonce: dto.nonce, expiresAt: dto.expiresAt);
  }
}

extension VerificationResultDtoDomainMapper on VerificationResultDto {
  VerificationResult toDomain() {
    final dto = this;

    return VerificationResult(
      result: dto.result,
      placeId: dto.placeId,
      liveEventId: dto.liveEventId,
    );
  }
}

extension VerificationDeviceKeyDtoDomainMapper on VerificationDeviceKeyDto {
  VerificationDeviceKey toDomain() {
    final dto = this;

    return VerificationDeviceKey(
      keyId: dto.keyId,
      deviceId: dto.deviceId,
      algorithm: dto.algorithm,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      lastUsedAt: dto.lastUsedAt,
      revokedAt: dto.revokedAt,
    );
  }
}
