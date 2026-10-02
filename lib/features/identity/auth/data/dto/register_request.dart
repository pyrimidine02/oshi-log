/// EN: Register request DTO.
/// KO: 회원가입 요청 DTO.
library;

import 'package:oshi_log/features/identity/auth/domain/entities/register_consent.dart';

/// EN: DTO for registration request payload.
/// KO: 회원가입 요청 페이로드 DTO.
class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.password,
    required this.nickname,
    this.consents = const [],
  });

  final String username;
  final String password;
  final String nickname;
  final List<RegisterConsent> consents;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'nickname': nickname,
      if (consents.isNotEmpty)
        'consents': consents
            .map(
              (consent) => {
                'type': consent.type,
                'version': consent.version,
                'agreed': consent.agreed,
                'agreedAt': consent.agreedAt.toIso8601String(),
              },
            )
            .toList(growable: false),
    };
  }
}
