/// EN: Verification device key service for JWS signing.
/// KO: JWS 서명을 위한 인증 디바이스 키 서비스.
library;

import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:jose/jose.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';
import 'package:oshi_log/features/place/verification/domain/repositories/verification_repository.dart';

/// EN: In-memory representation of a verification signing key.
/// KO: 인증 서명 키의 메모리 표현.
class VerificationSigningKey {
  const VerificationSigningKey({
    required this.keyId,
    required this.deviceId,
    required this.privateKey,
  });

  final String keyId;
  final String deviceId;
  final JsonWebKey privateKey;
}

/// EN: Handles device key creation, storage, and registration.
/// KO: 디바이스 키 생성, 저장, 등록을 담당합니다.
class VerificationKeyService {
  VerificationKeyService(this._repository, this._secureStorage);

  final VerificationRepository _repository;
  final SecureStorage _secureStorage;

  /// EN: Ensures a signing key exists and is registered with the backend.
  ///     On 400 (ValidationFailure) from registration, clears stale keys
  ///     and retries once with a freshly generated key.
  /// KO: 서명 키가 존재하고 백엔드에 등록되었는지 확인합니다.
  ///     등록 시 400(ValidationFailure)이 오면 오래된 키를 삭제하고
  ///     새 키로 한 번 재시도합니다.
  Future<VerificationSigningKey> ensureSigningKey({
    required String jwsAlg,
  }) async {
    try {
      return await _tryBuildAndRegisterKey(jwsAlg: jwsAlg);
    } catch (e) {
      // EN: 400 on key registration means the stored key is stale — reset and retry once.
      // KO: 등록 400 응답은 저장된 키가 오래됐음을 의미합니다 — 초기화 후 한 번 재시도.
      if (e is ValidationFailure) {
        await _secureStorage.clearVerificationKeys();
        return await _tryBuildAndRegisterKey(jwsAlg: jwsAlg);
      }
      rethrow;
    }
  }

  Future<VerificationSigningKey> _tryBuildAndRegisterKey({
    required String jwsAlg,
  }) async {
    final storedKeyId = await _secureStorage.getVerificationKeyId();
    final storedDeviceId = await _secureStorage.getVerificationDeviceId();
    final storedJwkJson = await _secureStorage.getVerificationPrivateJwk();

    if (storedKeyId != null &&
        storedDeviceId != null &&
        storedJwkJson != null) {
      final privateKey = _parsePrivateKey(storedJwkJson);
      await _ensureRegistered(
        keyId: storedKeyId,
        deviceId: storedDeviceId,
        privateKey: privateKey,
        jwsAlg: jwsAlg,
      );
      return VerificationSigningKey(
        keyId: storedKeyId,
        deviceId: storedDeviceId,
        privateKey: privateKey,
      );
    }

    final deviceId = storedDeviceId ?? await _resolveStableDeviceId();
    final keyId = 'device-key-${_randomId()}';

    final privateKey = _generateKeyPair(jwsAlg, keyId);

    await _secureStorage.saveVerificationDeviceId(deviceId);
    await _secureStorage.saveVerificationKeyId(keyId);
    await _secureStorage.saveVerificationPrivateJwk(
      jsonEncode(privateKey.toJson()),
    );

    await _ensureRegistered(
      keyId: keyId,
      deviceId: deviceId,
      privateKey: privateKey,
      jwsAlg: jwsAlg,
    );

    return VerificationSigningKey(
      keyId: keyId,
      deviceId: deviceId,
      privateKey: privateKey,
    );
  }

  Future<void> _ensureRegistered({
    required String keyId,
    required String deviceId,
    required JsonWebKey privateKey,
    required String jwsAlg,
  }) async {
    final registeredAt = await _secureStorage.getVerificationKeyRegisteredAt();
    if (registeredAt != null) {
      return;
    }

    final publicKey = _extractPublicKey(privateKey, keyId);
    final publicKeyJson = Map<String, dynamic>.from(publicKey.toJson());
    publicKeyJson['alg'] = jwsAlg.trim().isEmpty ? 'RS256' : jwsAlg.trim();
    publicKeyJson['kid'] = keyId;

    final result = await _repository.registerDeviceKey(
      keyId: keyId,
      deviceId: deviceId,
      publicKeyJwk: publicKeyJson,
    );

    if (result.isSuccess) {
      await _secureStorage.saveVerificationKeyRegisteredAt(DateTime.now());
      return;
    }

    final failure = result.failureOrNull;
    throw failure ??
        const UnknownFailure(
          'Device key registration failed',
          code: 'device_key_registration_failed',
        );
  }

  /// EN: Returns a stable device identifier.
  ///     Android: uses androidId (persists across app reinstalls).
  ///     Other platforms: falls back to a randomly-generated ID stored in secure storage.
  /// KO: 안정적인 디바이스 식별자를 반환합니다.
  ///     Android: androidId 사용 (앱 재설치 후에도 유지됨).
  ///     기타 플랫폼: 보안 저장소에 저장된 랜덤 ID로 대체합니다.
  Future<String> _resolveStableDeviceId() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        final androidId = info.id;
        if (androidId.isNotEmpty) {
          return 'device-android-$androidId';
        }
      } catch (_) {
        // EN: Fall through to random ID if device info is unavailable.
        // KO: 기기 정보를 가져올 수 없으면 랜덤 ID로 대체합니다.
      }
    }
    return 'device-${_platformPrefix()}-${_randomId()}';
  }

  JsonWebKey _generateKeyPair(String jwsAlg, String keyId) {
    final algorithm = jwsAlg.trim().isEmpty ? 'RS256' : jwsAlg.trim();
    final generated = JsonWebKey.generate(algorithm, keyBitLength: 2048);
    final cryptoPair = generated.cryptoKeyPair;
    return JsonWebKey.fromCryptoKeys(
      publicKey: cryptoPair.publicKey,
      privateKey: cryptoPair.privateKey,
      keyId: keyId,
    );
  }

  JsonWebKey _extractPublicKey(JsonWebKey privateKey, String keyId) {
    final publicKey = privateKey.cryptoKeyPair.publicKey;
    return JsonWebKey.fromCryptoKeys(publicKey: publicKey, keyId: keyId);
  }

  JsonWebKey _parsePrivateKey(String jwkJson) {
    final jsonValue = jsonDecode(jwkJson);
    if (jsonValue is Map<String, dynamic>) {
      return JsonWebKey.fromJson(jsonValue);
    }
    throw const FormatException('Invalid verification private JWK payload.');
  }

  String _randomId() {
    final bytes = Uint8List(16);
    final random = Random.secure();
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _platformPrefix() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
