/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/token_response.dart';
import '../../domain/entities/auth_tokens.dart';

extension TokenResponseDomainMapper on TokenResponse {
  AuthTokens toDomain() {
    final response = this;

    return AuthTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      tokenType: response.tokenType,
    );
  }
}
