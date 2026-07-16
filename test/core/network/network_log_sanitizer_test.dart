import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/core/config/app_config.dart';
import 'package:girlsbandtabi_app/core/constants/api_constants.dart';
import 'package:girlsbandtabi_app/core/network/api_client.dart';
import 'package:girlsbandtabi_app/core/network/network_log_sanitizer.dart';
import 'package:girlsbandtabi_app/core/security/secure_storage.dart';

void main() {
  group('sanitizeNetworkLogData', () {
    test('redacts sensitive values recursively without mutating input', () {
      final nestedCredentials = <String, dynamic>{
        'refresh_token': 'nested-refresh-value',
        'displayName': 'Kasumi',
      };
      final credentialList = <dynamic>[
        <String, dynamic>{'ID-TOKEN': 'identity-value'},
        <String, dynamic>{'Authorization': 'Bearer credential-value'},
        <String, dynamic>{'cookie': 'session-cookie-value'},
      ];
      final original = <String, dynamic>{
        'accessToken': 'access-value',
        'password': 'password-value',
        'profile': nestedCredentials,
        'authEntries': credentialList,
        'metadata': <String, dynamic>{
          'clientSecret': 'client-secret-value',
          'api_key': 'api-key-value',
          'accessLevel': 'ADMIN',
          'refreshInterval': 30,
        },
      };

      final sanitized =
          sanitizeNetworkLogData(original) as Map<dynamic, dynamic>;

      expect(sanitized['accessToken'], redactedNetworkLogValue);
      expect(sanitized['password'], redactedNetworkLogValue);
      expect(
        (sanitized['profile'] as Map<dynamic, dynamic>)['refresh_token'],
        redactedNetworkLogValue,
      );
      expect(
        ((sanitized['authEntries'] as List<dynamic>)[0]
            as Map<dynamic, dynamic>)['ID-TOKEN'],
        redactedNetworkLogValue,
      );
      expect(
        ((sanitized['authEntries'] as List<dynamic>)[1]
            as Map<dynamic, dynamic>)['Authorization'],
        redactedNetworkLogValue,
      );
      expect(
        ((sanitized['authEntries'] as List<dynamic>)[2]
            as Map<dynamic, dynamic>)['cookie'],
        redactedNetworkLogValue,
      );
      expect(
        (sanitized['metadata'] as Map<dynamic, dynamic>)['clientSecret'],
        redactedNetworkLogValue,
      );
      expect(
        (sanitized['metadata'] as Map<dynamic, dynamic>)['api_key'],
        redactedNetworkLogValue,
      );
      expect(
        (sanitized['metadata'] as Map<dynamic, dynamic>)['accessLevel'],
        'ADMIN',
      );
      expect(
        (sanitized['metadata'] as Map<dynamic, dynamic>)['refreshInterval'],
        30,
      );

      expect(original['accessToken'], 'access-value');
      expect(nestedCredentials['refresh_token'], 'nested-refresh-value');
      expect(
        (credentialList[0] as Map<String, dynamic>)['ID-TOKEN'],
        'identity-value',
      );
      expect(identical(sanitized, original), isFalse);
      expect(identical(sanitized['profile'], nestedCredentials), isFalse);
      expect(identical(sanitized['authEntries'], credentialList), isFalse);
    });

    test('preserves scalar values and non-string map keys', () {
      final original = <dynamic, dynamic>{
        7: <String, dynamic>{'token': 'token-value'},
        'enabled': true,
        'empty': null,
      };

      final sanitized =
          sanitizeNetworkLogData(original) as Map<dynamic, dynamic>;

      expect(
        (sanitized[7] as Map<dynamic, dynamic>)['token'],
        redactedNetworkLogValue,
      );
      expect(sanitized['enabled'], isTrue);
      expect(sanitized['empty'], isNull);
    });
  });

  test('sanitizeNetworkLogUri redacts sensitive query parameters', () {
    final uri = Uri.parse(
      'https://example.com/api/refresh?refreshToken=refresh-value&mode=full',
    );

    final sanitized = sanitizeNetworkLogUri(uri);

    expect(sanitized.queryParameters['refreshToken'], redactedNetworkLogValue);
    expect(sanitized.queryParameters['mode'], 'full');
    expect(sanitized.toString(), isNot(contains('refresh-value')));
    expect(uri.queryParameters['refreshToken'], 'refresh-value');
  });

  test('redacts JSON and plain-text credential strings', () {
    final jsonBody = jsonEncode(<String, dynamic>{
      'data': <String, dynamic>{
        'accessToken': 'json-string-sensitive-value',
        'status': 'ok',
      },
    });
    const plainBody =
        '<html>authorization: Bearer plain-sensitive-value</html>';

    final sanitizedJson = sanitizeNetworkLogData(jsonBody);
    final sanitizedPlain = sanitizeNetworkLogData(plainBody);

    expect(sanitizedJson.toString(), contains('accessToken: ***'));
    expect(sanitizedJson.toString(), contains('status: ok'));
    expect(
      sanitizedJson.toString(),
      isNot(contains('json-string-sensitive-value')),
    );
    expect(sanitizedPlain.toString(), isNot(contains('plain-sensitive-value')));
    expect(sanitizedPlain.toString(), contains('***'));
  });

  test(
    'ApiClient redacts nested response and query values in debug logs',
    () async {
      AppConfig.instance.init(baseUrl: 'https://example.com');
      final dio = Dio()..httpClientAdapter = _NestedCredentialAdapter();
      ApiClient(secureStorage: SecureStorage(), dio: dio);
      final logs = <String>[];

      await runZoned(
        () => dio.get<dynamic>(
          ApiEndpoints.health,
          queryParameters: <String, dynamic>{
            'accessToken': 'query-sensitive-value',
            'mode': 'test',
          },
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );

      final output = logs.join('\n');
      expect(output, contains('accessToken: $redactedNetworkLogValue'));
      expect(output, contains('refreshToken: $redactedNetworkLogValue'));
      expect(output, isNot(contains('query-sensitive-value')));
      expect(output, isNot(contains('response-sensitive-value')));
    },
  );
}

class _NestedCredentialAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'refreshToken': 'response-sensitive-value',
          'status': 'ok',
        },
      }),
      200,
      headers: <String, List<String>>{
        // EN: Exercise the plain-text response path used by proxy errors.
        // KO: 프록시 오류에서 사용되는 평문 응답 경로를 검증합니다.
        Headers.contentTypeHeader: <String>[Headers.textPlainContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
