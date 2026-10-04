import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/platform/config/app_config.dart';
import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';

void main() {
  for (final changedSession in [true, false]) {
    test(
      changedSession
          ? 'late successful response never reaches repository decoding'
          : 'current-session successful response reaches repository decoding',
      () async {
        AppConfig.instance.init(baseUrl: 'https://example.com');
        final requestStarted = Completer<void>();
        final response = Completer<ResponseBody>();
        final adapter = _RecordingAdapter(
          onFetch: (_) {
            requestStarted.complete();
            return response.future;
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        var generation = 0;
        var decoded = 0;
        final client = ApiClient(
          secureStorage: _ControlledSecureStorage(),
          dio: dio,
          currentSessionGeneration: () => generation,
          isSessionGenerationCurrent: (captured) => captured == generation,
        );
        final resultFuture = client.get<String>(
          '/private-visits',
          fromJson: (data) {
            decoded++;
            return (data as Map<String, dynamic>)['visit'] as String;
          },
        );
        await requestStarted.future;
        if (changedSession) generation++;
        response.complete(
          ResponseBody.fromString(
            '{"data":{"visit":"owner-a-visit"}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
        final result = await resultFuture;
        if (changedSession) {
          expect(result.failureOrNull?.code, 'cancelled');
          expect(result.dataOrNull, isNull);
          expect(decoded, 0);
        } else {
          expect(result.dataOrNull, 'owner-a-visit');
          expect(decoded, 1);
        }
      },
    );
  }

  for (final boundary in ['expiry', 'access', 'refresh']) {
    test(
      'account change during $boundary read cancels before dispatch',
      () async {
        AppConfig.instance.init(baseUrl: 'https://example.com');
        final storage = _ControlledSecureStorage(
          blockedAt: boundary,
          expired: boundary != 'access',
        );
        final adapter = _RecordingAdapter();
        final dio = Dio()..httpClientAdapter = adapter;
        var generation = 0;
        ApiClient(
          secureStorage: storage,
          dio: dio,
          currentSessionGeneration: () => generation,
          isSessionGenerationCurrent: (captured) => captured == generation,
        );
        final result = expectLater(
          dio.post<dynamic>('/private-upload'),
          throwsA(
            isA<DioException>().having(
              (error) => error.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        await storage.blocked.future;
        generation++;
        storage.resume.complete();
        await result;
        expect(adapter.paths, isEmpty);
        expect(storage.tokensSaved, isFalse);
        expect(storage.tokensCleared, isFalse);
      },
    );
  }

  for (final refreshStatus in [200, 401]) {
    test(
      'late refresh $refreshStatus cannot alter or dispatch a new session',
      () async {
        AppConfig.instance.init(baseUrl: 'https://example.com');
        final storage = _ControlledSecureStorage(expired: true);
        final refreshStarted = Completer<void>();
        final refreshResponse = Completer<ResponseBody>();
        final adapter = _RecordingAdapter(
          onFetch: (options) {
            if (options.path == ApiEndpoints.refresh) {
              refreshStarted.complete();
              return refreshResponse.future;
            }
            return Future.value(ResponseBody.fromString('{}', 200));
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        var generation = 0;
        var refreshed = 0;
        var unauthorized = 0;
        ApiClient(
          secureStorage: storage,
          dio: dio,
          currentSessionGeneration: () => generation,
          isSessionGenerationCurrent: (captured) => captured == generation,
          onTokenRefreshed: () => refreshed++,
          onUnauthorized: () => unauthorized++,
        );
        final result = expectLater(
          dio.post<dynamic>('/private-upload'),
          throwsA(
            isA<DioException>().having(
              (error) => error.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        await refreshStarted.future;
        generation++;
        refreshResponse.complete(_refreshResponse(refreshStatus));
        await result;
        expect(adapter.paths, [ApiEndpoints.refresh]);
        expect(storage.tokensSaved, isFalse);
        expect(storage.tokensCleared, isFalse);
        expect(refreshed, 0);
        expect(unauthorized, 0);
      },
    );
  }

  test(
    'late protected 401 never refreshes or retries for a new session',
    () async {
      AppConfig.instance.init(baseUrl: 'https://example.com');
      final storage = _ControlledSecureStorage();
      final requestStarted = Completer<void>();
      final response = Completer<ResponseBody>();
      final adapter = _RecordingAdapter(
        onFetch: (options) {
          if (options.path == ApiEndpoints.refresh) {
            return Future.value(_refreshResponse(200));
          }
          if (!requestStarted.isCompleted) {
            requestStarted.complete();
            return response.future;
          }
          return Future.value(ResponseBody.fromString('{}', 200));
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      var generation = 0;
      ApiClient(
        secureStorage: storage,
        dio: dio,
        currentSessionGeneration: () => generation,
        isSessionGenerationCurrent: (captured) => captured == generation,
      );
      final result = expectLater(
        dio.post<dynamic>('/private-upload'),
        throwsA(isA<DioException>()),
      );
      await requestStarted.future;
      generation++;
      response.complete(ResponseBody.fromString('{}', 401));
      await result;
      expect(adapter.paths, ['/private-upload']);
      expect(storage.tokensSaved, isFalse);
    },
  );

  test(
    'current session still refreshes once and retries the original request',
    () async {
      AppConfig.instance.init(baseUrl: 'https://example.com');
      final storage = _ControlledSecureStorage();
      var protectedCalls = 0;
      final adapter = _RecordingAdapter(
        onFetch: (options) async {
          if (options.path == ApiEndpoints.refresh) {
            return _refreshResponse(200);
          }
          return ResponseBody.fromString(
            '{}',
            ++protectedCalls == 1 ? 401 : 200,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      ApiClient(
        secureStorage: storage,
        dio: dio,
        currentSessionGeneration: () => 1,
        isSessionGenerationCurrent: (captured) => captured == 1,
      );
      await dio.post<dynamic>('/private-upload');
      expect(adapter.paths, [
        '/private-upload',
        ApiEndpoints.refresh,
        '/private-upload',
      ]);
      expect(storage.tokensSaved, isTrue);
    },
  );

  test('account recovery requests bypass stale authentication state', () async {
    AppConfig.instance.init(baseUrl: 'https://example.com');
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    ApiClient(secureStorage: _FailIfReadSecureStorage(), dio: dio);

    await dio.post<dynamic>(ApiEndpoints.accountRecoveryPassword);

    expect(adapter.lastRequest?.headers[ApiHeaders.authorization], isNull);
  });

  test('a stale-generation refresh failure does not clear tokens or '
      'unauthenticate the current (re-logged-in) session', () async {
    AppConfig.instance.init(baseUrl: 'https://example.com');
    final secureStorage = _FakeExpiredTokenSecureStorage();
    final adapter = _InvalidRefreshAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    var unauthorizedCalls = 0;

    ApiClient(
      secureStorage: secureStorage,
      dio: dio,
      onUnauthorized: () => unauthorizedCalls += 1,
      // EN: Request/refresh started under generation 0, but by the time
      //     the refresh failure comes back the real session has moved to
      //     generation 1 (user logged back in). The guard must say "no,
      //     generation 0 is stale" so tokens/auth state are preserved.
      // KO: 요청/갱신은 generation 0에서 시작했지만, 갱신 실패가 돌아올
      //     때쯤 실제 세션은 generation 1로 이동했습니다(재로그인).
      //     가드는 "generation 0은 오래되었다"고 판단해 토큰/인증 상태를
      //     보존해야 합니다.
      currentSessionGeneration: () => 0,
      isSessionGenerationCurrent: (captured) => captured == 1,
    );

    // EN: The original 401 still propagates (no retry possible); what
    //     matters is that it does not trigger the unauthorized callback or
    //     clear tokens for the superseded generation.
    // KO: 원래 401은 여전히 전파됩니다(재시도 불가); 중요한 것은 교체된
    //     세대에 대해 unauthorized 콜백이나 토큰 삭제가 일어나지 않는다는
    //     점입니다.
    await expectLater(
      dio.get<dynamic>('/some/protected/path'),
      throwsA(isA<DioException>()),
    );

    expect(unauthorizedCalls, 0);
    expect(secureStorage.tokensCleared, isFalse);
  });
}

/// EN: SecureStorage stub whose token is always expired, has no refresh
///     token saved locally (so proactive refresh in onRequest is skipped),
///     and records whether tokens were ever cleared.
/// KO: 토큰이 항상 만료되었고, 로컬에 리프레시 토큰이 없어(onRequest의
///     선제 갱신을 건너뜀) 토큰 삭제 여부를 기록하는 SecureStorage 스텁.
class _FakeExpiredTokenSecureStorage extends SecureStorage {
  bool tokensCleared = false;

  @override
  Future<bool> isTokenExpired() async => false;

  @override
  Future<String?> getAccessToken() async => 'stale-access-token';

  @override
  Future<String?> getRefreshToken() async => 'stale-refresh-token';

  @override
  Future<void> clearTokens() async {
    tokensCleared = true;
  }
}

/// EN: Adapter that returns 401 for the original request and a definitive
///     invalid-refresh-token error for the refresh call.
/// KO: 원래 요청에는 401을, 갱신 요청에는 확정적인 invalid-refresh-token
///     오류를 반환하는 어댑터.
class _InvalidRefreshAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == ApiEndpoints.refresh) {
      return ResponseBody.fromString(
        '{"error":{"code":"INVALID_REFRESH_TOKEN"}}',
        401,
      );
    }
    return ResponseBody.fromString('{}', 401);
  }

  @override
  void close({bool force = false}) {}
}

class _FailIfReadSecureStorage extends SecureStorage {
  @override
  Future<bool> isTokenExpired() {
    throw StateError('Public endpoints must not inspect token expiry.');
  }

  @override
  Future<String?> getAccessToken() {
    throw StateError('Public endpoints must not read access tokens.');
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.onFetch});
  final Future<ResponseBody> Function(RequestOptions)? onFetch;
  RequestOptions? lastRequest;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    paths.add(options.path);
    if (onFetch != null) return onFetch!(options);
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _refreshResponse(int status) => ResponseBody.fromString(
  status == 200
      ? '{"data":{"accessToken":"refreshed-test-access","refreshToken":"refreshed-test-refresh","expiresIn":3600}}'
      : '{"error":{"code":"INVALID_REFRESH_TOKEN"}}',
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _ControlledSecureStorage extends SecureStorage {
  _ControlledSecureStorage({this.blockedAt, this.expired = false});
  final String? blockedAt;
  final bool expired;
  final blocked = Completer<void>();
  final resume = Completer<void>();
  bool tokensSaved = false;
  bool tokensCleared = false;

  Future<void> _pause(String boundary) async {
    if (blockedAt != boundary) return;
    if (!blocked.isCompleted) blocked.complete();
    await resume.future;
  }

  @override
  Future<bool> isTokenExpired() async {
    await _pause('expiry');
    return expired;
  }

  @override
  Future<String?> getAccessToken() async {
    await _pause('access');
    return 'test-access';
  }

  @override
  Future<String?> getRefreshToken() async {
    await _pause('refresh');
    return 'test-refresh';
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    tokensSaved = true;
  }

  @override
  Future<void> saveTokenExpiry(DateTime expiry) async {}

  @override
  Future<void> clearTokens() async => tokensCleared = true;
}
