/// EN: Request body for POST /auth/oauth2/connect/existing/google.
///     Called with Bearer token of the new OAuth account when the user
///     proves ownership of an existing Google account on the merge page.
/// KO: POST /auth/oauth2/connect/existing/google 요청 바디.
///     머지 페이지에서 기존 Google 계정 소유권을 인증할 때
///     신규 OAuth 계정의 Bearer 토큰과 함께 호출합니다.
library;

class ConnectExistingGoogleRequest {
  const ConnectExistingGoogleRequest({required this.idToken});

  /// EN: Google ID token obtained from the native Google Sign-In SDK.
  /// KO: 네이티브 Google Sign-In SDK에서 받은 ID 토큰.
  final String idToken;

  Map<String, dynamic> toJson() => {'id_token': idToken};
}
