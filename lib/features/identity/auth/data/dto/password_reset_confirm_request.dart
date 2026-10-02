/// EN: DTO for confirming a password-reset with token + new password (Step 2).
/// KO: 토큰 + 새 비밀번호로 비밀번호 재설정을 확인하는 DTO (2단계).
library;

class PasswordResetConfirmRequest {
  const PasswordResetConfirmRequest({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {'token': token, 'newPassword': newPassword};
}

/// EN: Response DTO for a successful password-reset confirm.
/// KO: 비밀번호 재설정 확인 성공 응답 DTO.
class PasswordResetConfirmResponse {
  const PasswordResetConfirmResponse({
    required this.email,
    required this.revokedRefreshTokenCount,
  });

  factory PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetConfirmResponse(
      email: json['email'] as String? ?? '',
      revokedRefreshTokenCount: json['revokedRefreshTokenCount'] as int? ?? 0,
    );
  }

  final String email;
  final int revokedRefreshTokenCount;
}
