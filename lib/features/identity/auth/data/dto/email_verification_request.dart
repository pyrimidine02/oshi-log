/// EN: Email verification request DTO.
/// KO: 이메일 인증 요청 DTO.
library;

class EmailVerificationRequest {
  const EmailVerificationRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
