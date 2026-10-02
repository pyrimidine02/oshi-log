/// EN: Request body for POST /auth/oauth2/connect/existing/apple.
///     Called with Bearer token of the new OAuth account when the user
///     proves ownership of an existing Apple account on the merge page.
///     email and fullName are cached locally — Apple only provides them once.
/// KO: POST /auth/oauth2/connect/existing/apple 요청 바디.
///     머지 페이지에서 기존 Apple 계정 소유권을 인증할 때
///     신규 OAuth 계정의 Bearer 토큰과 함께 호출합니다.
///     email과 fullName은 로컬 캐시에서 전달됩니다 — Apple은 최초 1회만 제공합니다.
library;

class ConnectExistingAppleRequest {
  const ConnectExistingAppleRequest({
    required this.identityToken,
    this.email,
    this.fullName,
  });

  /// EN: Apple identity token from the native Sign in with Apple SDK.
  /// KO: 네이티브 Sign in with Apple SDK에서 받은 identity 토큰.
  final String identityToken;

  /// EN: Apple-provided email (only available on first sign-in).
  /// KO: Apple이 제공한 이메일 (최초 로그인 시에만 제공).
  final String? email;

  /// EN: User's full name from Apple (only available on first sign-in).
  /// KO: Apple에서 받은 전체 이름 (최초 로그인 시에만 제공).
  final String? fullName;

  Map<String, dynamic> toJson() => {
    'identity_token': identityToken,
    if (email != null) 'email': email,
    if (fullName != null) 'full_name': fullName,
  };
}
