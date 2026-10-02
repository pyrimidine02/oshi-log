/// EN: Token response DTO.
/// KO: 토큰 응답 DTO.
library;

/// EN: DTO for token response.
/// KO: 토큰 응답 DTO.
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.expiresIn,
    this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final int? expiresIn;
  final String? tokenType;

  /// EN: Parse token response from JSON.
  /// KO: JSON에서 토큰 응답 파싱.
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final expiresAtRaw = json['expiresAt'] ?? json['expires_at'];
    final expiresInRaw = json['expiresIn'] ?? json['expires_in'];

    DateTime? parsedExpiresAt;
    if (expiresAtRaw is String) {
      parsedExpiresAt = DateTime.tryParse(expiresAtRaw);
    }

    int? parsedExpiresIn;
    if (expiresInRaw is int) {
      parsedExpiresIn = expiresInRaw;
    } else if (expiresInRaw is String) {
      parsedExpiresIn = int.tryParse(expiresInRaw);
    }

    return TokenResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: parsedExpiresAt,
      expiresIn: parsedExpiresIn,
      tokenType: json['tokenType'] as String? ?? json['token_type'] as String?,
    );
  }

  /// EN: Compute access token expiry time.
  /// KO: 액세스 토큰 만료 시간을 계산.
  DateTime? resolvedExpiry(DateTime now) {
    if (expiresAt != null) return expiresAt;
    if (expiresIn != null) return now.add(Duration(seconds: expiresIn!));
    return null;
  }
}
