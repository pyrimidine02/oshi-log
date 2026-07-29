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
