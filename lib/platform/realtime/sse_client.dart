/// EN: Lightweight Server-Sent Events (SSE) client with auth header support.
/// KO: 인증 헤더를 지원하는 경량 Server-Sent Events(SSE) 클라이언트입니다.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage.dart';

/// EN: Parsed SSE event payload.
/// KO: 파싱된 SSE 이벤트 페이로드입니다.
class SseEvent {
  const SseEvent({
    required this.data,
    this.event,
    this.id,
    this.retryMilliseconds,
  });

  final String data;
  final String? event;
  final String? id;
  final int? retryMilliseconds;

  /// EN: Best-effort JSON parse for `data` payload.
  /// KO: `data` 페이로드를 가능한 경우 JSON으로 파싱합니다.
  Map<String, dynamic>? get dataAsJson {
    if (data.isEmpty) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

/// EN: Active SSE connection handle.
/// KO: 활성 SSE 연결 핸들입니다.
class SseConnection {
  SseConnection._({required this.events, required http.Client httpClient})
    : _httpClient = httpClient;

  final Stream<SseEvent> events;
  final http.Client _httpClient;
  bool _closed = false;

  /// EN: Close the active SSE connection.
  /// KO: 활성 SSE 연결을 종료합니다.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }
}

/// EN: SSE client that opens authenticated event streams.
/// KO: 인증된 이벤트 스트림을 여는 SSE 클라이언트입니다.
class SseClient {
  SseClient({
    required SecureStorage secureStorage,
    String? baseUrl,
    http.Client Function()? clientFactory,
    Future<bool> Function()? ensureFreshToken,
  }) : _secureStorage = secureStorage,
       _baseUrl = baseUrl ?? AppConfig.instance.baseUrl,
       _clientFactory = clientFactory ?? http.Client.new,
       _ensureFreshToken = ensureFreshToken;

  final SecureStorage _secureStorage;
  final String _baseUrl;
  final http.Client Function() _clientFactory;
  final Future<bool> Function()? _ensureFreshToken;

  /// EN: Connect to SSE endpoint with bearer token when available.
  /// KO: 가능하면 bearer 토큰을 포함해 SSE 엔드포인트에 연결합니다.
  Future<SseConnection> connect({
    required String path,
    Map<String, dynamic>? queryParameters,
    Duration openTimeout = const Duration(seconds: 12),
    String? lastEventId,
  }) async {
    final client = _clientFactory();
    try {
      final request = http.Request('GET', _buildUri(path, queryParameters));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';
      request.headers[ApiHeaders.clientType] = ApiHeaders.clientTypeMobile;
      if (lastEventId != null && lastEventId.isNotEmpty) {
        request.headers['Last-Event-ID'] = lastEventId;
      }

      final ensureFreshToken = _ensureFreshToken;
      if (ensureFreshToken != null) {
        await ensureFreshToken();
      }

      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers[ApiHeaders.authorization] =
            '${ApiHeaders.bearer} $accessToken';
      }

      final response = await client.send(request).timeout(openTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('SSE connection failed: HTTP ${response.statusCode}');
      }

      final events = _parse(response.stream);
      return SseConnection._(events: events, httpClient: client);
    } catch (_) {
      client.close();
      rethrow;
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final base = Uri.parse(_baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: normalizedPath,
      queryParameters: _stringQuery(queryParameters),
    );
  }

  Map<String, String>? _stringQuery(Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return null;
    final output = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) continue;
      final rendered = value.toString();
      if (rendered.isEmpty) continue;
      output[entry.key] = rendered;
    }
    return output.isEmpty ? null : output;
  }

  Stream<SseEvent> _parse(Stream<List<int>> byteStream) async* {
    final lines = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    var eventName = '';
    var eventId = '';
    var retryMilliseconds = '';
    final dataLines = <String>[];

    void resetEvent() {
      eventName = '';
      eventId = '';
      retryMilliseconds = '';
      dataLines.clear();
    }

    SseEvent? buildEvent() {
      if (eventName.isEmpty &&
          eventId.isEmpty &&
          retryMilliseconds.isEmpty &&
          dataLines.isEmpty) {
        return null;
      }
      return SseEvent(
        data: dataLines.join('\n'),
        event: eventName.isEmpty ? null : eventName,
        id: eventId.isEmpty ? null : eventId,
        retryMilliseconds: int.tryParse(retryMilliseconds),
      );
    }

    await for (final line in lines) {
      if (line.isEmpty) {
        final event = buildEvent();
        if (event != null) {
          yield event;
        }
        resetEvent();
        continue;
      }

      if (line.startsWith(':')) {
        continue;
      }

      final separator = line.indexOf(':');
      final field = separator == -1 ? line : line.substring(0, separator);
      var value = separator == -1 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }

      switch (field) {
        case 'event':
          eventName = value;
        case 'data':
          dataLines.add(value);
        case 'id':
          eventId = value;
        case 'retry':
          retryMilliseconds = value;
      }
    }

    final tailEvent = buildEvent();
    if (tailEvent != null) {
      yield tailEvent;
    }
  }
}
