import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/features/auth/application/oauth_service.dart';

void main() {
  test('accepts configured callback shapes and preserves legacy support', () {
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('https://api.noraneko.cc/oauth/x/callback?code=abc'),
      ),
      isTrue,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('girlsbandtabi://oauth/x/callback?code=abc&state=s1'),
      ),
      isTrue,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('https://api.noraneko.cc/oauth/other?code=abc'),
      ),
      isFalse,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('girlsbandtabi://oauth/callback?code=abc'),
      ),
      isFalse,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('girlsbandti://oauth/x/callback?code=abc'),
      ),
      isFalse,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('girlsbandtabi://user@oauth/x/callback?code=abc'),
      ),
      isFalse,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('girlsbandtabi://oauth:443/x/callback?code=abc'),
      ),
      isFalse,
    );
    expect(
      isTwitterOAuthCallbackUri(
        Uri.parse('girlsbandtabi://oauth/x/callback?code=abc#fragment'),
      ),
      isFalse,
    );
  });

  test(
    'uses one injected redirect URI in the X authorization request',
    () async {
      final launcher = _RecordingUrlLauncher();
      final secureStorage = _MockSecureStorage();
      when(
        () => secureStorage.saveTwitterCodeVerifier(any()),
      ).thenAnswer((_) async {});
      when(
        () => secureStorage.saveOAuthPendingState(
          state: any(named: 'state'),
          providerId: any(named: 'providerId'),
        ),
      ).thenAnswer((_) async {});

      final config = AppConfig.instance;
      config.init(
        environment: Environment.development,
        baseUrl: 'https://dev.oshilog.org',
      );
      final service = AuthOAuthService(
        config: config,
        launcher: launcher,
        secureStorage: secureStorage,
        twitterRedirectUri: 'https://login.example.test/oauth/x/callback',
      );

      final result = await service.launchTwitterPkce();

      expect(result.isSuccess, isTrue);
      expect(
        service.twitterRedirectUri,
        'https://login.example.test/oauth/x/callback',
      );
      expect(
        launcher.lastUri?.queryParameters['redirect_uri'],
        'https://login.example.test/oauth/x/callback',
      );
    },
  );

  test(
    'rejects an unsafe injected redirect before persisting PKCE state',
    () async {
      final launcher = _RecordingUrlLauncher();
      final secureStorage = _MockSecureStorage();
      when(
        () => secureStorage.saveTwitterCodeVerifier(any()),
      ).thenAnswer((_) async {});
      when(
        () => secureStorage.saveOAuthPendingState(
          state: any(named: 'state'),
          providerId: any(named: 'providerId'),
        ),
      ).thenAnswer((_) async {});

      final service = AuthOAuthService(
        launcher: launcher,
        secureStorage: secureStorage,
        twitterRedirectUri: 'https://user:pass@example.test/oauth/x/callback',
      );

      final result = await service.launchTwitterPkce();

      expect(result.failureOrNull?.code, 'twitter_redirect_uri_invalid');
      verifyNever(() => secureStorage.saveTwitterCodeVerifier(any()));
      verifyNever(
        () => secureStorage.saveOAuthPendingState(
          state: any(named: 'state'),
          providerId: any(named: 'providerId'),
        ),
      );
    },
  );
}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _RecordingUrlLauncher implements UrlLauncher {
  Uri? lastUri;

  @override
  Future<bool> canLaunch(Uri uri) async {
    lastUri = uri;
    return true;
  }

  @override
  Future<bool> launch(Uri uri) async {
    lastUri = uri;
    return true;
  }
}
