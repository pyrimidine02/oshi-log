/// EN: Domain entity representing the outcome of a successful registration.
/// KO: 성공적인 회원가입 결과를 나타내는 도메인 엔티티.
library;

/// EN: Outcome of a successful [AuthRepository.register] call.
///     When [verificationRequired] is true, no session tokens are issued —
///     the user must verify their email before logging in.
///     When false, tokens are already persisted and the user is logged in.
/// KO: 성공적인 [AuthRepository.register] 호출의 결과입니다.
///     [verificationRequired]가 true이면 세션 토큰이 발급되지 않습니다.
///     사용자는 로그인 전에 이메일을 인증해야 합니다.
///     false이면 토큰이 이미 저장되어 있고 사용자가 로그인된 상태입니다.
class RegisterResult {
  const RegisterResult({
    required this.verificationRequired,
    this.pendingEmail,
    this.verificationExpiresAt,
  });

  /// EN: Whether email verification is required before login.
  /// KO: 로그인 전 이메일 인증이 필요한지 여부.
  final bool verificationRequired;

  /// EN: Email address awaiting verification.
  ///     Non-null when [verificationRequired] is true.
  /// KO: 인증 대기 중인 이메일 주소.
  ///     [verificationRequired]가 true일 때 non-null.
  final String? pendingEmail;

  /// EN: Expiry time of the email verification token.
  ///     Non-null when [verificationRequired] is true and the backend provides it.
  /// KO: 이메일 인증 토큰의 만료 시간.
  ///     [verificationRequired]가 true이고 백엔드가 제공할 때 non-null.
  final DateTime? verificationExpiresAt;
}
