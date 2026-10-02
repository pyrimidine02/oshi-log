/// EN: Login request DTO.
/// KO: 로그인 요청 DTO.
library;

/// EN: DTO for login request payload.
/// KO: 로그인 요청 페이로드 DTO.
class LoginRequest {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}
