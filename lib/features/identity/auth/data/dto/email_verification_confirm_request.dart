/// EN: Email verification confirm request DTO.
/// KO: 이메일 인증 확인 요청 DTO.
library;

class EmailVerificationConfirmRequest {
  const EmailVerificationConfirmRequest({required this.token});

  final String token;

  Map<String, dynamic> toJson() {
    return {'token': token};
  }
}
