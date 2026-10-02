/// EN: Request body for POST /auth/oauth2/google/link-existing.
/// KO: POST /auth/oauth2/google/link-existing 요청 바디.
library;

class GoogleLinkExistingRequest {
  const GoogleLinkExistingRequest({
    required this.idToken,
    required this.email,
    required this.password,
  });

  /// EN: Google ID token from the Sign-In SDK.
  /// KO: Sign-In SDK에서 받은 Google ID 토큰.
  final String idToken;

  /// EN: Email of the existing local account to link with.
  /// KO: 연동할 기존 로컬 계정의 이메일 (EMAIL_ACCOUNT_CONFLICT의 details.email).
  final String email;

  /// EN: Password of the existing local account.
  /// KO: 기존 로컬 계정의 비밀번호.
  final String password;

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    'email': email,
    'password': password,
  };
}
