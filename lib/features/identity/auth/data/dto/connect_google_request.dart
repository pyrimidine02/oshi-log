/// EN: Request body for POST /auth/oauth2/connect/google.
///     Called with Bearer token from settings to link Google to the current account.
/// KO: POST /auth/oauth2/connect/google 요청 바디.
///     설정에서 현재 계정에 Google을 연결할 때 Bearer 토큰과 함께 호출합니다.
library;

class ConnectGoogleRequest {
  const ConnectGoogleRequest({required this.idToken});

  /// EN: Google ID token from the Sign-In SDK.
  /// KO: Sign-In SDK에서 받은 Google ID 토큰.
  final String idToken;

  Map<String, dynamic> toJson() => {'idToken': idToken};
}
