/// EN: Navigation arguments for the email verification pending page.
/// KO: 이메일 인증 대기 페이지의 네비게이션 인자.
library;

/// EN: Immutable arguments passed when navigating to [EmailVerificationPendingPage].
/// KO: [EmailVerificationPendingPage]로 이동할 때 전달되는 불변 인자.
class EmailVerificationArgs {
  const EmailVerificationArgs({
    required this.email,
    this.verificationExpiresAt,
  });

  /// EN: Email address the verification link was sent to.
  /// KO: 인증 링크가 발송된 이메일 주소.
  final String email;

  /// EN: Expiry time of the verification token.
  ///     Null if not provided by the backend.
  /// KO: 인증 토큰의 만료 시간.
  ///     백엔드가 제공하지 않은 경우 null.
  final DateTime? verificationExpiresAt;
}
