/// EN: Password credentials used to restore an inactive account.
/// KO: 비활성 계정 복구에 사용하는 비밀번호 자격 증명입니다.
class AccountRecoveryPasswordRequest {
  const AccountRecoveryPasswordRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
