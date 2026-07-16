/// EN: Authentication controller handling auth workflows.
/// KO: 인증 플로우를 처리하는 인증 컨트롤러.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_manager.dart';
import '../../../core/error/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/result.dart';
import '../../settings/application/settings_controller.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/auth_tokens.dart';
import '../domain/entities/oauth_provider.dart';
import '../domain/entities/register_consent.dart';
import '../domain/entities/register_result.dart';
import '../domain/repositories/auth_repository.dart';
import 'native_social_login_service.dart';
import 'oauth_service.dart';

const String _kPostComposeCreateDraftKeyPrefix = 'feed_post_create_draft_';
const String _kPostComposeEditDraftKeyPrefix = 'feed_post_edit_draft_';

/// EN: Authentication controller state (loading/error only).
/// KO: 인증 컨트롤러 상태 (로딩/에러만 관리).
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({
    required AuthRepository repository,
    required AuthStateNotifier authStateNotifier,
    required AuthOAuthService oauthService,
    required NativeSocialLoginService nativeSocialLoginService,
    required Future<CacheManager> cacheManagerFuture,
    required SecureStorage secureStorage,
    required Future<LocalStorage> localStorageFuture,
    required Ref ref,
  }) : _repository = repository,
       _authStateNotifier = authStateNotifier,
       _oauthService = oauthService,
       _nativeSocialLoginService = nativeSocialLoginService,
       _cacheManagerFuture = cacheManagerFuture,
       _secureStorage = secureStorage,
       _localStorageFuture = localStorageFuture,
       _ref = ref,
       super(const AsyncData(null));

  final AuthRepository _repository;
  final AuthStateNotifier _authStateNotifier;
  final AuthOAuthService _oauthService;
  final NativeSocialLoginService _nativeSocialLoginService;
  final Future<CacheManager> _cacheManagerFuture;
  final SecureStorage _secureStorage;
  final Future<LocalStorage> _localStorageFuture;
  final Ref _ref;

  /// EN: Pending OAuth credentials stored during EMAIL_ACCOUNT_CONFLICT flow.
  /// KO: EMAIL_ACCOUNT_CONFLICT 플로우 중 임시 보관되는 OAuth 자격증명.
  _PendingOAuthConflict? _pendingConflict;

  /// EN: Fresh provider proof retained only for an explicitly confirmed
  ///     inactive-account recovery attempt.
  /// KO: 명시적으로 확인된 비활성 계정 복구 시도에만 사용할
  ///     최신 제공자 소유권 증명을 임시 보관합니다.
  _PendingInactiveRecovery? _pendingInactiveRecovery;

  /// EN: Login with username/password.
  /// KO: 사용자명/비밀번호 로그인.
  Future<Result<void>> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.login(
      username: username,
      password: password,
    );
    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: 'password',
    );
  }

  /// EN: Restore an inactive password account after explicit user consent.
  /// KO: 사용자의 명시적 동의 후 비활성 비밀번호 계정을 복구합니다.
  Future<Result<void>> recoverWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.recoverWithPassword(
      email: email,
      password: password,
    );
    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: 'password',
    );
  }

  /// EN: Register with username/password.
  ///     Returns [RegisterResult] to distinguish immediate login from
  ///     email-verification-required flows.
  /// KO: 사용자명/비밀번호 회원가입.
  ///     즉시 로그인과 이메일 인증 필요 플로우를 구분하기 위해
  ///     [RegisterResult]를 반환합니다.
  Future<Result<RegisterResult>> register({
    required String username,
    required String password,
    required String nickname,
    List<RegisterConsent> consents = const [],
  }) async {
    state = const AsyncLoading();
    final result = await _repository.register(
      username: username,
      password: password,
      nickname: nickname,
      consents: consents,
    );

    if (result is Err<RegisterResult>) {
      state = AsyncError(result.failure, StackTrace.current);
      return result;
    }

    final registerResult = (result as Success<RegisterResult>).data;

    if (registerResult.verificationRequired) {
      // EN: Email verification required — do not set authenticated.
      // KO: 이메일 인증 필요 — 인증 상태로 전환하지 않습니다.
      state = const AsyncData(null);
      return result;
    }

    // EN: Tokens were persisted by the repository; validate before setting authenticated.
    // KO: 리포지토리가 토큰을 저장했습니다. 인증 상태 설정 전 재검증합니다.
    final hasTokens = await _secureStorage.hasValidTokens();
    if (!hasTokens) {
      const failure = AuthFailure(
        'Authentication succeeded but tokens were not persisted',
        code: 'token_not_persisted',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    await _clearAppCaches();
    _authStateNotifier.setAuthenticated();
    state = const AsyncData(null);
    unawaited(_requestNotificationPermissionOnLogin());
    unawaited(
      _logAuthSuccess(
        analyticsType: _AuthAnalyticsType.signup,
        method: 'password',
      ),
    );
    return result;
  }

  /// EN: Send (or resend) a verification email.
  ///     Returns the earliest time the user may request another email,
  ///     or null if the server did not specify a cooldown.
  /// KO: 인증 이메일을 발송(또는 재발송)합니다.
  ///     사용자가 다음 이메일을 요청할 수 있는 최초 시간을 반환하며,
  ///     서버가 쿨다운을 지정하지 않은 경우 null을 반환합니다.
  Future<Result<DateTime?>> sendEmailVerification({
    required String email,
  }) async {
    final result = await _repository.sendEmailVerification(email: email);
    if (result is Err<DateTime?>) {
      final failure = result.failure;
      state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  /// EN: Confirm verification token.
  /// KO: 이메일 인증 토큰을 확인합니다.
  Future<Result<void>> confirmEmailVerification({required String token}) async {
    final result = await _repository.confirmEmailVerification(token: token);
    if (result is Err<void>) {
      final failure = result.failure;
      state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  /// EN: Complete OAuth login after receiving authorization code.
  /// KO: 인가 코드 수신 후 OAuth 로그인 완료.
  Future<Result<void>> completeOAuthLogin({
    required OAuthProvider provider,
    required String code,
    String? stateParam,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.exchangeOAuthCode(
      provider: provider,
      code: code,
      state: stateParam,
    );
    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: provider.id,
    );
  }

  /// EN: Launch OAuth login flow (generic web-redirect, non-PKCE providers).
  /// KO: OAuth 로그인 플로우 실행 (일반 웹 리다이렉트, PKCE 미사용 제공자).
  Future<Result<void>> startOAuthLogin(OAuthProvider provider) async {
    return _oauthService.launch(provider);
  }

  /// EN: Launch X (Twitter) OAuth 2.0 + PKCE authorization flow.
  ///     Generates PKCE pair, saves the verifier to SecureStorage, then
  ///     opens the X authorization page in the system browser.
  ///     After the user approves, X redirects to the Universal Link
  ///     https://api.noraneko.cc/oauth/x/callback, which the OS intercepts
  ///     and routes to the app via [completeTwitterLogin].
  /// KO: X (Twitter) OAuth 2.0 + PKCE 인가 플로우를 실행합니다.
  ///     PKCE 쌍을 생성하고 verifier를 SecureStorage에 저장한 뒤,
  ///     시스템 브라우저에서 X 인가 페이지를 엽니다.
  ///     사용자 승인 후 X가 유니버설 링크
  ///     https://api.noraneko.cc/oauth/x/callback으로 리다이렉트하면
  ///     OS가 앱을 실행하고 [completeTwitterLogin]이 처리합니다.
  Future<Result<void>> startTwitterLogin() async {
    return _oauthService.launchTwitterPkce();
  }

  /// EN: Complete X (Twitter) PKCE login after the OAuth callback is received.
  ///     Retrieves and clears the stored code_verifier, validates the state nonce,
  ///     then exchanges the authorization code for JWT tokens.
  /// KO: OAuth 콜백 수신 후 X (Twitter) PKCE 로그인을 완료합니다.
  ///     저장된 code_verifier를 읽고 삭제하며, state nonce를 검증한 뒤,
  ///     인가 코드를 JWT 토큰으로 교환합니다.
  Future<Result<void>> completeTwitterLogin({
    required String code,
    String? stateParam,
  }) async {
    state = const AsyncLoading();

    // EN: Validate and consume the CSRF state nonce.
    // KO: CSRF state nonce를 검증하고 소모합니다.
    final stateValidation = await _oauthService.validateAndConsumeState(
      provider: OAuthProvider.twitter,
      callbackState: stateParam,
    );
    if (stateValidation is Err<void>) {
      state = AsyncError(stateValidation.failure, StackTrace.current);
      return Result.failure(stateValidation.failure);
    }

    // EN: Retrieve and immediately clear the code_verifier stored before browser launch.
    // KO: 브라우저 실행 전 저장했던 code_verifier를 읽고 즉시 삭제합니다.
    final codeVerifier = await _secureStorage.getAndClearTwitterCodeVerifier();
    if (codeVerifier == null || codeVerifier.isEmpty) {
      const failure = ValidationFailure(
        'Twitter PKCE code_verifier missing — '
        'session may have expired or the callback arrived after a restart.',
        code: 'twitter_code_verifier_missing',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    final result = await _repository.loginWithTwitter(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: 'https://api.noraneko.cc/oauth/x/callback',
    );
    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: OAuthProvider.twitter.id,
    );
  }

  /// EN: Native Google Sign-In — calls Google SDK then exchanges idToken with backend.
  ///     Returns [AuthFailure] with code 'sign_in_cancelled' if user dismisses the picker.
  ///     On EMAIL_ACCOUNT_CONFLICT (409), stores pending credentials and returns the
  ///     conflict failure so the UI can navigate to the conflict resolution page.
  /// KO: 네이티브 Google 로그인 — Google SDK 호출 후 idToken을 백엔드와 교환합니다.
  ///     사용자가 계정 선택기를 닫으면 code 'sign_in_cancelled' [AuthFailure]를 반환합니다.
  ///     EMAIL_ACCOUNT_CONFLICT(409) 시 pending 자격증명을 저장하고 충돌 실패를 반환하여
  ///     UI가 충돌 해결 화면으로 이동할 수 있도록 합니다.
  Future<Result<void>> loginWithGoogle() async {
    state = const AsyncLoading();
    _pendingInactiveRecovery = null;
    final tokenResult = await _nativeSocialLoginService.signInWithGoogle();
    if (tokenResult is Err<String>) {
      state = AsyncError(tokenResult.failure, StackTrace.current);
      return Result.failure(tokenResult.failure);
    }
    final idToken = (tokenResult as Success<String>).data;
    final authResult = await _repository.loginWithGoogle(idToken: idToken);

    // EN: Detect EMAIL_ACCOUNT_CONFLICT and store idToken for link-existing flow.
    // KO: EMAIL_ACCOUNT_CONFLICT 감지 시 link-existing 플로우를 위해 idToken을 저장합니다.
    final authFailure = authResult.failureOrNull;
    if (authFailure?.code == 'ACCOUNT_INACTIVE') {
      _pendingInactiveRecovery = _PendingInactiveRecovery(
        provider: OAuthProvider.google,
        token: idToken,
      );
    }
    if (authFailure != null && authFailure.code == 'EMAIL_ACCOUNT_CONFLICT') {
      var conflictEmail = '';
      if (authFailure is ValidationFailure) {
        conflictEmail = (authFailure.details?['email'] as String?) ?? '';
      }
      _pendingConflict = _PendingOAuthConflict(
        provider: OAuthProvider.google,
        token: idToken,
        conflictEmail: conflictEmail,
      );
    }

    return _handleAuthResult(
      authResult,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: OAuthProvider.google.id,
    );
  }

  /// EN: Restore an inactive Google account with the fresh proof obtained by
  ///     the immediately preceding login attempt.
  /// KO: 바로 앞선 로그인 시도에서 얻은 최신 Google 소유권 증명으로
  ///     비활성 계정을 복구합니다.
  Future<Result<void>> recoverWithGoogle() async {
    state = const AsyncLoading();
    final pending = _takeInactiveRecovery(OAuthProvider.google);
    if (pending == null) {
      const failure = ValidationFailure(
        'Google recovery proof is missing or expired.',
        code: 'recovery_proof_missing',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }
    final result = await _repository.recoverWithGoogle(idToken: pending.token);
    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: OAuthProvider.google.id,
    );
  }

  /// EN: Native Apple Sign-In — calls Apple SDK then exchanges identityToken with backend.
  ///     Returns [AuthFailure] with code 'sign_in_cancelled' if user dismisses the sheet.
  ///     On EMAIL_ACCOUNT_CONFLICT (409), stores pending credentials for link-existing flow.
  /// KO: 네이티브 Apple 로그인 — Apple SDK 호출 후 identityToken을 백엔드와 교환합니다.
  ///     사용자가 로그인 시트를 닫으면 code 'sign_in_cancelled' [AuthFailure]를 반환합니다.
  ///     EMAIL_ACCOUNT_CONFLICT(409) 시 link-existing 플로우를 위해 pending 자격증명을 저장합니다.
  Future<Result<void>> loginWithApple() async {
    state = const AsyncLoading();
    _pendingInactiveRecovery = null;
    final credentialResult = await _nativeSocialLoginService.signInWithApple();
    if (credentialResult is Err<AppleSignInCredentials>) {
      state = AsyncError(credentialResult.failure, StackTrace.current);
      return Result.failure(credentialResult.failure);
    }
    final credentials =
        (credentialResult as Success<AppleSignInCredentials>).data;
    final authResult = await _repository.loginWithApple(
      identityToken: credentials.identityToken,
      email: credentials.email,
      fullName: credentials.fullName,
    );

    // EN: Detect EMAIL_ACCOUNT_CONFLICT and store credentials for link-existing flow.
    // KO: EMAIL_ACCOUNT_CONFLICT 감지 시 link-existing 플로우를 위해 자격증명을 저장합니다.
    final appleAuthFailure = authResult.failureOrNull;
    if (appleAuthFailure?.code == 'ACCOUNT_INACTIVE') {
      _pendingInactiveRecovery = _PendingInactiveRecovery(
        provider: OAuthProvider.apple,
        token: credentials.identityToken,
        email: credentials.email,
        fullName: credentials.fullName,
      );
    }
    if (appleAuthFailure != null &&
        appleAuthFailure.code == 'EMAIL_ACCOUNT_CONFLICT') {
      var conflictEmail = '';
      if (appleAuthFailure is ValidationFailure) {
        conflictEmail = (appleAuthFailure.details?['email'] as String?) ?? '';
      }
      _pendingConflict = _PendingOAuthConflict(
        provider: OAuthProvider.apple,
        token: credentials.identityToken,
        conflictEmail: conflictEmail,
        appleEmail: credentials.email,
        fullName: credentials.fullName,
      );
    }

    return _handleAuthResult(
      authResult,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: OAuthProvider.apple.id,
    );
  }

  /// EN: Restore an inactive Apple account with the fresh proof obtained by
  ///     the immediately preceding login attempt.
  /// KO: 바로 앞선 로그인 시도에서 얻은 최신 Apple 소유권 증명으로
  ///     비활성 계정을 복구합니다.
  Future<Result<void>> recoverWithApple() async {
    state = const AsyncLoading();
    final pending = _takeInactiveRecovery(OAuthProvider.apple);
    if (pending == null) {
      const failure = ValidationFailure(
        'Apple recovery proof is missing or expired.',
        code: 'recovery_proof_missing',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }
    final result = await _repository.recoverWithApple(
      identityToken: pending.token,
      email: pending.email,
      fullName: pending.fullName,
    );
    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: OAuthProvider.apple.id,
    );
  }

  _PendingInactiveRecovery? _takeInactiveRecovery(OAuthProvider provider) {
    final pending = _pendingInactiveRecovery;
    _pendingInactiveRecovery = null;
    return pending?.provider == provider ? pending : null;
  }

  /// EN: Change password while authenticated.
  ///     On success, clears all local tokens and sets auth state to unauthenticated.
  ///     The UI must then navigate to the login screen.
  /// KO: 로그인 상태에서 비밀번호를 변경합니다.
  ///     성공 시 모든 로컬 토큰을 삭제하고 인증 상태를 미인증으로 설정합니다.
  ///     UI는 이후 로그인 화면으로 이동해야 합니다.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    // EN: Password changed — revoke all sessions. Clear all local data.
    // KO: 비밀번호 변경 완료 — 모든 세션 만료. 로컬 데이터 전체 삭제.
    await _clearAppCaches();
    await _clearSecureStorage();
    await _clearUserLocalStorage();
    _invalidateUserProviders();
    _authStateNotifier.setUnauthenticated();
    state = const AsyncData(null);
    return const Result.success(null);
  }

  /// EN: Request a password-reset email (Step 1 of forgot-password flow).
  /// KO: 비밀번호 재설정 이메일을 요청합니다 (비밀번호 분실 1단계).
  Future<Result<void>> requestPasswordReset({required String email}) async {
    state = const AsyncLoading();
    final result = await _repository.requestPasswordReset(email: email);
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    state = const AsyncData(null);
    return const Result.success(null);
  }

  /// EN: Confirm a password-reset with the email token + new password (Step 2).
  ///     On success, clears all local tokens and sets auth state to unauthenticated.
  /// KO: 이메일 토큰 + 새 비밀번호로 비밀번호 재설정을 확인합니다 (2단계).
  ///     성공 시 모든 로컬 토큰을 삭제하고 인증 상태를 미인증으로 설정합니다.
  Future<Result<void>> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.confirmPasswordReset(
      token: token,
      newPassword: newPassword,
    );
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    // EN: All sessions revoked after reset. Clear local data.
    // KO: 재설정 후 모든 세션 만료. 로컬 데이터 삭제.
    await _clearAppCaches();
    await _clearSecureStorage();
    await _clearUserLocalStorage();
    _invalidateUserProviders();
    _authStateNotifier.setUnauthenticated();
    state = const AsyncData(null);
    return const Result.success(null);
  }

  /// EN: Log out and clear ALL local data (tokens, caches, user-specific storage).
  /// KO: 로그아웃 시 모든 로컬 데이터를 삭제합니다 (토큰, 캐시, 사용자별 저장소).
  Future<void> logout() async {
    state = const AsyncLoading();
    final result = await _repository.logout();
    if (result is Err<void>) {
      AppLogger.warning(
        'Logout API failed; proceeding with local logout cleanup',
        data: result.failure,
        tag: 'AuthController',
      );
    }

    // EN: Best-effort remote push deactivation before clearing auth tokens.
    // KO: 인증 토큰 제거 전에 원격 푸시 등록 해제를 best-effort로 수행합니다.
    try {
      final remotePushService = _ref.read(remotePushServiceProvider);
      await remotePushService.deactivateCurrentDevice();
      await remotePushService.setAuthenticated(false);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to deactivate remote push registration on logout',
        data: e,
        tag: 'AuthController',
      );
      AppLogger.error(
        'Remote push deactivation error on logout',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthController',
      );
    }

    // EN: 1. Clear all cached data (gbt_cache namespace in SharedPreferences).
    // KO: 1. 모든 캐시 데이터 삭제 (SharedPreferences의 gbt_cache 네임스페이스).
    await _clearAppCaches();

    // EN: 2. Clear ALL secure storage (tokens, userId, verification keys).
    // KO: 2. 모든 보안 저장소 삭제 (토큰, userId, 인증 키).
    await _clearSecureStorage();

    // EN: 3. Clear user-specific local storage data.
    // KO: 3. 사용자별 로컬 저장소 데이터 삭제.
    await _clearUserLocalStorage();

    // EN: 4. Invalidate Riverpod providers holding user-specific state.
    // KO: 4. 사용자별 상태를 보유한 Riverpod 프로바이더 초기화.
    _invalidateUserProviders();

    // EN: 5. Set auth state to unauthenticated.
    // KO: 5. 인증 상태를 미인증으로 설정.
    _authStateNotifier.setUnauthenticated();
    _pendingConflict = null;
    state = const AsyncData(null);

    AppLogger.info(
      'Logout complete: all user data cleared',
      tag: 'AuthController',
    );
  }

  /// EN: Public getter for the conflict email — used by the UI to pre-fill the form.
  /// KO: 충돌 이메일 공개 getter — UI에서 폼을 미리 채우는 데 사용합니다.
  String? get pendingConflictEmail => _pendingConflict?.conflictEmail;

  /// EN: Complete the EMAIL_ACCOUNT_CONFLICT flow by linking the OAuth credential
  ///     to the existing local account identified by [_pendingConflict].
  ///     Clears the pending conflict on success.
  /// KO: [_pendingConflict]로 식별된 기존 로컬 계정에 OAuth 자격증명을 연동하여
  ///     EMAIL_ACCOUNT_CONFLICT 플로우를 완료합니다.
  ///     성공 시 pending conflict를 삭제합니다.
  Future<Result<void>> linkExistingOAuth({required String password}) async {
    final conflict = _pendingConflict;
    if (conflict == null) {
      const failure = ValidationFailure(
        'No pending OAuth conflict',
        code: 'no_pending_conflict',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    state = const AsyncLoading();
    Result<AuthTokens> result;

    if (conflict.provider == OAuthProvider.google) {
      result = await _repository.linkExistingWithGoogle(
        idToken: conflict.token,
        email: conflict.conflictEmail,
        password: password,
      );
    } else {
      // EN: Apple — pass cached email/fullName alongside identityToken.
      // KO: Apple — identityToken과 함께 캐시된 email/fullName을 전달합니다.
      result = await _repository.linkExistingWithApple(
        identityToken: conflict.token,
        email: conflict.conflictEmail,
        password: password,
        appleEmail: conflict.appleEmail,
        fullName: conflict.fullName,
      );
    }

    if (result is Success<AuthTokens>) {
      _pendingConflict = null;
    }

    return _handleAuthResult(
      result,
      analyticsType: _AuthAnalyticsType.login,
      analyticsMethod: conflict.provider.id,
    );
  }

  /// EN: Merge the current new OAuth account with an existing local account.
  ///     Called with the new OAuth account's Bearer token (already stored).
  ///     On success, tokens for the existing account replace the current ones.
  /// KO: 현재 신규 OAuth 계정을 기존 로컬 계정과 합칩니다.
  ///     이미 저장된 신규 OAuth 계정의 Bearer 토큰으로 호출됩니다.
  ///     성공 시 기존 계정의 토큰이 현재 토큰을 대체합니다.
  Future<Result<void>> connectExisting({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.connectExisting(
      email: email,
      password: password,
    );
    return _handleAuthResult(result);
  }

  /// EN: Merge the current new OAuth account with an existing Google account.
  ///     Calls Google SDK for proof of ownership, then POST /connect/existing/google.
  ///     On success, the existing Google account's tokens replace the current ones.
  /// KO: 현재 신규 OAuth 계정을 기존 Google 계정과 합칩니다.
  ///     소유권 증명을 위해 Google SDK를 호출한 뒤 POST /connect/existing/google을 호출합니다.
  ///     성공 시 기존 Google 계정의 토큰이 현재 토큰을 대체합니다.
  Future<Result<void>> connectExistingWithGoogle() async {
    final tokenResult = await _nativeSocialLoginService.signInWithGoogle();
    if (tokenResult is Err<String>) {
      state = AsyncError(tokenResult.failure, StackTrace.current);
      return Result.failure(tokenResult.failure);
    }
    final idToken = (tokenResult as Success<String>).data;
    state = const AsyncLoading();
    final result = await _repository.connectExistingWithGoogle(
      idToken: idToken,
    );
    return _handleAuthResult(result);
  }

  /// EN: Merge the current new OAuth account with an existing Apple account.
  ///     Calls Apple SDK for proof of ownership, then POST /connect/existing/apple.
  ///     On success, the existing Apple account's tokens replace the current ones.
  /// KO: 현재 신규 OAuth 계정을 기존 Apple 계정과 합칩니다.
  ///     소유권 증명을 위해 Apple SDK를 호출한 뒤 POST /connect/existing/apple을 호출합니다.
  ///     성공 시 기존 Apple 계정의 토큰이 현재 토큰을 대체합니다.
  Future<Result<void>> connectExistingWithApple() async {
    final credentialResult = await _nativeSocialLoginService.signInWithApple();
    if (credentialResult is Err<AppleSignInCredentials>) {
      state = AsyncError(credentialResult.failure, StackTrace.current);
      return Result.failure(credentialResult.failure);
    }
    final credentials =
        (credentialResult as Success<AppleSignInCredentials>).data;
    state = const AsyncLoading();
    final result = await _repository.connectExistingWithApple(
      identityToken: credentials.identityToken,
      email: credentials.email,
      fullName: credentials.fullName,
    );
    return _handleAuthResult(result);
  }

  /// EN: Connect Google OAuth to the current account from settings.
  ///     Calls Google SDK, then POST /connect/google with Bearer token.
  /// KO: 설정에서 Google OAuth를 현재 계정에 연결합니다.
  ///     Google SDK를 호출한 뒤 Bearer 토큰으로 POST /connect/google을 호출합니다.
  Future<Result<void>> connectGoogle() async {
    final tokenResult = await _nativeSocialLoginService.signInWithGoogle();
    if (tokenResult is Err<String>) {
      state = AsyncError(tokenResult.failure, StackTrace.current);
      return Result.failure(tokenResult.failure);
    }
    final idToken = (tokenResult as Success<String>).data;
    state = const AsyncLoading();
    final result = await _repository.connectGoogle(idToken: idToken);
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    state = const AsyncData(null);
    return const Result.success(null);
  }

  /// EN: Connect Apple OAuth to the current account from settings.
  ///     Calls Apple SDK, then POST /connect/apple with Bearer token.
  /// KO: 설정에서 Apple OAuth를 현재 계정에 연결합니다.
  ///     Apple SDK를 호출한 뒤 Bearer 토큰으로 POST /connect/apple을 호출합니다.
  Future<Result<void>> connectApple() async {
    final credentialResult = await _nativeSocialLoginService.signInWithApple();
    if (credentialResult is Err<AppleSignInCredentials>) {
      state = AsyncError(credentialResult.failure, StackTrace.current);
      return Result.failure(credentialResult.failure);
    }
    final credentials =
        (credentialResult as Success<AppleSignInCredentials>).data;
    state = const AsyncLoading();
    final result = await _repository.connectApple(
      identityToken: credentials.identityToken,
      email: credentials.email,
    );
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    state = const AsyncData(null);
    return const Result.success(null);
  }

  /// EN: Disconnect OAuth from the current account (DELETE /connect).
  ///     Returns CANNOT_DISCONNECT_OAUTH (409) if the account has no password set.
  /// KO: 현재 계정의 OAuth 연결을 해제합니다 (DELETE /connect).
  ///     비밀번호가 없는 계정이면 CANNOT_DISCONNECT_OAUTH(409)를 반환합니다.
  Future<Result<void>> disconnectOAuth() async {
    state = const AsyncLoading();
    final result = await _repository.disconnectOAuth();
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    state = const AsyncData(null);
    return const Result.success(null);
  }

  Future<Result<void>> _handleAuthResult(
    Result<dynamic> result, {
    _AuthAnalyticsType? analyticsType,
    String? analyticsMethod,
  }) async {
    if (result is Success<dynamic>) {
      final hasTokens = await _secureStorage.hasValidTokens();
      if (!hasTokens) {
        const failure = AuthFailure(
          'Authentication succeeded but tokens were not persisted',
          code: 'token_not_persisted',
        );
        state = AsyncError(failure, StackTrace.current);
        return Result.failure(failure);
      }
      await _clearAppCaches();
      _authStateNotifier.setAuthenticated();
      state = const AsyncData(null);
      unawaited(_requestNotificationPermissionOnLogin());
      if (analyticsType != null &&
          analyticsMethod != null &&
          analyticsMethod.isNotEmpty) {
        unawaited(
          _logAuthSuccess(
            analyticsType: analyticsType,
            method: analyticsMethod,
          ),
        );
      }
      return const Result.success(null);
    }

    if (result is Err<dynamic>) {
      final failure = result.failure;
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    state = AsyncError(
      const UnknownFailure('Unknown auth result', code: 'unknown_auth_result'),
      StackTrace.current,
    );
    return Result.failure(
      const UnknownFailure('Unknown auth result', code: 'unknown_auth_result'),
    );
  }

  Future<void> _logAuthSuccess({
    required _AuthAnalyticsType analyticsType,
    required String method,
  }) async {
    final analytics = _ref.read(analyticsServiceProvider);
    if (analyticsType == _AuthAnalyticsType.login) {
      await analytics.logLogin(method);
      return;
    }
    await analytics.logSignup(method);
  }

  /// EN: Prompt runtime notification permission after successful login.
  /// KO: 로그인 성공 직후 런타임 알림 권한을 요청합니다.
  Future<void> _requestNotificationPermissionOnLogin() async {
    try {
      final localStorage = await _localStorageFuture;
      final pushEnabled =
          localStorage.getBool(LocalStorageKeys.notificationsEnabled) ?? true;
      if (!pushEnabled) {
        return;
      }
      final remotePushService = _ref.read(remotePushServiceProvider);
      await remotePushService.initialize();
      // EN: setAuthenticated(true) is intentionally omitted here.
      //     It is called by remotePushBootstrapProvider's authStateProvider
      //     listener, which fires immediately after login sets AuthState.authenticated.
      //     Calling it again here would trigger a redundant syncRegistration().
      // KO: setAuthenticated(true)는 여기서 호출하지 않습니다.
      //     remotePushBootstrapProvider의 authStateProvider 리스너가
      //     로그인 직후 AuthState.authenticated로 전환될 때 이미 호출합니다.
      //     여기서 중복 호출하면 syncRegistration()이 불필요하게 추가 실행됩니다.
      await remotePushService.requestPermission();
      // EN: syncRegistration() after requestPermission() is intentional:
      //     on iOS, the APNs token may only become available AFTER the user
      //     grants permission, so we need an explicit sync at this point.
      // KO: requestPermission() 이후 syncRegistration() 호출은 의도적입니다.
      //     iOS에서는 사용자가 권한을 승인한 후에야 APNs 토큰을 얻을 수 있으므로
      //     이 시점에 명시적으로 동기화가 필요합니다.
      await remotePushService.syncRegistration();

      final localNotifier = _ref.read(localNotificationsServiceProvider);
      await localNotifier.requestPermissions();
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to request notification permission after login',
        data: e,
        tag: 'AuthController',
      );
      AppLogger.error(
        'Notification permission request error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthController',
      );
    }
  }

  /// EN: Clear app cache namespace on auth transitions.
  /// KO: 인증 상태 전환 시 앱 캐시 네임스페이스를 초기화합니다.
  Future<void> _clearAppCaches() async {
    try {
      final cacheManager = await _cacheManagerFuture;
      await cacheManager.clearAll();
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to clear app caches',
        data: e,
        tag: 'AuthController',
      );
      AppLogger.error(
        'App cache clear error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthController',
      );
    }
  }

  /// EN: Clear ALL data from secure storage (tokens, userId, verification keys).
  /// KO: 보안 저장소의 모든 데이터 삭제 (토큰, userId, 인증 키).
  Future<void> _clearSecureStorage() async {
    try {
      await _secureStorage.clearAll();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear secure storage on logout',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthController',
      );
    }
  }

  /// EN: Clear user-specific data from local storage while preserving app settings.
  /// KO: 앱 설정은 유지하면서 사용자별 로컬 저장소 데이터를 삭제합니다.
  Future<void> _clearUserLocalStorage() async {
    try {
      final localStorage = await _localStorageFuture;
      await _clearPostComposeDrafts(localStorage);
      await Future.wait([
        localStorage.remove(LocalStorageKeys.selectedProjectId),
        localStorage.remove(LocalStorageKeys.selectedProjectKey),
        localStorage.remove(LocalStorageKeys.selectedUnitIds),
        localStorage.remove(LocalStorageKeys.recentSearches),
        localStorage.remove(LocalStorageKeys.lastSyncTime),
        localStorage.remove(LocalStorageKeys.cachedHomeData),
        localStorage.remove(LocalStorageKeys.notificationDeviceId),
        localStorage.remove(LocalStorageKeys.notificationDeviceIdLegacy),
        localStorage.remove(LocalStorageKeys.notificationPushToken),
        localStorage.remove(LocalStorageKeys.userConsents),
        localStorage.remove(LocalStorageKeys.autoTranslationEnabled),
        localStorage.remove(LocalStorageKeys.privacyRequestHistory),
      ]);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear user local storage on logout',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthController',
      );
    }
  }

  Future<void> _clearPostComposeDrafts(LocalStorage localStorage) async {
    final draftKeys = localStorage
        .getKeys()
        .where((key) {
          return key.startsWith(_kPostComposeCreateDraftKeyPrefix) ||
              key.startsWith(_kPostComposeEditDraftKeyPrefix);
        })
        .toList(growable: false);

    if (draftKeys.isEmpty) {
      return;
    }

    await Future.wait(draftKeys.map(localStorage.remove));
  }

  /// EN: Invalidate Riverpod providers that hold user-specific data.
  /// KO: 사용자별 데이터를 보유한 Riverpod 프로바이더를 초기화합니다.
  void _invalidateUserProviders() {
    try {
      // EN: Reset project/unit selection state.
      // KO: 프로젝트/유닛 선택 상태 초기화.
      _ref.read(selectedProjectKeyProvider.notifier).state = null;
      _ref.read(selectedProjectIdProvider.notifier).state = null;
      _ref.read(selectedUnitIdsProvider.notifier).state = [];
      _ref.read(currentNavIndexProvider.notifier).state = 0;

      // EN: Invalidate user profile providers.
      // KO: 사용자 프로필 프로바이더 초기화.
      _ref.invalidate(userProfileControllerProvider);
      _ref.invalidate(notificationSettingsControllerProvider);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to invalidate providers on logout',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthController',
      );
    }
  }
}

/// EN: Temporarily holds OAuth credentials during EMAIL_ACCOUNT_CONFLICT flow.
///     Cleared after a successful link-existing or on logout.
/// KO: EMAIL_ACCOUNT_CONFLICT 플로우 중 OAuth 자격증명을 임시 보관합니다.
///     link-existing 성공 또는 로그아웃 시 삭제됩니다.
class _PendingOAuthConflict {
  const _PendingOAuthConflict({
    required this.provider,
    required this.token,
    required this.conflictEmail,
    this.appleEmail,
    this.fullName,
  });

  final OAuthProvider provider;

  /// EN: idToken (Google) or identityToken (Apple).
  /// KO: idToken (Google) 또는 identityToken (Apple).
  final String token;

  /// EN: Email from EMAIL_ACCOUNT_CONFLICT error details.
  /// KO: EMAIL_ACCOUNT_CONFLICT 에러 details의 이메일.
  final String conflictEmail;

  final String? appleEmail;
  final String? fullName;
}

/// EN: In-memory, single-use proof for explicit inactive-account recovery.
/// KO: 명시적 비활성 계정 복구용 메모리 내 1회성 소유권 증명.
class _PendingInactiveRecovery {
  const _PendingInactiveRecovery({
    required this.provider,
    required this.token,
    this.email,
    this.fullName,
  });

  final OAuthProvider provider;
  final String token;
  final String? email;
  final String? fullName;
}

enum _AuthAnalyticsType { login, signup }

/// EN: Provider for AuthOAuthService.
/// KO: AuthOAuthService 프로바이더.
final authOAuthServiceProvider = Provider<AuthOAuthService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthOAuthService(secureStorage: secureStorage);
});

/// EN: Provider for NativeSocialLoginService.
/// KO: NativeSocialLoginService 프로바이더.
final nativeSocialLoginServiceProvider = Provider<NativeSocialLoginService>((
  ref,
) {
  final secureStorage = ref.watch(secureStorageProvider);
  return NativeSocialLoginService(secureStorage: secureStorage);
});

/// EN: Provider for AuthRepository.
/// KO: AuthRepository 프로바이더.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(apiClient),
    secureStorage: secureStorage,
  );
});

/// EN: Provider for AuthController.
/// KO: AuthController 프로바이더.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      final authStateNotifier = ref.read(authStateProvider.notifier);
      final oauthService = ref.watch(authOAuthServiceProvider);
      final nativeSocialLoginService = ref.watch(
        nativeSocialLoginServiceProvider,
      );
      final cacheManagerFuture = ref.watch(cacheManagerProvider.future);
      final secureStorage = ref.watch(secureStorageProvider);
      final localStorageFuture = ref.watch(localStorageProvider.future);
      return AuthController(
        repository: repository,
        authStateNotifier: authStateNotifier,
        oauthService: oauthService,
        nativeSocialLoginService: nativeSocialLoginService,
        cacheManagerFuture: cacheManagerFuture,
        secureStorage: secureStorage,
        localStorageFuture: localStorageFuture,
        ref: ref,
      );
    });
