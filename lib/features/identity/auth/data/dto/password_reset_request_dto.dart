/// EN: DTO for requesting a password-reset email (Step 1).
/// KO: 비밀번호 재설정 이메일 요청 DTO (1단계).
library;

class PasswordResetRequestDto {
  const PasswordResetRequestDto({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

/// EN: Response DTO for the password-reset email request.
/// KO: 비밀번호 재설정 이메일 요청 응답 DTO.
class PasswordResetRequestResponse {
  const PasswordResetRequestResponse({
    required this.email,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  factory PasswordResetRequestResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequestResponse(
      email: json['email'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      resendAvailableAt: json['resendAvailableAt'] as String? ?? '',
    );
  }

  final String email;
  final String expiresAt;
  final String resendAvailableAt;
}
