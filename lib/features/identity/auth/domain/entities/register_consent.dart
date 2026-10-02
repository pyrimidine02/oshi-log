/// EN: Register consent domain model.
/// KO: 회원가입 동의 도메인 모델.
library;

/// EN: Consent record submitted during register flow.
/// KO: 회원가입 과정에서 제출되는 동의 레코드입니다.
class RegisterConsent {
  const RegisterConsent({
    required this.type,
    required this.version,
    required this.agreed,
    required this.agreedAt,
  });

  final String type;
  final String version;
  final bool agreed;
  final DateTime agreedAt;
}
