/// EN: Request body for POST /auth/oauth2/connect/existing.
///     Called with Bearer token after new OAuth account is created (200),
///     when the user indicates they have an existing local account to merge.
/// KO: POST /auth/oauth2/connect/existing 요청 바디.
///     200으로 신규 OAuth 계정이 생성된 후, 사용자가 기존 로컬 계정 합치기를
///     원할 때 Bearer 토큰과 함께 호출합니다.
library;

class ConnectExistingRequest {
  const ConnectExistingRequest({required this.email, required this.password});

  /// EN: Email of the existing local account to merge with.
  /// KO: 합칠 기존 로컬 계정의 이메일.
  final String email;

  /// EN: Password of the existing local account.
  /// KO: 기존 로컬 계정의 비밀번호.
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
