import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/security/secure_storage.dart';

void main() {
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
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}
