/// EN: Service for creating JWE tokens for verification.
/// KO: 인증을 위한 JWE 토큰을 생성하는 서비스.
library;

import 'dart:convert';
import 'package:jose/jose.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:oshi_log/platform/location/location_service.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/features/place/verification/domain/repositories/verification_repository.dart';
import 'verification_controller.dart';
import 'verification_key_service.dart';

part 'token_service.g.dart';

/// EN: A service responsible for creating the JWE token required for verification.
/// It combines location data with a server-provided challenge (nonce).
///
/// KO: 인증에 필요한 JWE 토큰 생성을 담당하는 서비스입니다.
/// 위치 데이터와 서버에서 제공된 챌린지(nonce)를 결합합니다.
class TokenService {
  TokenService(this._repository, this._locationService, this._keyService);

  final VerificationRepository _repository;
  final LocationService _locationService;
  final VerificationKeyService _keyService;

  /// EN: Creates a JWE token for verification.
  /// This involves fetching a challenge from the server, getting the current location,
  /// building a claims set, and then encrypting it into a JWE.
  ///
  /// KO: 인증을 위한 JWE 토큰을 생성합니다.
  /// 서버에서 챌린지를 가져오고, 현재 위치를 얻어 클레임(claims)을 구성한 뒤,
  /// 이를 JWE로 암호화하는 과정을 포함합니다.
  Future<String> createVerificationToken() async {
    // 1. Fetch challenge (nonce) from the server (optional).
    final challengeResult = await _repository.getChallenge();
    final challenge = challengeResult.dataOrNull;

    // 2. Fetch verification config to get public key for encryption
    final configResult = await _repository.getConfig();
    final config = configResult.dataOrNull;
    if (config == null || config.publicKeys.isEmpty) {
      throw Exception('Failed to get verification config or public key.');
    }

    // 3. Get current location
    final location = await _locationService.getCurrentLocation();

    // 4. Build the claims for the JWE
    final captureSeconds = location.timestamp.millisecondsSinceEpoch ~/ 1000;
    final claims = <String, dynamic>{
      'lat': location.latitude,
      'lon': location.longitude,
      'timestamp': captureSeconds,
      'accuracyM': location.accuracy,
      'isMocked': location.isMocked,
      'mockProvider': location.isMocked ? 'device' : null,
    };

    // 5. Ensure device key is registered and sign JWS (RS256), then wrap with JWE.
    // EN: Support JWK JSON, PEM, and base64-encoded PEM keys.
    // KO: JWK JSON, PEM, base64 PEM 키 형식을 모두 지원합니다.
    final publicKey = _parsePublicKey(config.publicKeys);
    final jweAlg = _resolveJweAlg(config.jweAlg, publicKey);
    final signingKey = await _keyService.ensureSigningKey(
      jwsAlg: config.jwsAlg,
    );
    final builder = JsonWebEncryptionBuilder();

    // EN: Sign claims first (JWS), then encrypt the signed JWT (JWE).
    // KO: 클레임을 먼저 서명(JWS)한 뒤, 서명된 JWT를 암호화(JWE)합니다.
    builder.stringContent = _buildSignedJwt(
      claims,
      config.jwsAlg,
      signingKey.keyId,
      signingKey.privateKey,
      nonce: challenge?.nonce,
    );
    builder.mediaType = 'JWT';
    builder.addRecipient(publicKey, algorithm: jweAlg);
    builder.encryptionAlgorithm = 'A256GCM'; // Common encryption algorithm

    final jwe = builder.build();
    return jwe.toCompactSerialization();
  }
}

String _buildSignedJwt(
  Map<String, dynamic> claims,
  String jwsAlg,
  String keyId,
  JsonWebKey privateKey, {
  String? nonce,
}) {
  final resolvedAlg = jwsAlg.trim().isEmpty ? 'RS256' : jwsAlg.trim();

  final jwsBuilder = JsonWebSignatureBuilder();
  jwsBuilder.jsonContent = claims;
  jwsBuilder.setProtectedHeader('kid', keyId);
  if (nonce != null && nonce.isNotEmpty) {
    jwsBuilder.setProtectedHeader('nonce', nonce);
  }
  jwsBuilder.addRecipient(privateKey, algorithm: resolvedAlg);
  return jwsBuilder.build().toCompactSerialization();
}

JsonWebKey _parsePublicKey(List<String> keys) {
  for (final rawKey in keys) {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    try {
      if (trimmed.startsWith('{')) {
        final jsonValue = jsonDecode(trimmed);
        if (jsonValue is Map<String, dynamic>) {
          return JsonWebKey.fromJson(jsonValue);
        }
      }
    } catch (_) {
      // EN: Ignore JSON parse errors and try PEM decoding next.
      // KO: JSON 파싱 오류는 무시하고 PEM 디코딩을 시도합니다.
    }

    final pem = _decodePem(trimmed);
    if (pem != null) {
      return JsonWebKey.fromPem(pem);
    }
  }

  throw const FormatException('Unsupported public key format.');
}

String? _decodePem(String input) {
  if (_looksLikePem(input)) {
    return input;
  }

  try {
    final decoded = utf8.decode(base64.decode(input));
    if (_looksLikePem(decoded)) {
      return decoded;
    }
  } catch (_) {
    // EN: Ignore base64 decoding failures.
    // KO: base64 디코딩 실패는 무시합니다.
  }

  return null;
}

bool _looksLikePem(String input) {
  return input.contains('BEGIN PUBLIC KEY') ||
      input.contains('BEGIN RSA PUBLIC KEY') ||
      input.contains('BEGIN CERTIFICATE');
}

String _resolveJweAlg(String configAlg, JsonWebKey key) {
  final trimmed = configAlg.trim();
  if (trimmed.isNotEmpty && trimmed != 'dir') {
    return trimmed;
  }

  // EN: If config says 'dir' but the key is asymmetric, fall back to RSA-OAEP-256.
  // KO: 설정이 'dir'이지만 비대칭 키인 경우 RSA-OAEP-256으로 보정합니다.
  if (key.keyType != 'oct') {
    return 'RSA-OAEP-256';
  }

  return 'dir';
}

/// EN: Provider for the TokenService.
/// KO: TokenService를 위한 프로바이더.
@riverpod
TokenService tokenService(Ref ref) {
  final repository = ref.watch(verificationRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final keyService = VerificationKeyService(repository, secureStorage);
  return TokenService(repository, locationService, keyService);
}
