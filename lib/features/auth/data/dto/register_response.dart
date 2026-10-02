/// EN: DTO for the register endpoint response.
/// KO: 회원가입 엔드포인트 응답 DTO.
library;

/// EN: Register response DTO — handles both immediate-login
///     (verificationRequired: false) and email-verification flows.
/// KO: 회원가입 응답 DTO — 즉시 로그인(verificationRequired: false)과
///     이메일 인증 필요 플로우를 모두 처리합니다.
class RegisterResponse {
  const RegisterResponse({
    required this.verificationRequired,
    this.userId,
    this.email,
    this.verificationExpiresAt,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.expiresIn,
    this.tokenType,
  });

  /// EN: Whether email verification is required before login.
  /// KO: 로그인 전 이메일 인증이 필요한지 여부.
  final bool verificationRequired;

  /// EN: Registered user ID.
  /// KO: 등록된 사용자 ID.
  final String? userId;

  /// EN: Registered email address — present when verificationRequired is true.
  /// KO: 등록된 이메일 주소 — verificationRequired가 true일 때 존재.
  final String? email;

  /// EN: Verification token expiry time.
  /// KO: 인증 토큰 만료 시간.
  final DateTime? verificationExpiresAt;

  // EN: Token fields — present only when verificationRequired is false.
  // KO: 토큰 필드 — verificationRequired가 false일 때만 존재.
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final int? expiresIn;
  final String? tokenType;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final verificationRequired =
        json['verificationRequired'] as bool? ??
        json['verification_required'] as bool? ??
        false;

    final expiresAtRaw = json['expiresAt'] ?? json['expires_at'];
    final expiresInRaw = json['expiresIn'] ?? json['expires_in'];
    final verificationExpiresAtRaw =
        json['verificationExpiresAt'] ?? json['verification_expires_at'];

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

    DateTime? parsedVerificationExpiresAt;
    if (verificationExpiresAtRaw is String) {
      parsedVerificationExpiresAt = DateTime.tryParse(verificationExpiresAtRaw);
    }

    return RegisterResponse(
      verificationRequired: verificationRequired,
      userId: json['userId'] as String? ?? json['user_id'] as String?,
      email: json['email'] as String?,
      verificationExpiresAt: parsedVerificationExpiresAt,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: parsedExpiresAt,
      expiresIn: parsedExpiresIn,
      tokenType: json['tokenType'] as String? ?? json['token_type'] as String?,
    );
  }

  /// EN: Compute access token expiry time.
  /// KO: 액세스 토큰 만료 시간을 계산합니다.
  DateTime? resolvedExpiry(DateTime now) {
    if (expiresAt != null) return expiresAt;
    if (expiresIn != null) return now.add(Duration(seconds: expiresIn!));
    return null;
  }
}
