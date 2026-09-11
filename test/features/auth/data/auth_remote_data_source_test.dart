import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshi_log/features/auth/data/dto/account_recovery_password_request.dart';
import 'package:oshi_log/features/auth/data/dto/apple_oauth_request.dart';
import 'package:oshi_log/features/auth/data/dto/google_oauth_request.dart';
import 'package:oshi_log/features/auth/data/dto/token_response.dart';
import 'package:oshi_log/features/auth/domain/entities/oauth_provider.dart';

void main() {
  late _MockApiClient apiClient;
  late AuthRemoteDataSource dataSource;

  setUp(() {
    apiClient = _MockApiClient();
    dataSource = AuthRemoteDataSource(apiClient);
    when(
      () => apiClient.post<TokenResponse>(
        any(),
        data: any(named: 'data'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => Result.success(_tokens));
  });

  test('recovers inactive password account with exact credentials', () async {
    await dataSource.recoverWithPassword(
      const AccountRecoveryPasswordRequest(
        email: 'fan@example.com',
        password: 'secret',
      ),
    );

    verify(
      () => apiClient.post<TokenResponse>(
        ApiEndpoints.accountRecoveryPassword,
        data: {'email': 'fan@example.com', 'password': 'secret'},
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('recovers inactive Google account with provider token', () async {
    await dataSource.recoverWithGoogle(
      const GoogleOAuthRequest(idToken: 'google-token'),
    );

    verify(
      () => apiClient.post<TokenResponse>(
        ApiEndpoints.accountRecoveryGoogle,
        data: {'idToken': 'google-token'},
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('recovers inactive Apple account with provider credentials', () async {
    await dataSource.recoverWithApple(
      const AppleOAuthRequest(
        identityToken: 'apple-token',
        email: 'fan@privaterelay.appleid.com',
        fullName: 'Fan',
      ),
    );

    verify(
      () => apiClient.post<TokenResponse>(
        ApiEndpoints.accountRecoveryApple,
        data: {
          'identityToken': 'apple-token',
          'email': 'fan@privaterelay.appleid.com',
          'fullName': 'Fan',
        },
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('does not call the removed generic OAuth callback route', () async {
    final result = await dataSource.exchangeOAuthCode(
      provider: OAuthProvider.google,
      code: 'authorization-code',
      state: 'state',
    );

    expect(result.failureOrNull?.code, 'oauth_callback_unsupported');
    verifyNoMoreInteractions(apiClient);
  });
}

const _tokens = TokenResponse(
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: 3600,
  tokenType: 'Bearer',
);

class _MockApiClient extends Mock implements ApiClient {}
