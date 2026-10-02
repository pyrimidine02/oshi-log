/// EN: DTO for the change-password response body.
/// KO: 비밀번호 변경 응답 DTO.
library;

class ChangePasswordResponse {
  const ChangePasswordResponse({
    required this.changed,
    required this.revokedRefreshTokenCount,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      changed: json['changed'] as bool? ?? false,
      revokedRefreshTokenCount: json['revokedRefreshTokenCount'] as int? ?? 0,
    );
  }

  final bool changed;
  final int revokedRefreshTokenCount;
}
