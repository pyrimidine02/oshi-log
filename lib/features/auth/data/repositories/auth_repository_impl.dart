/// EN: Authentication repository implementation.
/// KO: 인증 리포지토리 구현체.
library;

import 'dart:convert';
import 'dart:math';

import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/oauth_provider.dart';
import '../../domain/entities/register_consent.dart';
import '../../domain/entities/register_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/account_recovery_password_request.dart';
import '../dto/apple_link_existing_request.dart';
import '../dto/apple_oauth_request.dart';
import '../dto/change_password_request.dart';
import '../dto/change_password_response.dart';
import '../dto/connect_apple_request.dart';
import '../dto/connect_existing_apple_request.dart';
import '../dto/connect_existing_google_request.dart';
import '../dto/connect_existing_request.dart';
import '../dto/connect_google_request.dart';
import '../dto/email_verification_confirm_request.dart';
import '../dto/email_verification_request.dart';
import '../dto/email_verification_response.dart';
import '../dto/google_link_existing_request.dart';
import '../dto/google_oauth_request.dart';
import '../dto/login_request.dart';
import '../dto/password_reset_confirm_request.dart';
import '../dto/password_reset_request_dto.dart';
import '../dto/register_request.dart';
import '../dto/register_response.dart';
import '../dto/refresh_token_request.dart';
import '../dto/token_response.dart';
import '../dto/twitter_oauth_request.dart';
import '../mappers/auth_tokens_mappers.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
    DateTime Function()? now,
    Future<void> Function(Duration)? sleep,
    int Function(int maxExclusive)? nextInt,
  }) : _remoteDataSource = remoteDataSource,
       _secureStorage = secureStorage,
       _now = now ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed,
       _nextInt = nextInt ?? Random().nextInt;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _sleep;
  final int Function(int maxExclusive) _nextInt;
  final Map<String, Future<Result<AuthTokens>>> _inFlightLoginRequests =
      <String, Future<Result<AuthTokens>>>{};

  @override
  Future<Result<AuthTokens>> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final inFlight = _inFlightLoginRequests[normalizedUsername];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loginWithRetry(username: username, password: password);
    _inFlightLoginRequests[normalizedUsername] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightLoginRequests[normalizedUsername], future)) {
        _inFlightLoginRequests.remove(normalizedUsername);
      }
    }
  }

  @override
  Future<Result<AuthTokens>> recoverWithPassword({
    required String email,
    required String password,
  }) async {
    return _persistTokens(
      await _remoteDataSource.recoverWithPassword(
        AccountRecoveryPasswordRequest(
          email: email.trim().toLowerCase(),
          password: password,
        ),
      ),
    );
  }

  @override
  Future<Result<AuthTokens>> recoverWithGoogle({
    required String idToken,
  }) async {
    return _persistTokens(
      await _remoteDataSource.recoverWithGoogle(
        GoogleOAuthRequest(idToken: idToken),
      ),
    );
  }

  @override
  Future<Result<AuthTokens>> recoverWithApple({
    required String identityToken,
    String? email,
    String? fullName,
  }) async {
    return _persistTokens(
      await _remoteDataSource.recoverWithApple(
        AppleOAuthRequest(
          identityToken: identityToken,
          email: email,
          fullName: fullName,
        ),
      ),
    );
  }

  @override
  Future<Result<RegisterResult>> register({
    required String username,
    required String password,
    required String nickname,
    List<RegisterConsent> consents = const [],
  }) async {
    final primaryResult = await _remoteDataSource.register(
      RegisterRequest(
        username: username,
        password: password,
        nickname: nickname,
        consents: consents,
      ),
    );

    // EN: Compatibility fallback for backends that still reject `consents`.
    // KO: `consents` 필드를 아직 허용하지 않는 백엔드에 대한 하위호환 재시도입니다.
    if (consents.isNotEmpty &&
        primaryResult is Err<RegisterResponse> &&
        _shouldRetryLegacyRegister(primaryResult.failure)) {
      final legacyResult = await _remoteDataSource.register(
        RegisterRequest(
          username: username,
          password: password,
          nickname: nickname,
        ),
      );
      return _processRegisterResponse(legacyResult);
    }

    return _processRegisterResponse(primaryResult);
  }

  /// EN: Processes a [RegisterResponse] — persists tokens when verification
  ///     is not required, otherwise returns [RegisterResult] with pending email.
  /// KO: [RegisterResponse]를 처리합니다 — 인증 불필요 시 토큰을 저장하고,
  ///     그렇지 않으면 대기 이메일과 함께 [RegisterResult]를 반환합니다.
  Future<Result<RegisterResult>> _processRegisterResponse(
    Result<RegisterResponse> result,
  ) async {
    if (result is Err<RegisterResponse>) {
      return Result.failure(result.failure);
    }

    final resp = (result as Success<RegisterResponse>).data;

    if (resp.verificationRequired) {
      // EN: Email verification required — no tokens issued yet.
      // KO: 이메일 인증 필요 — 토큰이 아직 발급되지 않았습니다.
      return Result.success(
        RegisterResult(
          verificationRequired: true,
          pendingEmail: resp.email,
          verificationExpiresAt: resp.verificationExpiresAt,
        ),
      );
    }

    // EN: Persist tokens for immediate login.
    // KO: 즉시 로그인을 위해 토큰을 저장합니다.
    final accessToken = resp.accessToken ?? '';
    final refreshToken = resp.refreshToken ?? '';
    await _secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final expiry = resp.resolvedExpiry(_now());
    if (expiry != null) {
      await _secureStorage.saveTokenExpiry(expiry);
    }

    final newUserId = _extractUserId(accessToken);
    if (newUserId != null && newUserId.isNotEmpty) {
      final previousUserId = await _secureStorage.getUserId();
      if (previousUserId == null || previousUserId != newUserId) {
        await _secureStorage.clearVerificationKeys();
      }
      await _secureStorage.saveUserId(newUserId);
    }

    final hasTokens = await _secureStorage.hasValidTokens();
    if (!hasTokens) {
      return Result.failure(
        const AuthFailure(
          'Token persistence failed',
          code: 'token_persist_failed',
        ),
      );
    }

    return const Result.success(RegisterResult(verificationRequired: false));
  }

  @override
  Future<Result<AuthTokens>> refresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return Result.failure(
        const ValidationFailure('Refresh token missing', code: 'missing_token'),
      );
    }

    final result = await _remoteDataSource.refresh(
      RefreshTokenRequest(refreshToken: refreshToken),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<void>> logout() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    final request = refreshToken != null && refreshToken.isNotEmpty
        ? RefreshTokenRequest(refreshToken: refreshToken)
        : null;

    final result = await _remoteDataSource.logout(request);
    await _secureStorage.clearTokens();
    return result;
  }

  @override
  Future<Result<AuthTokens>> exchangeOAuthCode({
    required OAuthProvider provider,
    required String code,
    String? state,
  }) async {
    final result = await _remoteDataSource.exchangeOAuthCode(
      provider: provider,
      code: code,
      state: state,
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> loginWithGoogle({required String idToken}) async {
    final result = await _remoteDataSource.loginWithGoogle(
      GoogleOAuthRequest(idToken: idToken),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> loginWithApple({
    required String identityToken,
    String? email,
    String? fullName,
  }) async {
    final result = await _remoteDataSource.loginWithApple(
      AppleOAuthRequest(
        identityToken: identityToken,
        email: email,
        fullName: fullName,
      ),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> loginWithTwitter({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final result = await _remoteDataSource.loginWithTwitter(
      TwitterOAuthRequest(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      ),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<DateTime?>> sendEmailVerification({
    required String email,
  }) async {
    final result = await _remoteDataSource.sendEmailVerification(
      EmailVerificationRequest(email: email),
    );
    if (result is Err<EmailVerificationResponse>) {
      return Result.failure(result.failure);
    }
    final resp = (result as Success<EmailVerificationResponse>).data;
    return Result.success(resp.resendAvailableAt);
  }

  @override
  Future<Result<void>> confirmEmailVerification({required String token}) {
    return _remoteDataSource.confirmEmailVerification(
      EmailVerificationConfirmRequest(token: token),
    );
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _remoteDataSource.changePassword(
      ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    if (result is Err<ChangePasswordResponse>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    final result = await _remoteDataSource.requestPasswordReset(
      PasswordResetRequestDto(email: email),
    );
    if (result is Err<PasswordResetRequestResponse>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    final result = await _remoteDataSource.confirmPasswordReset(
      PasswordResetConfirmRequest(token: token, newPassword: newPassword),
    );
    if (result is Err<PasswordResetConfirmResponse>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<AuthTokens>> linkExistingWithGoogle({
    required String idToken,
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.linkExistingWithGoogle(
      GoogleLinkExistingRequest(
        idToken: idToken,
        email: email,
        password: password,
      ),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> linkExistingWithApple({
    required String identityToken,
    required String email,
    required String password,
    String? appleEmail,
    String? fullName,
  }) async {
    final result = await _remoteDataSource.linkExistingWithApple(
      AppleLinkExistingRequest(
        identityToken: identityToken,
        email: email,
        password: password,
        appleEmail: appleEmail,
        fullName: fullName,
      ),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> connectExisting({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.connectExisting(
      ConnectExistingRequest(email: email, password: password),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> connectExistingWithGoogle({
    required String idToken,
  }) async {
    final result = await _remoteDataSource.connectExistingWithGoogle(
      ConnectExistingGoogleRequest(idToken: idToken),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<AuthTokens>> connectExistingWithApple({
    required String identityToken,
    String? email,
    String? fullName,
  }) async {
    final result = await _remoteDataSource.connectExistingWithApple(
      ConnectExistingAppleRequest(
        identityToken: identityToken,
        email: email,
        fullName: fullName,
      ),
    );
    return _persistTokens(result);
  }

  @override
  Future<Result<void>> connectGoogle({required String idToken}) {
    return _remoteDataSource.connectGoogle(
      ConnectGoogleRequest(idToken: idToken),
    );
  }

  @override
  Future<Result<void>> connectApple({
    required String identityToken,
    String? email,
  }) {
    return _remoteDataSource.connectApple(
      ConnectAppleRequest(identityToken: identityToken, email: email),
    );
  }

  @override
  Future<Result<void>> disconnectOAuth() {
    return _remoteDataSource.disconnectOAuth();
  }

  Future<Result<AuthTokens>> _persistTokens(
    Result<TokenResponse> result,
  ) async {
    if (result is Success<TokenResponse>) {
      final tokenResponse = result.data;
      await _secureStorage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      final expiry = tokenResponse.resolvedExpiry(_now());
      if (expiry != null) {
        await _secureStorage.saveTokenExpiry(expiry);
      }

      final newUserId = _extractUserId(tokenResponse.accessToken);
      if (newUserId != null && newUserId.isNotEmpty) {
        final previousUserId = await _secureStorage.getUserId();
        if (previousUserId == null || previousUserId != newUserId) {
          await _secureStorage.clearVerificationKeys();
        }
        await _secureStorage.saveUserId(newUserId);
      }

      // EN: Ensure tokens are persisted before returning success to callers
      // EN: that will immediately call protected APIs.
      // KO: 호출자가 즉시 보호 API를 호출하더라도 안전하도록 토큰 저장을
      // KO: 재검증한 뒤 성공을 반환합니다.
      final hasTokens = await _secureStorage.hasValidTokens();
      if (!hasTokens) {
        return Result.failure(
          const AuthFailure(
            'Token persistence failed',
            code: 'token_persist_failed',
          ),
        );
      }

      return Result.success(tokenResponse.toDomain());
    }

    if (result is Err<TokenResponse>) {
      return Result.failure(result.failure);
    }

    return Result.failure(
      const UnknownFailure('Unknown auth result', code: 'unknown_result'),
    );
  }

  String? _extractUserId(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length < 2) return null;
      final normalized = base64.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final jsonValue = jsonDecode(payload);
      if (jsonValue is Map<String, dynamic>) {
        final sub = jsonValue['sub'];
        return sub is String ? sub : null;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to parse access token subject',
        data: e,
        tag: 'AuthRepository',
      );
      AppLogger.error(
        'Access token parse error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthRepository',
      );
      return null;
    }
  }

  bool _shouldRetryLegacyRegister(Failure failure) {
    final normalizedMessage = failure.message.toLowerCase();
    final normalizedCode = (failure.code ?? '').toLowerCase();

    final mentionsConsents =
        normalizedMessage.contains('consents') ||
        normalizedCode.contains('consents');
    final likelyContractMismatch =
        normalizedMessage.contains('unrecognized') ||
        normalizedMessage.contains('unknown') ||
        normalizedMessage.contains('not allowed') ||
        normalizedMessage.contains('cannot deserialize') ||
        normalizedMessage.contains('json parse');

    return mentionsConsents && likelyContractMismatch;
  }

  Future<Result<AuthTokens>> _loginWithRetry({
    required String username,
    required String password,
  }) async {
    final request = LoginRequest(username: username.trim(), password: password);
    final firstResult = await _remoteDataSource.login(request);

    if (firstResult is Success<TokenResponse>) {
      return _persistTokens(firstResult);
    }
    if (firstResult is! Err<TokenResponse>) {
      return Result.failure(
        const UnknownFailure('Unknown login result', code: 'unknown_login'),
      );
    }

    if (_isConflictFailure(firstResult.failure)) {
      await _sleep(_resolveConflictRetryDelay());
      return _persistTokens(await _remoteDataSource.login(request));
    }

    if (_isRateLimitFailure(firstResult.failure)) {
      final retryDelay = _resolveRateLimitRetryDelay(firstResult.failure);
      await _sleep(retryDelay);
      return _persistTokens(await _remoteDataSource.login(request));
    }

    return Result.failure(firstResult.failure);
  }

  bool _isConflictFailure(Failure failure) {
    if (failure.code == '409') {
      return true;
    }
    final lowerCode = (failure.code ?? '').toLowerCase();
    final lowerMessage = failure.message.toLowerCase();
    return lowerCode.contains('conflict') ||
        lowerMessage.contains('conflict') ||
        lowerMessage.contains('duplicate');
  }

  bool _isRateLimitFailure(Failure failure) {
    if (failure.code == '429') {
      return true;
    }
    final lowerCode = (failure.code ?? '').toLowerCase();
    final lowerMessage = failure.message.toLowerCase();
    return lowerCode.contains('too_many') ||
        lowerMessage.contains('too many requests');
  }

  Duration _resolveRateLimitRetryDelay(Failure failure) {
    const fallback = Duration(milliseconds: 1200);
    if (failure is! ServerFailure || failure.retryAfterMs == null) {
      return fallback;
    }

    final retryAfterMs = failure.retryAfterMs!;
    if (retryAfterMs <= 0) {
      return fallback;
    }

    // EN: Clamp server hints to avoid excessive wait in automatic retry flow.
    // KO: 자동 재시도 흐름에서 과도한 대기를 피하기 위해 서버 힌트를 제한합니다.
    final clampedMs = retryAfterMs.clamp(500, 5000).toInt();
    return Duration(milliseconds: clampedMs);
  }

  Duration _resolveConflictRetryDelay() {
    // EN: Add short jitter to reduce concurrent login-thrashing on conflicts.
    // KO: 충돌(409) 발생 시 동시 로그인 재시도 폭주를 줄이기 위해 짧은 지터를 둡니다.
    const baseMs = 220;
    const jitterWindowMs = 121; // 220ms ~ 340ms
    return Duration(milliseconds: baseMs + _nextInt(jitterWindowMs));
  }
}
