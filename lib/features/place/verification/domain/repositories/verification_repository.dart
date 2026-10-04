/// EN: Verification repository interface.
/// KO: 인증 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/place/verification/domain/entities/verification_entities.dart';

abstract class VerificationRepository {
  Future<Result<VerificationConfig>> getConfig();

  Future<Result<VerificationChallenge>> getChallenge();

  Future<Result<VerificationResult>> verifyPlace({
    required String projectId,
    required String placeId,
    String? token,
    String? verificationMethod,
    String? evidence,
  });

  Future<Result<VerificationResult>> verifyLiveEvent({
    required String projectId,
    required String liveEventId,
    String? token,
    String? verificationMethod,
    String? evidence,
  });

  Future<Result<VerificationDeviceKey>> registerDeviceKey({
    required String keyId,
    required String deviceId,
    Map<String, dynamic>? publicKeyJwk,
    String? publicKeyPem,
  });
}
