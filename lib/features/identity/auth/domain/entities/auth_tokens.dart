/// EN: Authentication tokens domain model.
/// KO: 인증 토큰 도메인 모델.
library;

/// EN: Domain model for access/refresh tokens.
/// KO: 액세스/리프레시 토큰 도메인 모델.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final String? tokenType;

  /// EN: Create domain tokens from API response.
  /// KO: API 응답으로부터 도메인 토큰 생성.

  /// EN: Whether the access token is expired.
  /// KO: 액세스 토큰이 만료되었는지 여부.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
