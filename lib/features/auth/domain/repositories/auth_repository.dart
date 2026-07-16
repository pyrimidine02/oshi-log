/// EN: Authentication repository interface.
/// KO: 인증 리포지토리 인터페이스.
library;

import '../../../../core/utils/result.dart';
import '../entities/auth_tokens.dart';
import '../entities/oauth_provider.dart';
import '../entities/register_consent.dart';
import '../entities/register_result.dart';

/// EN: Contract for authentication data operations.
/// KO: 인증 데이터 작업을 위한 계약.
abstract class AuthRepository {
  Future<Result<AuthTokens>> login({
    required String username,
    required String password,
  });

  /// EN: Restore an inactive password account with explicit user consent.
  /// KO: 사용자의 명시적 동의 후 비활성 비밀번호 계정을 복구합니다.
  Future<Result<AuthTokens>> recoverWithPassword({
    required String email,
    required String password,
  });

  /// EN: Restore an inactive Google account with a fresh provider token.
  /// KO: 새 공급자 토큰으로 비활성 Google 계정을 복구합니다.
  Future<Result<AuthTokens>> recoverWithGoogle({required String idToken});

  /// EN: Restore an inactive Apple account with fresh provider credentials.
  /// KO: 새 공급자 자격 증명으로 비활성 Apple 계정을 복구합니다.
  Future<Result<AuthTokens>> recoverWithApple({
    required String identityToken,
    String? email,
    String? fullName,
  });

  /// EN: Register a new account.
  ///     Returns [RegisterResult] indicating whether email verification is needed.
  ///     When [RegisterResult.verificationRequired] is false, tokens are already
  ///     persisted and the user can be set to authenticated immediately.
  /// KO: 새 계정을 등록합니다.
  ///     이메일 인증 필요 여부를 나타내는 [RegisterResult]를 반환합니다.
  ///     [RegisterResult.verificationRequired]가 false이면 토큰이 이미 저장되어 있고
  ///     즉시 인증 상태로 전환할 수 있습니다.
  Future<Result<RegisterResult>> register({
    required String username,
    required String password,
    required String nickname,
    List<RegisterConsent> consents = const [],
  });

  /// EN: Send (or resend) a verification email.
  ///     Returns the earliest time the user may request another email,
  ///     or null if the server did not specify a cooldown.
  /// KO: 인증 이메일을 발송(또는 재발송)합니다.
  ///     사용자가 다음 이메일을 요청할 수 있는 최초 시간을 반환하며,
  ///     서버가 쿨다운을 지정하지 않은 경우 null을 반환합니다.
  Future<Result<DateTime?>> sendEmailVerification({required String email});

  /// EN: Confirm email verification token.
  /// KO: 이메일 인증 토큰을 확인합니다.
  Future<Result<void>> confirmEmailVerification({required String token});

  Future<Result<AuthTokens>> refresh();

  Future<Result<void>> logout();

  /// EN: Change password while authenticated.
  ///     On success the caller must clear all local tokens and navigate to login.
  /// KO: 로그인 상태에서 비밀번호를 변경합니다.
  ///     성공 시 호출자는 모든 로컬 토큰을 삭제하고 로그인 화면으로 이동해야 합니다.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// EN: Request a password-reset email (Step 1 of forgot-password flow).
  ///     Always returns success even if the email is not registered.
  /// KO: 비밀번호 재설정 이메일을 요청합니다 (비밀번호 분실 1단계).
  ///     이메일이 미등록이어도 항상 성공을 반환합니다.
  Future<Result<void>> requestPasswordReset({required String email});

  /// EN: Confirm a password-reset with the email token + new password (Step 2).
  ///     On success the caller must clear all local tokens and navigate to login.
  /// KO: 이메일 토큰 + 새 비밀번호로 비밀번호 재설정을 확인합니다 (2단계).
  ///     성공 시 호출자는 모든 로컬 토큰을 삭제하고 로그인 화면으로 이동해야 합니다.
  Future<Result<void>> confirmPasswordReset({
    required String token,
    required String newPassword,
  });

  /// EN: Exchange OAuth authorization code for tokens.
  /// KO: OAuth 인가 코드를 토큰으로 교환.
  Future<Result<AuthTokens>> exchangeOAuthCode({
    required OAuthProvider provider,
    required String code,
    String? state,
  });

  /// EN: Native Google Sign-In — exchange Google ID token for JWT pair.
  ///     The idToken is obtained from the Google Sign-In SDK (not a browser redirect).
  /// KO: 네이티브 Google 로그인 — Google SDK에서 받은 ID 토큰을 JWT 쌍으로 교환합니다.
  ///     idToken은 브라우저 리다이렉트가 아닌 Google Sign-In SDK에서 직접 수령합니다.
  Future<Result<AuthTokens>> loginWithGoogle({required String idToken});

  /// EN: Native Apple Sign-In — exchange Apple identity token for JWT pair.
  ///     email and fullName are cached locally because Apple provides them
  ///     only on the very first sign-in.
  /// KO: 네이티브 Apple 로그인 — Apple identity 토큰을 JWT 쌍으로 교환합니다.
  ///     Apple은 최초 로그인 시에만 email/fullName을 제공하므로 로컬 캐시에서 전달합니다.
  Future<Result<AuthTokens>> loginWithApple({
    required String identityToken,
    String? email,
    String? fullName,
  });

  /// EN: X (Twitter) PKCE login — exchange authorization code and verifier for JWT pair.
  ///     redirectUri must exactly match the value used in the authorization request.
  /// KO: X (Twitter) PKCE 로그인 — 인가 코드와 verifier를 JWT 쌍으로 교환합니다.
  ///     redirectUri는 인가 요청 시 사용한 값과 정확히 일치해야 합니다.
  Future<Result<AuthTokens>> loginWithTwitter({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  });

  /// EN: Link Google OAuth to an existing local account after EMAIL_ACCOUNT_CONFLICT (409).
  ///     The idToken is the same one that triggered the conflict.
  ///     On success, tokens for the existing account are persisted and returned.
  /// KO: EMAIL_ACCOUNT_CONFLICT(409) 후 기존 로컬 계정에 Google OAuth를 연동합니다.
  ///     idToken은 충돌을 발생시킨 것과 동일한 토큰입니다.
  ///     성공 시 기존 계정의 토큰이 저장되고 반환됩니다.
  Future<Result<AuthTokens>> linkExistingWithGoogle({
    required String idToken,
    required String email,
    required String password,
  });

  /// EN: Link Apple OAuth to an existing local account after EMAIL_ACCOUNT_CONFLICT (409).
  ///     email is the local account email; appleEmail is the Apple-provided cached email.
  /// KO: EMAIL_ACCOUNT_CONFLICT(409) 후 기존 로컬 계정에 Apple OAuth를 연동합니다.
  ///     email은 로컬 계정 이메일이고, appleEmail은 Apple이 제공한 캐시된 이메일입니다.
  Future<Result<AuthTokens>> linkExistingWithApple({
    required String identityToken,
    required String email,
    required String password,
    String? appleEmail,
    String? fullName,
  });

  /// EN: Merge the current new OAuth account with an existing local account.
  ///     Called with the new OAuth account's Bearer token.
  ///     On success, the existing account's tokens replace the current ones.
  /// KO: 현재 신규 OAuth 계정을 기존 로컬 계정과 합칩니다.
  ///     신규 OAuth 계정의 Bearer 토큰으로 호출합니다.
  ///     성공 시 기존 계정의 토큰이 현재 토큰을 대체합니다.
  Future<Result<AuthTokens>> connectExisting({
    required String email,
    required String password,
  });

  /// EN: Merge the current new OAuth account with an existing Google account.
  ///     The user proves ownership via the native Google Sign-In SDK.
  ///     On success, the existing account's tokens replace the current ones.
  /// KO: 현재 신규 OAuth 계정을 기존 Google 계정과 합칩니다.
  ///     네이티브 Google Sign-In SDK로 소유권을 인증합니다.
  ///     성공 시 기존 계정의 토큰이 현재 토큰을 대체합니다.
  Future<Result<AuthTokens>> connectExistingWithGoogle({
    required String idToken,
  });

  /// EN: Merge the current new OAuth account with an existing Apple account.
  ///     The user proves ownership via the native Sign in with Apple SDK.
  ///     email and fullName are passed from local cache (Apple provides once only).
  ///     On success, the existing account's tokens replace the current ones.
  /// KO: 현재 신규 OAuth 계정을 기존 Apple 계정과 합칩니다.
  ///     네이티브 Sign in with Apple SDK로 소유권을 인증합니다.
  ///     email, fullName은 로컬 캐시에서 전달됩니다 (Apple은 최초 1회만 제공).
  ///     성공 시 기존 계정의 토큰이 현재 토큰을 대체합니다.
  Future<Result<AuthTokens>> connectExistingWithApple({
    required String identityToken,
    String? email,
    String? fullName,
  });

  /// EN: Link Google OAuth to the current authenticated account (from settings).
  /// KO: 설정 화면에서 현재 인증된 계정에 Google OAuth를 연결합니다.
  Future<Result<void>> connectGoogle({required String idToken});

  /// EN: Link Apple OAuth to the current authenticated account (from settings).
  /// KO: 설정 화면에서 현재 인증된 계정에 Apple OAuth를 연결합니다.
  Future<Result<void>> connectApple({
    required String identityToken,
    String? email,
  });

  /// EN: Disconnect any OAuth provider from the current account (from settings).
  ///     Returns CANNOT_DISCONNECT_OAUTH (409) if the account has no password.
  ///     Returns 200 even if no OAuth was connected (idempotent).
  /// KO: 설정 화면에서 현재 계정의 OAuth 연결을 해제합니다.
  ///     비밀번호가 없는 계정이면 CANNOT_DISCONNECT_OAUTH(409)를 반환합니다.
  ///     OAuth 연결이 없어도 200을 반환합니다 (멱등성 보장).
  Future<Result<void>> disconnectOAuth();
}
