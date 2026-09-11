import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/analytics/analytics_service.dart';
import 'package:oshi_log/core/cache/cache_manager.dart';
import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/notifications/local_notifications_service.dart';
import 'package:oshi_log/core/notifications/remote_push_service.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/auth/application/auth_controller.dart';
import 'package:oshi_log/features/auth/application/native_social_login_service.dart';
import 'package:oshi_log/features/auth/application/oauth_service.dart';
import 'package:oshi_log/features/auth/domain/entities/auth_tokens.dart';
import 'package:oshi_log/features/auth/domain/repositories/auth_repository.dart';

const _fixtureCredential = 'local-fixture-value';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'logout clears active personal data while preserving other origin and app settings',
    () async {
      final repository = _FakeAuthRepository();
      final harness = await _AuthHarness.create(repository);
      addTearDown(harness.dispose);
      await _seedUserSession(harness);
      harness.authStateNotifier.setAuthenticated();
      repository.logoutHandler = () async => const Result.success(null);

      await harness.controller.logout();

      expect(await harness.activeSecureStorage.getAccessToken(), isNull);
      expect(await harness.activeSecureStorage.getRefreshToken(), isNull);
      expect(
        await harness.otherSecureStorage.getAccessToken(),
        'other-access-token',
      );
      expect(
        await harness.otherSecureStorage.getRefreshToken(),
        'other-refresh-token',
      );

      expect(harness.activeLocalStorage.getPendingFavoriteMutations(), isEmpty);
      expect(
        harness.activeLocalStorage.getPendingPostReactionMutations(),
        isEmpty,
      );
      expect(
        harness.activeLocalStorage.getPendingLiveAttendanceMutations(),
        isEmpty,
      );
      expect(harness.activeLocalStorage.getLocalPostBookmarks(), isEmpty);

      expect(harness.otherLocalStorage.getPendingFavoriteMutations(), [
        <String, dynamic>{'marker': 'other-favorite'},
      ]);
      expect(harness.otherLocalStorage.getPendingPostReactionMutations(), [
        <String, dynamic>{'marker': 'other-reaction'},
      ]);
      expect(harness.otherLocalStorage.getPendingLiveAttendanceMutations(), [
        <String, dynamic>{'marker': 'other-attendance'},
      ]);
      expect(harness.otherLocalStorage.getLocalPostBookmarks(), [
        <String, dynamic>{'marker': 'other-bookmark'},
      ]);
      expect(harness.activeLocalStorage.getThemeMode(), 'dark');
      expect(harness.activeLocalStorage.getLocale(), 'ko');
      expect(
        harness.container.read(authStateProvider),
        AuthState.unauthenticated,
      );
    },
  );

  test(
    'login waits for an in-progress logout and keeps the new session tokens',
    () async {
      final repository = _FakeAuthRepository();
      final harness = await _AuthHarness.create(repository);
      addTearDown(harness.dispose);
      await _seedUserSession(harness);
      harness.authStateNotifier.setAuthenticated();

      final logoutStarted = Completer<void>();
      final releaseLogout = Completer<Result<void>>();
      var loginCalls = 0;
      repository.logoutHandler = () async {
        logoutStarted.complete();
        return releaseLogout.future;
      };
      repository.loginHandler = (username, password) async {
        loginCalls += 1;
        await harness.activeSecureStorage.saveTokens(
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
        );
        return const Result.success(
          AuthTokens(
            accessToken: 'new-access-token',
            refreshToken: 'new-refresh-token',
          ),
        );
      };

      final logoutFuture = harness.controller.logout();
      await logoutStarted.future;
      final loginFuture = harness.controller.login(
        username: 'new-user',
        password: _fixtureCredential,
      );
      await Future<void>.delayed(Duration.zero);
      expect(loginCalls, 0);

      releaseLogout.complete(const Result.success(null));
      await logoutFuture;
      final loginResult = await loginFuture;

      expect(loginResult, isA<Success<void>>());
      expect(loginCalls, 1);
      expect(
        await harness.activeSecureStorage.getAccessToken(),
        'new-access-token',
      );
      expect(
        await harness.activeSecureStorage.getRefreshToken(),
        'new-refresh-token',
      );
      expect(
        harness.container.read(authStateProvider),
        AuthState.authenticated,
      );
    },
  );

  test('an in-flight login is superseded when logout starts', () async {
    final repository = _FakeAuthRepository();
    final harness = await _AuthHarness.create(repository);
    addTearDown(harness.dispose);
    await _seedUserSession(harness);
    harness.authStateNotifier.setAuthenticated();

    final loginStarted = Completer<void>();
    final releaseLogin = Completer<Result<AuthTokens>>();
    repository.loginHandler = (username, password) {
      loginStarted.complete();
      return releaseLogin.future;
    };
    repository.logoutHandler = () async => const Result.success(null);

    final loginFuture = harness.controller.login(
      username: 'old-login',
      password: _fixtureCredential,
    );
    await loginStarted.future;

    final logoutFuture = harness.controller.logout();
    expect(
      harness.container.read(authStateProvider),
      AuthState.unauthenticated,
    );

    // EN: The repository persists tokens when its delayed response arrives.
    // KO: 지연된 응답이 도착하면 리포지토리가 토큰을 저장한다고 가정합니다.
    await harness.activeSecureStorage.saveTokens(
      accessToken: 'stale-access-token',
      refreshToken: 'stale-refresh-token',
    );
    releaseLogin.complete(
      const Result.success(
        AuthTokens(
          accessToken: 'stale-access-token',
          refreshToken: 'stale-refresh-token',
        ),
      ),
    );

    final loginResult = await loginFuture;
    await logoutFuture;

    expect(loginResult, isA<Err<void>>());
    expect(
      harness.container.read(authStateProvider),
      AuthState.unauthenticated,
    );
    expect(await harness.activeSecureStorage.getAccessToken(), isNull);
    expect(await harness.activeSecureStorage.getRefreshToken(), isNull);
  });

  test(
    'OAuth launch cannot recreate callback credentials after logout starts',
    () async {
      final repository = _FakeAuthRepository();
      final verifierStarted = Completer<void>();
      final releaseVerifier = Completer<void>();
      late _DelayedOAuthSecureStorage oauthStorage;
      final harness = await _AuthHarness.create(
        repository,
        oauthServiceFactory: (namespace) {
          oauthStorage = _DelayedOAuthSecureStorage(
            namespace: namespace,
            verifierStarted: verifierStarted,
            releaseVerifier: releaseVerifier,
          );
          return AuthOAuthService(
            secureStorage: oauthStorage,
            launcher: _SuccessfulUrlLauncher(),
            twitterRedirectUri: 'https://api.noraneko.cc/oauth/x/callback',
          );
        },
      );
      addTearDown(() {
        if (!releaseVerifier.isCompleted) {
          releaseVerifier.complete();
        }
        harness.dispose();
      });
      harness.authStateNotifier.setAuthenticated();
      var logoutStarted = false;
      repository.logoutHandler = () async {
        logoutStarted = true;
        return const Result.success(null);
      };

      final launchFuture = harness.controller.startTwitterLogin();
      await verifierStarted.future;

      // EN: Logout must wait for the launch operation before clearing storage.
      // KO: 로그아웃은 저장소를 비우기 전에 인가 시작 작업이 끝나기를 기다려야 합니다.
      final logoutFuture = harness.controller.logout();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(logoutStarted, isFalse);
      releaseVerifier.complete();

      await launchFuture;
      await logoutFuture;

      expect(await oauthStorage.getOAuthPendingState(), isNull);
      expect(await oauthStorage.getAndClearTwitterCodeVerifier(), isNull);
    },
  );

  test(
    'token replacement freezes authenticated session before repository writes',
    () async {
      final repository = _FakeAuthRepository();
      final harness = await _AuthHarness.create(repository);
      addTearDown(harness.dispose);
      harness.authStateNotifier.setAuthenticated();
      var repositorySawUnauthenticated = false;
      repository.connectExistingHandler = (email, password) async {
        repositorySawUnauthenticated =
            harness.container.read(authStateProvider) ==
            AuthState.unauthenticated;
        await harness.activeSecureStorage.saveTokens(
          accessToken: 'replacement-access-token',
          refreshToken: 'replacement-refresh-token',
        );
        return const Result.success(
          AuthTokens(
            accessToken: 'replacement-access-token',
            refreshToken: 'replacement-refresh-token',
          ),
        );
      };

      final result = await harness.controller.connectExisting(
        email: 'fixture@example.invalid',
        password: _fixtureCredential,
      );

      expect(result, isA<Success<void>>());
      expect(repositorySawUnauthenticated, isTrue);
      expect(
        harness.container.read(authStateProvider),
        AuthState.authenticated,
      );
    },
  );

  test(
    'logout still clears the local session when the remote logout throws',
    () async {
      final repository = _FakeAuthRepository();
      final harness = await _AuthHarness.create(repository);
      addTearDown(harness.dispose);
      await _seedUserSession(harness);
      harness.authStateNotifier.setAuthenticated();
      repository.logoutHandler = () =>
          Future<Result<void>>.error(StateError('logout transport failed'));

      try {
        await harness.controller.logout();
      } catch (error) {
        // EN: A transport exception may be reported after local cleanup.
        // KO: 로컬 정리 후 전송 예외가 다시 보고될 수 있습니다.
        expect(error, isA<StateError>());
      }

      expect(await harness.activeSecureStorage.getAccessToken(), isNull);
      expect(await harness.activeSecureStorage.getRefreshToken(), isNull);
      expect(harness.activeLocalStorage.getPendingFavoriteMutations(), isEmpty);
      expect(
        harness.activeLocalStorage.getPendingPostReactionMutations(),
        isEmpty,
      );
      expect(
        harness.activeLocalStorage.getPendingLiveAttendanceMutations(),
        isEmpty,
      );
      expect(harness.activeLocalStorage.getLocalPostBookmarks(), isEmpty);
      expect(
        harness.container.read(authStateProvider),
        AuthState.unauthenticated,
      );
    },
  );

  test(
    'logout reports incomplete local cleanup while remaining unauthenticated',
    () async {
      final repository = _FakeAuthRepository();
      final harness = await _AuthHarness.create(
        repository,
        localStorageFailure: _LocalStorageRemovalFailure.returnsFalse,
      );
      addTearDown(harness.dispose);
      harness.authStateNotifier.setAuthenticated();
      repository.logoutHandler = () async => const Result.success(null);

      await harness.controller.logout();

      expect(
        harness.container.read(authControllerProvider),
        isA<AsyncError<void>>().having(
          (state) => state.error,
          'error',
          isA<AuthFailure>().having(
            (failure) => failure.code,
            'code',
            'logout_cleanup_failed',
          ),
        ),
      );
      expect(
        harness.container.read(authStateProvider),
        AuthState.unauthenticated,
      );
    },
  );

  test(
    'login stays unauthenticated when personal data cleanup fails',
    () async {
      for (final failure in _LocalStorageRemovalFailure.values) {
        final repository = _FakeAuthRepository();
        final harness = await _AuthHarness.create(
          repository,
          localStorageFailure: failure,
        );
        try {
          await _seedUserSession(harness);
          harness.authStateNotifier.setUnauthenticated();
          repository.loginHandler = (username, password) async {
            await harness.activeSecureStorage.saveTokens(
              accessToken: 'new-access-token',
              refreshToken: 'new-refresh-token',
            );
            return const Result.success(
              AuthTokens(
                accessToken: 'new-access-token',
                refreshToken: 'new-refresh-token',
              ),
            );
          };

          final result = await harness.controller.login(
            username: 'new-user',
            password: _fixtureCredential,
          );

          expect(result, isA<Err<void>>(), reason: failure.name);
          expect(
            (result as Err<void>).failure,
            isA<AuthFailure>().having(
              (error) => error.code,
              'code',
              'user_data_cleanup_failed',
            ),
          );
          expect(
            harness.container.read(authStateProvider),
            AuthState.unauthenticated,
            reason: failure.name,
          );
          expect(await harness.activeSecureStorage.getAccessToken(), isNull);
          expect(await harness.activeSecureStorage.getRefreshToken(), isNull);
          expect(harness.activeLocalStorage.getThemeMode(), 'dark');
          expect(harness.activeLocalStorage.getLocale(), 'ko');
        } finally {
          harness.dispose();
        }
      }
    },
  );
}

Future<void> _seedUserSession(_AuthHarness harness) async {
  await harness.activeSecureStorage.saveTokens(
    accessToken: 'active-access-token',
    refreshToken: 'active-refresh-token',
  );
  await harness.otherSecureStorage.saveTokens(
    accessToken: 'other-access-token',
    refreshToken: 'other-refresh-token',
  );

  await harness.activeLocalStorage.setPendingFavoriteMutations([
    <String, dynamic>{'marker': 'active-favorite'},
  ]);
  await harness.activeLocalStorage.setPendingPostReactionMutations([
    <String, dynamic>{'marker': 'active-reaction'},
  ]);
  await harness.activeLocalStorage.setPendingLiveAttendanceMutations([
    <String, dynamic>{'marker': 'active-attendance'},
  ]);
  await harness.activeLocalStorage.setLocalPostBookmarks([
    <String, dynamic>{'marker': 'active-bookmark'},
  ]);

  await harness.otherLocalStorage.setPendingFavoriteMutations([
    <String, dynamic>{'marker': 'other-favorite'},
  ]);
  await harness.otherLocalStorage.setPendingPostReactionMutations([
    <String, dynamic>{'marker': 'other-reaction'},
  ]);
  await harness.otherLocalStorage.setPendingLiveAttendanceMutations([
    <String, dynamic>{'marker': 'other-attendance'},
  ]);
  await harness.otherLocalStorage.setLocalPostBookmarks([
    <String, dynamic>{'marker': 'other-bookmark'},
  ]);

  await harness.activeLocalStorage.setThemeMode('dark');
  await harness.activeLocalStorage.setLocale('ko');
  await harness.activeLocalStorage.setBool(
    LocalStorageKeys.notificationsEnabled,
    false,
  );
}

enum _LocalStorageRemovalFailure { returnsFalse, throws }

class _AuthHarness {
  _AuthHarness({
    required this.container,
    required this.activeLocalStorage,
    required this.otherLocalStorage,
    required this.activeSecureStorage,
    required this.otherSecureStorage,
  });

  final ProviderContainer container;
  final LocalStorage activeLocalStorage;
  final LocalStorage otherLocalStorage;
  final SecureStorage activeSecureStorage;
  final SecureStorage otherSecureStorage;

  AuthController get controller =>
      container.read(authControllerProvider.notifier);

  AuthStateNotifier get authStateNotifier =>
      container.read(authStateProvider.notifier);

  void dispose() => container.dispose();

  static Future<_AuthHarness> create(
    _FakeAuthRepository repository, {
    _LocalStorageRemovalFailure? localStorageFailure,
    AuthOAuthService Function(String namespace)? oauthServiceFactory,
  }) async {
    final config = AppConfig.instance;
    config.init(
      environment: Environment.development,
      baseUrl: 'https://dev.oshilog.org',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final preferences = await SharedPreferences.getInstance();

    final activeNamespace = config.storageNamespace;
    final otherNamespace = AppConfig.storageNamespaceForOrigin(
      'https://api.oshilog.org',
    );
    final activeLocalStorage = localStorageFailure == null
        ? LocalStorage(preferences, namespace: activeNamespace)
        : _FailingLocalStorage(
            preferences,
            namespace: activeNamespace,
            failure: localStorageFailure,
          );
    final otherLocalStorage = LocalStorage(
      preferences,
      namespace: otherNamespace,
    );
    final activeSecureStorage = SecureStorage(namespace: activeNamespace);
    final otherSecureStorage = SecureStorage(namespace: otherNamespace);

    final remotePushService = _MockRemotePushService();
    when(
      () => remotePushService.deactivateCurrentDevice(),
    ).thenAnswer((_) async {});
    when(
      () => remotePushService.setAuthenticated(any()),
    ).thenAnswer((_) async {});
    when(() => remotePushService.initialize()).thenAnswer((_) async {});
    when(
      () => remotePushService.requestPermission(),
    ).thenAnswer((_) async => false);
    when(() => remotePushService.syncRegistration()).thenAnswer((_) async {});

    final localNotificationsService = _MockLocalNotificationsService();
    when(
      () => localNotificationsService.requestPermissions(),
    ).thenAnswer((_) async => false);

    final analyticsService = _MockAnalyticsService();
    when(() => analyticsService.logLogin(any())).thenAnswer((_) async {});
    when(() => analyticsService.logSignup(any())).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(activeSecureStorage),
        localStorageProvider.overrideWith((ref) async => activeLocalStorage),
        cacheManagerProvider.overrideWith(
          (ref) async =>
              CacheManager(activeLocalStorage, isOnline: () async => true),
        ),
        authRepositoryProvider.overrideWithValue(repository),
        authOAuthServiceProvider.overrideWithValue(
          oauthServiceFactory?.call(activeNamespace) ?? _MockAuthOAuthService(),
        ),
        nativeSocialLoginServiceProvider.overrideWithValue(
          _MockNativeSocialLoginService(),
        ),
        remotePushServiceProvider.overrideWithValue(remotePushService),
        localNotificationsServiceProvider.overrideWithValue(
          localNotificationsService,
        ),
        analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
    );

    return _AuthHarness(
      container: container,
      activeLocalStorage: activeLocalStorage,
      otherLocalStorage: otherLocalStorage,
      activeSecureStorage: activeSecureStorage,
      otherSecureStorage: otherSecureStorage,
    );
  }
}

class _FakeAuthRepository extends Mock implements AuthRepository {
  late Future<Result<AuthTokens>> Function(String username, String password)
  loginHandler;
  late Future<Result<void>> Function() logoutHandler;
  Future<Result<AuthTokens>> Function(String email, String password)?
  connectExistingHandler;

  @override
  Future<Result<AuthTokens>> login({
    required String username,
    required String password,
  }) {
    return loginHandler(username, password);
  }

  @override
  Future<Result<void>> logout() => logoutHandler();

  @override
  Future<Result<AuthTokens>> connectExisting({
    required String email,
    required String password,
  }) {
    final handler = connectExistingHandler;
    if (handler == null) {
      return Future<Result<AuthTokens>>.error(
        StateError('connectExisting handler not configured'),
      );
    }
    return handler(email, password);
  }
}

class _FailingLocalStorage extends LocalStorage {
  _FailingLocalStorage(
    super.preferences, {
    required super.namespace,
    required this.failure,
  });

  final _LocalStorageRemovalFailure failure;

  @override
  Future<bool> remove(String key) {
    const mutationKeys = {
      LocalStorageKeys.pendingFavoriteMutations,
      LocalStorageKeys.pendingPostReactionMutations,
      LocalStorageKeys.pendingLiveAttendanceMutations,
      LocalStorageKeys.localPostBookmarks,
    };
    if (!mutationKeys.contains(key)) {
      return super.remove(key);
    }
    if (failure == _LocalStorageRemovalFailure.throws) {
      return Future<bool>.error(StateError('mutation removal failed'));
    }
    return Future<bool>.value(false);
  }
}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockAuthOAuthService extends Mock implements AuthOAuthService {}

class _DelayedOAuthSecureStorage extends SecureStorage {
  _DelayedOAuthSecureStorage({
    required super.namespace,
    required this.verifierStarted,
    required this.releaseVerifier,
  });

  final Completer<void> verifierStarted;
  final Completer<void> releaseVerifier;

  @override
  Future<void> saveTwitterCodeVerifier(String verifier) async {
    if (!verifierStarted.isCompleted) {
      verifierStarted.complete();
    }
    await releaseVerifier.future;
    await super.saveTwitterCodeVerifier(verifier);
  }
}

class _SuccessfulUrlLauncher implements UrlLauncher {
  @override
  Future<bool> canLaunch(Uri uri) async => true;

  @override
  Future<bool> launch(Uri uri) async => true;
}

class _MockLocalNotificationsService extends Mock
    implements LocalNotificationsService {}

class _MockNativeSocialLoginService extends Mock
    implements NativeSocialLoginService {}

class _MockRemotePushService extends Mock implements RemotePushService {}
