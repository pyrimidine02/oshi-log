/// EN: Verification domain entities.
/// KO: 인증 도메인 엔티티.
library;

class VerificationConfig {
  const VerificationConfig({
    required this.jweAlg,
    required this.jwsAlg,
    required this.publicKeys,
    required this.toleranceMeters,
    required this.timeSkewSec,
  });

  final String jweAlg;
  final String jwsAlg;
  final List<String> publicKeys;
  final int toleranceMeters;
  final int timeSkewSec;
}

class VerificationChallenge {
  const VerificationChallenge({required this.nonce, required this.expiresAt});

  final String nonce;
  final DateTime expiresAt;
}

class VerificationResult {
  const VerificationResult({
    required this.result,
    this.placeId,
    this.liveEventId,
  });

  final String result;
  final String? placeId;
  final String? liveEventId;
}

class VerificationDeviceKey {
  const VerificationDeviceKey({
    required this.keyId,
    required this.deviceId,
    required this.algorithm,
    required this.isActive,
    required this.createdAt,
    this.lastUsedAt,
    this.revokedAt,
  });

  final String keyId;
  final String deviceId;
  final String algorithm;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime? revokedAt;
}
