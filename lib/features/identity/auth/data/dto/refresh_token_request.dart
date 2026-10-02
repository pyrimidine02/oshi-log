/// EN: Refresh token request DTO.
/// KO: 리프레시 토큰 요청 DTO.
library;

/// EN: DTO for refresh token payload.
/// KO: 리프레시 토큰 페이로드 DTO.
class RefreshTokenRequest {
  const RefreshTokenRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}
