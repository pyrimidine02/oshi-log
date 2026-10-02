/// EN: Request DTO for Google native sign-in (POST /api/v1/auth/oauth2/google).
/// KO: Google 네이티브 로그인 요청 DTO (POST /api/v1/auth/oauth2/google).
library;

/// EN: Carries the Google ID token obtained from the Google Sign-In SDK.
/// KO: Google Sign-In SDK에서 받은 ID 토큰을 전달합니다.
class GoogleOAuthRequest {
  const GoogleOAuthRequest({required this.idToken});

  /// EN: Google ID token from the native SDK.
  /// KO: 네이티브 SDK에서 받은 Google ID 토큰.
  final String idToken;

  Map<String, dynamic> toJson() => {'idToken': idToken};
}
