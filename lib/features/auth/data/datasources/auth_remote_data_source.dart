/// EN: Remote data source for authentication.
/// KO: 인증용 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/oauth_provider.dart';
import '../dto/apple_link_existing_request.dart';
import '../dto/apple_oauth_request.dart';
import '../dto/account_recovery_password_request.dart';
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

/// EN: Handles authentication API requests.
/// KO: 인증 API 요청을 처리합니다.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<TokenResponse>> login(LoginRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.login,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Restores an inactive password account after explicit user consent.
  /// KO: 사용자가 명시적으로 동의한 후 비활성 비밀번호 계정을 복구합니다.
  Future<Result<TokenResponse>> recoverWithPassword(
    AccountRecoveryPasswordRequest request,
  ) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.accountRecoveryPassword,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Restores an inactive Google account after provider verification.
  /// KO: Google 소유권 확인 후 비활성 계정을 복구합니다.
  Future<Result<TokenResponse>> recoverWithGoogle(GoogleOAuthRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.accountRecoveryGoogle,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Restores an inactive Apple account after provider verification.
  /// KO: Apple 소유권 확인 후 비활성 계정을 복구합니다.
  Future<Result<TokenResponse>> recoverWithApple(AppleOAuthRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.accountRecoveryApple,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<RegisterResponse>> register(RegisterRequest request) {
    return _apiClient.post<RegisterResponse>(
      ApiEndpoints.register,
      data: request.toJson(),
      fromJson: (json) =>
          RegisterResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Send (or resend) a verification email.
  /// KO: 인증 이메일을 발송(또는 재발송)합니다.
  Future<Result<EmailVerificationResponse>> sendEmailVerification(
    EmailVerificationRequest request,
  ) {
    return _apiClient.post<EmailVerificationResponse>(
      ApiEndpoints.emailVerifications,
      data: request.toJson(),
      fromJson: (json) => json is Map<String, dynamic>
          ? EmailVerificationResponse.fromJson(json)
          : const EmailVerificationResponse(),
    );
  }

  /// EN: Confirm verification token.
  /// KO: 이메일 인증 토큰을 확인합니다.
  Future<Result<void>> confirmEmailVerification(
    EmailVerificationConfirmRequest request,
  ) {
    return _apiClient.post<void>(
      ApiEndpoints.emailVerificationsConfirm,
      data: request.toJson(),
      fromJson: (_) {},
    );
  }

  Future<Result<TokenResponse>> refresh(RefreshTokenRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.refresh,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<void>> logout(RefreshTokenRequest? request) {
    return _apiClient.post<void>(ApiEndpoints.logout, data: request?.toJson());
  }

  /// EN: Change password for the authenticated user (PATCH /users/me/password).
  /// KO: 인증된 사용자의 비밀번호를 변경합니다 (PATCH /users/me/password).
  Future<Result<ChangePasswordResponse>> changePassword(
    ChangePasswordRequest request,
  ) {
    return _apiClient.patch<ChangePasswordResponse>(
      ApiEndpoints.userMePassword,
      data: request.toJson(),
      fromJson: (json) =>
          ChangePasswordResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Request a password-reset email (POST /auth/password-reset-requests).
  /// KO: 비밀번호 재설정 이메일을 요청합니다 (POST /auth/password-reset-requests).
  Future<Result<PasswordResetRequestResponse>> requestPasswordReset(
    PasswordResetRequestDto request,
  ) {
    return _apiClient.post<PasswordResetRequestResponse>(
      ApiEndpoints.passwordResetRequests,
      data: request.toJson(),
      fromJson: (json) =>
          PasswordResetRequestResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Confirm password-reset with token + new password
  ///     (POST /auth/password-reset-requests/confirm).
  /// KO: 토큰 + 새 비밀번호로 비밀번호 재설정을 확인합니다
  ///     (POST /auth/password-reset-requests/confirm).
  Future<Result<PasswordResetConfirmResponse>> confirmPasswordReset(
    PasswordResetConfirmRequest request,
  ) {
    return _apiClient.post<PasswordResetConfirmResponse>(
      ApiEndpoints.passwordResetRequestsConfirm,
      data: request.toJson(),
      fromJson: (json) =>
          PasswordResetConfirmResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Exchange OAuth authorization code for tokens.
  /// KO: OAuth 인가 코드를 토큰으로 교환합니다.
  Future<Result<TokenResponse>> exchangeOAuthCode({
    required OAuthProvider provider,
    required String code,
    String? state,
  }) {
    return _apiClient.get<TokenResponse>(
      ApiEndpoints.oauthCallback(provider.id),
      queryParameters: {'code': code, if (state != null) 'state': state},
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Native Google Sign-In — exchange Google ID token for JWT pair.
  /// KO: 네이티브 Google 로그인 — Google ID 토큰을 JWT 쌍으로 교환합니다.
  Future<Result<TokenResponse>> loginWithGoogle(GoogleOAuthRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthGoogle,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Native Apple Sign-In — exchange Apple identity token for JWT pair.
  /// KO: 네이티브 Apple 로그인 — Apple identity 토큰을 JWT 쌍으로 교환합니다.
  Future<Result<TokenResponse>> loginWithApple(AppleOAuthRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthApple,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: X (Twitter) PKCE login — exchange authorization code + verifier for JWT pair.
  /// KO: X (Twitter) PKCE 로그인 — 인가 코드 + verifier를 JWT 쌍으로 교환합니다.
  Future<Result<TokenResponse>> loginWithTwitter(TwitterOAuthRequest request) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthTwitter,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Link Google OAuth to an existing local account (POST /google/link-existing).
  /// KO: 기존 로컬 계정에 Google OAuth 연동 (POST /google/link-existing).
  Future<Result<TokenResponse>> linkExistingWithGoogle(
    GoogleLinkExistingRequest request,
  ) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthGoogleLinkExisting,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Link Apple OAuth to an existing local account (POST /apple/link-existing).
  /// KO: 기존 로컬 계정에 Apple OAuth 연동 (POST /apple/link-existing).
  Future<Result<TokenResponse>> linkExistingWithApple(
    AppleLinkExistingRequest request,
  ) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthAppleLinkExisting,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Merge current OAuth account with existing local account (POST /connect/existing).
  /// KO: 현재 OAuth 계정과 기존 로컬 계정 합치기 (POST /connect/existing).
  Future<Result<TokenResponse>> connectExisting(
    ConnectExistingRequest request,
  ) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthConnectExisting,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Merge current OAuth account with an existing Google account on the merge page.
  ///     Authenticates via native Google SDK token (POST /connect/existing/google).
  /// KO: 머지 페이지에서 현재 OAuth 계정을 기존 Google 계정과 합치기.
  ///     네이티브 Google SDK 토큰으로 인증합니다 (POST /connect/existing/google).
  Future<Result<TokenResponse>> connectExistingWithGoogle(
    ConnectExistingGoogleRequest request,
  ) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthConnectExistingGoogle,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Merge current OAuth account with an existing Apple account on the merge page.
  ///     Authenticates via native Sign in with Apple token (POST /connect/existing/apple).
  /// KO: 머지 페이지에서 현재 OAuth 계정을 기존 Apple 계정과 합치기.
  ///     네이티브 Sign in with Apple 토큰으로 인증합니다 (POST /connect/existing/apple).
  Future<Result<TokenResponse>> connectExistingWithApple(
    ConnectExistingAppleRequest request,
  ) {
    return _apiClient.post<TokenResponse>(
      ApiEndpoints.oauthConnectExistingApple,
      data: request.toJson(),
      fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Link Google to the current account from settings (POST /connect/google).
  /// KO: 설정에서 현재 계정에 Google 연결 (POST /connect/google).
  Future<Result<void>> connectGoogle(ConnectGoogleRequest request) {
    return _apiClient.post<void>(
      ApiEndpoints.oauthConnectGoogle,
      data: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// EN: Link Apple to the current account from settings (POST /connect/apple).
  /// KO: 설정에서 현재 계정에 Apple 연결 (POST /connect/apple).
  Future<Result<void>> connectApple(ConnectAppleRequest request) {
    return _apiClient.post<void>(
      ApiEndpoints.oauthConnectApple,
      data: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// EN: Fetch current legal policy list — public endpoint, no auth required.
  ///     Response is a JSON array of policy objects or a wrapper with a list field.
  /// KO: 현재 법률 정책 목록 조회 — 공개 엔드포인트, 인증 불필요.
  ///     응답은 정책 객체 배열 또는 목록 필드를 가진 래퍼 JSON입니다.
  Future<Result<List<Map<String, dynamic>>>> fetchLegalPolicies() {
    return _apiClient.get<List<Map<String, dynamic>>>(
      ApiEndpoints.legalPolicies,
      fromJson: (json) {
        if (json is List) {
          return json.whereType<Map<String, dynamic>>().toList(growable: false);
        }
        if (json is Map<String, dynamic>) {
          final items =
              json['policies'] ??
              json['items'] ??
              json['data'] ??
              json['content'];
          if (items is List) {
            return items.whereType<Map<String, dynamic>>().toList(
              growable: false,
            );
          }
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }

  /// EN: Disconnect OAuth from the current account (DELETE /connect).
  /// KO: 현재 계정의 OAuth 연결 해제 (DELETE /connect).
  Future<Result<void>> disconnectOAuth() {
    return _apiClient.delete<void>(
      ApiEndpoints.oauthDisconnect,
      fromJson: (_) {},
    );
  }
}
