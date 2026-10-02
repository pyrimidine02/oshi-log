/// EN: Request DTO for Apple native sign-in (POST /api/v1/auth/oauth2/apple).
/// KO: Apple 네이티브 로그인 요청 DTO (POST /api/v1/auth/oauth2/apple).
library;

/// EN: Carries the Apple identity token and optional cached user info.
///     Apple only provides email/fullName on the very first sign-in,
///     so these must be read from the local cache on subsequent calls.
/// KO: Apple identity 토큰과 선택적으로 캐시된 사용자 정보를 전달합니다.
///     Apple은 최초 로그인 시에만 email/fullName을 제공하므로
///     이후 호출에서는 로컬 캐시에서 읽어 전송해야 합니다.
class AppleOAuthRequest {
  const AppleOAuthRequest({
    required this.identityToken,
    this.email,
    this.fullName,
  });

  /// EN: Apple identity token from the native SDK.
  /// KO: 네이티브 SDK에서 받은 Apple identity 토큰.
  final String identityToken;

  /// EN: User email — provided by Apple on first sign-in only; send from cache thereafter.
  /// KO: 사용자 이메일 — Apple이 최초 로그인 시에만 제공; 이후 캐시에서 전송.
  final String? email;

  /// EN: User full name — provided by Apple on first sign-in only; send from cache thereafter.
  /// KO: 사용자 전체 이름 — Apple이 최초 로그인 시에만 제공; 이후 캐시에서 전송.
  final String? fullName;

  Map<String, dynamic> toJson() => {
    'identityToken': identityToken,
    if (email != null) 'email': email,
    if (fullName != null) 'fullName': fullName,
  };
}
