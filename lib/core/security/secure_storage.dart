/// EN: Secure storage for sensitive data like tokens
/// KO: 토큰과 같은 민감한 데이터를 위한 보안 저장소
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// EN: Keys for secure storage
/// KO: 보안 저장소 키
class SecureStorageKeys {
  SecureStorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String tokenExpiry = 'token_expiry';
  static const String verificationKeyId = 'verification_key_id';
  static const String verificationDeviceId = 'verification_device_id';
  static const String verificationPrivateJwk = 'verification_private_jwk';
  static const String verificationKeyRegisteredAt =
      'verification_key_registered_at';
  static const String oauthPendingState = 'oauth_pending_state';
  static const String oauthPendingProvider = 'oauth_pending_provider';
  static const String notificationDeviceId = 'notification_device_id';
  static const String notificationPushToken = 'notification_push_token';

  // EN: Apple Sign-In cached credentials (required because Apple only provides
  //     email/fullName on the very first sign-in; subsequent logins omit them).
  // KO: Apple 로그인 캐시 자격증명 (Apple은 최초 1회만 email/fullName을 제공하므로
  //     이후 요청 시 재사용하기 위해 저장합니다).
  static const String appleEmail = 'apple_cached_email';
  static const String appleFullName = 'apple_cached_full_name';

  // EN: Twitter PKCE code_verifier — stored before launching the browser,
  //     retrieved and cleared when the OAuth callback arrives.
  // KO: Twitter PKCE code_verifier — 브라우저 실행 전 저장하고,
  //     OAuth 콜백 수신 시 읽고 즉시 삭제합니다.
  static const String twitterCodeVerifier = 'twitter_pkce_code_verifier';
}

/// EN: Wrapper for FlutterSecureStorage with typed methods
/// KO: 타입화된 메서드를 제공하는 FlutterSecureStorage 래퍼
class SecureStorage {
  /// EN: Create a secure-storage wrapper scoped to an API origin.
  ///     The app provider passes [AppConfig.storageNamespace]. A null
  ///     namespace is retained for isolated tests and migration utilities.
  /// KO: API 오리전에 맞춘 보안 저장소 래퍼를 생성합니다.
  ///     앱 프로바이더는 [AppConfig.storageNamespace]를 전달합니다. null
  ///     네임스페이스는 격리된 테스트와 마이그레이션 도구를 위해 유지합니다.
  SecureStorage({FlutterSecureStorage? storage, String? namespace})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          ),
      _namespace = namespace?.trim().isEmpty == true ? null : namespace?.trim();

  final FlutterSecureStorage _storage;
  final String? _namespace;

  /// EN: Namespace used by this wrapper, if it is scoped.
  /// KO: 이 래퍼가 사용하는 네임스페이스입니다.
  String? get namespace => _namespace;

  String _storageKey(String key) {
    final namespace = _namespace;
    if (namespace == null || key.startsWith('gbt:$namespace:')) {
      return key;
    }
    return 'gbt:$namespace:$key';
  }

  // ========================================
  // EN: Token Management
  // KO: 토큰 관리
  // ========================================

  /// EN: Save access token
  /// KO: 액세스 토큰 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.accessToken),
      value: token,
    );
  }

  /// EN: Get access token
  /// KO: 액세스 토큰 조회
  Future<String?> getAccessToken() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.accessToken));
  }

  /// EN: Delete access token
  /// KO: 액세스 토큰 삭제
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _storageKey(SecureStorageKeys.accessToken));
  }

  /// EN: Save refresh token
  /// KO: 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.refreshToken),
      value: token,
    );
  }

  /// EN: Get refresh token
  /// KO: 리프레시 토큰 조회
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.refreshToken));
  }

  /// EN: Delete refresh token
  /// KO: 리프레시 토큰 삭제
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _storageKey(SecureStorageKeys.refreshToken));
  }

  /// EN: Save both tokens at once, optionally with an expiry timestamp.
  /// KO: 두 토큰을 한번에 저장하고, 선택적으로 만료 시간도 함께 저장합니다.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    final futures = <Future<void>>[
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ];
    if (expiresAt != null) {
      futures.add(saveTokenExpiry(expiresAt));
    }
    await Future.wait(futures);
  }

  /// EN: Delete all tokens (logout)
  /// KO: 모든 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      _storage.delete(key: _storageKey(SecureStorageKeys.tokenExpiry)),
    ]);
  }

  /// EN: Check if user has valid tokens
  /// KO: 유효한 토큰이 있는지 확인
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  // ========================================
  // EN: Token Expiry Management
  // KO: 토큰 만료 관리
  // ========================================

  /// EN: Save token expiry timestamp
  /// KO: 토큰 만료 타임스탬프 저장
  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.tokenExpiry),
      value: expiry.toIso8601String(),
    );
  }

  /// EN: Get token expiry timestamp
  /// KO: 토큰 만료 타임스탬프 조회
  Future<DateTime?> getTokenExpiry() async {
    final value = await _storage.read(
      key: _storageKey(SecureStorageKeys.tokenExpiry),
    );
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// EN: Check if token is expired
  /// KO: 토큰이 만료되었는지 확인
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    // EN: If expiry is unknown, treat token as valid and rely on refresh/401.
    // KO: 만료 시간이 없으면 유효하다고 간주하고 갱신/401 처리에 맡깁니다.
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  // ========================================
  // EN: User ID Management
  // KO: 사용자 ID 관리
  // ========================================

  /// EN: Save user ID
  /// KO: 사용자 ID 저장
  Future<void> saveUserId(String userId) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.userId),
      value: userId,
    );
  }

  /// EN: Get user ID
  /// KO: 사용자 ID 조회
  Future<String?> getUserId() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.userId));
  }

  /// EN: Delete user ID
  /// KO: 사용자 ID 삭제
  Future<void> deleteUserId() async {
    await _storage.delete(key: _storageKey(SecureStorageKeys.userId));
  }

  // ========================================
  // EN: Notification Device Management
  // KO: 알림 디바이스 관리
  // ========================================

  /// EN: Save notification device ID.
  /// KO: 알림 디바이스 ID 저장.
  Future<void> saveNotificationDeviceId(String deviceId) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.notificationDeviceId),
      value: deviceId,
    );
  }

  /// EN: Get notification device ID.
  /// KO: 알림 디바이스 ID 조회.
  Future<String?> getNotificationDeviceId() async {
    return _storage.read(
      key: _storageKey(SecureStorageKeys.notificationDeviceId),
    );
  }

  /// EN: Delete notification device ID.
  /// KO: 알림 디바이스 ID 삭제.
  Future<void> deleteNotificationDeviceId() async {
    await _storage.delete(
      key: _storageKey(SecureStorageKeys.notificationDeviceId),
    );
  }

  /// EN: Save notification push token.
  /// KO: 알림 푸시 토큰 저장.
  Future<void> saveNotificationPushToken(String pushToken) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.notificationPushToken),
      value: pushToken,
    );
  }

  /// EN: Get notification push token.
  /// KO: 알림 푸시 토큰 조회.
  Future<String?> getNotificationPushToken() async {
    return _storage.read(
      key: _storageKey(SecureStorageKeys.notificationPushToken),
    );
  }

  /// EN: Delete notification push token.
  /// KO: 알림 푸시 토큰 삭제.
  Future<void> deleteNotificationPushToken() async {
    await _storage.delete(
      key: _storageKey(SecureStorageKeys.notificationPushToken),
    );
  }

  /// EN: Clear notification registration material.
  /// KO: 알림 등록 정보를 삭제합니다.
  Future<void> clearNotificationRegistration() async {
    await Future.wait([
      deleteNotificationDeviceId(),
      deleteNotificationPushToken(),
    ]);
  }

  // ========================================
  // EN: Verification device key management
  // KO: 인증 디바이스 키 관리
  // ========================================

  /// EN: Save verification key ID.
  /// KO: 인증 키 ID 저장.
  Future<void> saveVerificationKeyId(String keyId) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.verificationKeyId),
      value: keyId,
    );
  }

  /// EN: Get verification key ID.
  /// KO: 인증 키 ID 조회.
  Future<String?> getVerificationKeyId() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.verificationKeyId));
  }

  /// EN: Save device ID for verification.
  /// KO: 인증용 디바이스 ID 저장.
  Future<void> saveVerificationDeviceId(String deviceId) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.verificationDeviceId),
      value: deviceId,
    );
  }

  /// EN: Get device ID for verification.
  /// KO: 인증용 디바이스 ID 조회.
  Future<String?> getVerificationDeviceId() async {
    return _storage.read(
      key: _storageKey(SecureStorageKeys.verificationDeviceId),
    );
  }

  /// EN: Save verification private JWK (JSON string).
  /// KO: 인증용 개인키 JWK(JSON 문자열) 저장.
  Future<void> saveVerificationPrivateJwk(String jwkJson) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.verificationPrivateJwk),
      value: jwkJson,
    );
  }

  /// EN: Get verification private JWK (JSON string).
  /// KO: 인증용 개인키 JWK(JSON 문자열) 조회.
  Future<String?> getVerificationPrivateJwk() async {
    return _storage.read(
      key: _storageKey(SecureStorageKeys.verificationPrivateJwk),
    );
  }

  /// EN: Save verification key registration timestamp.
  /// KO: 인증 키 등록 시간 저장.
  Future<void> saveVerificationKeyRegisteredAt(DateTime registeredAt) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.verificationKeyRegisteredAt),
      value: registeredAt.toIso8601String(),
    );
  }

  /// EN: Get verification key registration timestamp.
  /// KO: 인증 키 등록 시간 조회.
  Future<DateTime?> getVerificationKeyRegisteredAt() async {
    final value = await _storage.read(
      key: _storageKey(SecureStorageKeys.verificationKeyRegisteredAt),
    );
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// EN: Clear verification key material.
  /// KO: 인증 키 자료 삭제.
  Future<void> clearVerificationKeys() async {
    await Future.wait([
      _storage.delete(key: _storageKey(SecureStorageKeys.verificationKeyId)),
      _storage.delete(key: _storageKey(SecureStorageKeys.verificationDeviceId)),
      _storage.delete(
        key: _storageKey(SecureStorageKeys.verificationPrivateJwk),
      ),
      _storage.delete(
        key: _storageKey(SecureStorageKeys.verificationKeyRegisteredAt),
      ),
    ]);
  }

  // ========================================
  // EN: OAuth state nonce management
  // KO: OAuth state nonce 관리
  // ========================================

  /// EN: Save pending OAuth state nonce and provider.
  /// KO: 대기 중인 OAuth state nonce와 provider를 저장합니다.
  Future<void> saveOAuthPendingState({
    required String state,
    required String providerId,
  }) async {
    await Future.wait([
      _storage.write(
        key: _storageKey(SecureStorageKeys.oauthPendingState),
        value: state,
      ),
      _storage.write(
        key: _storageKey(SecureStorageKeys.oauthPendingProvider),
        value: providerId,
      ),
    ]);
  }

  /// EN: Get pending OAuth state nonce.
  /// KO: 대기 중인 OAuth state nonce를 조회합니다.
  Future<String?> getOAuthPendingState() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.oauthPendingState));
  }

  /// EN: Get pending OAuth provider id.
  /// KO: 대기 중인 OAuth provider id를 조회합니다.
  Future<String?> getOAuthPendingProvider() async {
    return _storage.read(
      key: _storageKey(SecureStorageKeys.oauthPendingProvider),
    );
  }

  /// EN: Clear pending OAuth state nonce/provider.
  /// KO: 대기 중인 OAuth state/provider를 삭제합니다.
  Future<void> clearOAuthPendingState() async {
    await Future.wait([
      _storage.delete(key: _storageKey(SecureStorageKeys.oauthPendingState)),
      _storage.delete(key: _storageKey(SecureStorageKeys.oauthPendingProvider)),
    ]);
  }

  // ========================================
  // EN: Apple Sign-In credential cache
  // KO: Apple 로그인 자격증명 캐시
  // ========================================

  /// EN: Cache Apple email and fullName (only available on first sign-in).
  ///     Pass null to skip writing a field (preserves any previously cached value).
  /// KO: Apple 이메일과 이름을 캐시합니다 (최초 로그인 시에만 제공됨).
  ///     null을 전달하면 해당 필드를 건너뜁니다 (기존 캐시 값 유지).
  Future<void> saveAppleCredentials({String? email, String? fullName}) async {
    final futures = <Future<void>>[];
    if (email != null) {
      futures.add(
        _storage.write(
          key: _storageKey(SecureStorageKeys.appleEmail),
          value: email,
        ),
      );
    }
    if (fullName != null) {
      futures.add(
        _storage.write(
          key: _storageKey(SecureStorageKeys.appleFullName),
          value: fullName,
        ),
      );
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  /// EN: Get cached Apple email.
  /// KO: 캐시된 Apple 이메일을 조회합니다.
  Future<String?> getAppleEmail() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.appleEmail));
  }

  /// EN: Get cached Apple fullName.
  /// KO: 캐시된 Apple 이름을 조회합니다.
  Future<String?> getAppleFullName() async {
    return _storage.read(key: _storageKey(SecureStorageKeys.appleFullName));
  }

  // ========================================
  // EN: Twitter PKCE code_verifier management
  // KO: Twitter PKCE code_verifier 관리
  // ========================================

  /// EN: Store the PKCE code_verifier before launching the Twitter auth browser.
  /// KO: Twitter 인증 브라우저 실행 전 PKCE code_verifier를 저장합니다.
  Future<void> saveTwitterCodeVerifier(String verifier) async {
    await _storage.write(
      key: _storageKey(SecureStorageKeys.twitterCodeVerifier),
      value: verifier,
    );
  }

  /// EN: Retrieve and immediately delete the PKCE code_verifier.
  ///     Returns null if none was stored (e.g., stale callback after restart).
  /// KO: PKCE code_verifier를 읽고 즉시 삭제합니다.
  ///     저장된 값이 없으면 null을 반환합니다 (예: 재시작 후 오래된 콜백).
  Future<String?> getAndClearTwitterCodeVerifier() async {
    final value = await _storage.read(
      key: _storageKey(SecureStorageKeys.twitterCodeVerifier),
    );
    await _storage.delete(
      key: _storageKey(SecureStorageKeys.twitterCodeVerifier),
    );
    return value;
  }

  // ========================================
  // EN: Generic Methods
  // KO: 제네릭 메서드
  // ========================================

  /// EN: Write value to secure storage
  /// KO: 보안 저장소에 값 쓰기
  Future<void> write(String key, String value) async {
    await _storage.write(key: _storageKey(key), value: value);
  }

  /// EN: Read value from secure storage
  /// KO: 보안 저장소에서 값 읽기
  Future<String?> read(String key) async {
    return _storage.read(key: _storageKey(key));
  }

  /// EN: Delete value from secure storage
  /// KO: 보안 저장소에서 값 삭제
  Future<void> delete(String key) async {
    await _storage.delete(key: _storageKey(key));
  }

  /// EN: Clear all data from secure storage
  /// KO: 보안 저장소의 모든 데이터 삭제
  Future<void> clearAll() async {
    final namespace = _namespace;
    if (namespace == null) {
      await _storage.deleteAll();
      return;
    }
    final values = await _storage.readAll();
    final prefix = 'gbt:$namespace:';
    final scopedKeys = values.keys
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    await Future.wait(scopedKeys.map((key) => _storage.delete(key: key)));
  }

  /// EN: Check if key exists in secure storage
  /// KO: 보안 저장소에 키가 존재하는지 확인
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: _storageKey(key));
  }
}
