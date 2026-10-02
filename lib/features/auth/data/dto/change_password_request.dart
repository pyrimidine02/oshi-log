/// EN: DTO for changing password while authenticated.
/// KO: 로그인 상태에서 비밀번호를 변경하는 DTO.
library;

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'currentPassword': currentPassword, 'newPassword': newPassword};
  }
}
