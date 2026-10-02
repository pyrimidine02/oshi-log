/// EN: Request body for POST /auth/oauth2/apple/link-existing.
/// KO: POST /auth/oauth2/apple/link-existing 요청 바디.
library;

class AppleLinkExistingRequest {
  const AppleLinkExistingRequest({
    required this.identityToken,
    required this.email,
    required this.password,
    this.appleEmail,
    this.fullName,
  });

  /// EN: Apple identity token (JWT) from Sign in with Apple SDK.
  /// KO: Sign in with Apple SDK에서 받은 Apple identity 토큰 (JWT).
  final String identityToken;

  /// EN: Email of the existing local account to link with.
  /// KO: 연동할 기존 로컬 계정의 이메일.
  final String email;

  /// EN: Password of the existing local account.
  /// KO: 기존 로컬 계정의 비밀번호.
  final String password;

  /// EN: Apple-provided email (cached from first sign-in, optional).
  /// KO: Apple이 제공한 이메일 (최초 로그인 시 캐시, 선택).
  final String? appleEmail;

  /// EN: User's full name (cached from first sign-in, optional).
  /// KO: 사용자 전체 이름 (최초 로그인 시 캐시, 선택).
  final String? fullName;

  Map<String, dynamic> toJson() => {
    'identityToken': identityToken,
    'email': email,
    'password': password,
    if (appleEmail != null) 'appleEmail': appleEmail,
    if (fullName != null) 'fullName': fullName,
  };
}
