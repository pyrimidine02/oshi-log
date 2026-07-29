import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:oshi_log/core/realtime/sse_client.dart';
import 'package:oshi_log/core/security/secure_storage.dart';

class _FakeSecureStorage extends SecureStorage {
  _FakeSecureStorage(this._token) : super();

  final String? _token;

  @override
  Future<String?> getAccessToken() async => _token;
}

class _FakeStreamClient extends http.BaseClient {
  _FakeStreamClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}

void main() {
  group('SseClient', () {
    test('parses event frames into SseEvent objects', () async {
      final streamClient = _FakeStreamClient((_) async {
        final payload = utf8.encode(
          'event: COMMUNITY_POST_CREATED\n'
          'id: evt-1\n'
          'data: {"eventType":"COMMUNITY_POST_CREATED","entityId":"post-1"}\n'
          '\n',
        );
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable([payload]),
          200,
          headers: const {'content-type': 'text/event-stream'},
        );
      });

      final client = SseClient(
        secureStorage: _FakeSecureStorage(null),
        baseUrl: 'https://api.example.com',
        clientFactory: () => streamClient,
      );

      final connection = await client.connect(path: '/api/v1/community/events');
      final events = await connection.events.toList();
      await connection.close();

      expect(events, hasLength(1));
      expect(events.first.event, 'COMMUNITY_POST_CREATED');
      expect(events.first.id, 'evt-1');
      expect(events.first.dataAsJson?['entityId'], 'post-1');
    });

    test('adds authorization header when token exists', () async {
      late http.BaseRequest capturedRequest;
      final streamClient = _FakeStreamClient((request) async {
        capturedRequest = request;
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(const <List<int>>[]),
          200,
          headers: const {'content-type': 'text/event-stream'},
        );
      });

      final client = SseClient(
        secureStorage: _FakeSecureStorage('access-token'),
        baseUrl: 'https://api.example.com',
        clientFactory: () => streamClient,
      );

      final connection = await client.connect(
        path: '/api/v1/notifications/stream',
      );
      await connection.close();

      expect(
        capturedRequest.headers['Authorization'],
        equals('Bearer access-token'),
      );
      expect(capturedRequest.headers['Accept'], equals('text/event-stream'));
    });

    test('surfaces stream disconnect errors to onError handler', () async {
      final responseStreamController = StreamController<List<int>>();
      final streamClient = _FakeStreamClient((_) async {
        scheduleMicrotask(() {
          responseStreamController.add(utf8.encode('data: {"ok":true}\n\n'));
          responseStreamController.addError(
            http.ClientException(
              'Connection closed while receiving data',
              Uri.parse('https://api.example.com/api/v1/notifications/stream'),
            ),
          );
        });
        return http.StreamedResponse(
          responseStreamController.stream,
          200,
          headers: const {'content-type': 'text/event-stream'},
        );
      });

      final client = SseClient(
        secureStorage: _FakeSecureStorage(null),
        baseUrl: 'https://api.example.com',
        clientFactory: () => streamClient,
      );

      final connection = await client.connect(
        path: '/api/v1/notifications/stream',
      );
      final done = Completer<void>();
      final events = <SseEvent>[];
      Object? receivedError;

      final subscription = connection.events.listen(
        events.add,
        onError: (Object error, StackTrace stackTrace) {
          receivedError = error;
          if (!done.isCompleted) {
            done.complete();
          }
        },
        onDone: () {
          if (!done.isCompleted) {
            done.complete();
          }
        },
        cancelOnError: true,
      );

      await done.future.timeout(const Duration(seconds: 2));
      await subscription.cancel();
      await connection.close();
      await responseStreamController.close();

      expect(events, hasLength(1));
      expect(receivedError, isA<http.ClientException>());
    });
  });
}
