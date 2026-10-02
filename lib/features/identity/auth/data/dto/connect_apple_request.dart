/// EN: Request body for POST /auth/oauth2/connect/apple.
///     Called with Bearer token from settings to link Apple to the current account.
/// KO: POST /auth/oauth2/connect/apple 요청 바디.
///     설정에서 현재 계정에 Apple을 연결할 때 Bearer 토큰과 함께 호출합니다.
library;

class ConnectAppleRequest {
  const ConnectAppleRequest({required this.identityToken, this.email});

  /// EN: Apple identity token (JWT) from Sign in with Apple SDK.
  /// KO: Sign in with Apple SDK에서 받은 Apple identity 토큰 (JWT).
  final String identityToken;

  /// EN: Apple-provided email (cached from first sign-in, optional).
  /// KO: Apple이 제공한 이메일 (최초 로그인 시 캐시, 선택).
  final String? email;

  Map<String, dynamic> toJson() => {
    'identityToken': identityToken,
    if (email != null) 'email': email,
  };
}
