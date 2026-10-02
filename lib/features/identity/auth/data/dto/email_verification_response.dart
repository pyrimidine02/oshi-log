/// EN: DTO for email verification (resend) endpoint response.
/// KO: 이메일 인증(재발송) 엔드포인트 응답 DTO.
library;

/// EN: Email verification API response.
///     Contains the earliest time the user may request another email.
/// KO: 이메일 인증 API 응답.
///     사용자가 다음 인증 메일을 요청할 수 있는 최초 시간을 포함합니다.
class EmailVerificationResponse {
  const EmailVerificationResponse({this.resendAvailableAt});

  /// EN: Earliest UTC time at which a resend request will be accepted.
  ///     Null means the server did not specify a cooldown (resend immediately allowed).
  /// KO: 재발송 요청이 허용될 수 있는 가장 이른 UTC 시간.
  ///     null이면 서버가 쿨다운을 지정하지 않은 것 (즉시 재발송 허용).
  final DateTime? resendAvailableAt;

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['resendAvailableAt'] ?? json['resend_available_at'];
    DateTime? parsed;
    if (raw is String) {
      parsed = DateTime.tryParse(raw)?.toLocal();
    }
    return EmailVerificationResponse(resendAvailableAt: parsed);
  }
}
