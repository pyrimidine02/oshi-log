import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/notifications/local_notifications_service.dart';
import 'package:oshi_log/core/notifications/remote_push_service.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/utils/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.instance.init();
  });

  group('RemotePushService helpers', () {
    test('computeNotificationDeviceHash uses SHA-256 with fixed salt', () {
      final hash = computeNotificationDeviceHash('android-raw-1');

      expect(
        hash,
        'af5e55f7f23364f56286babefad5d6f13d51545cbadca3869744426cc2670b37',
      );
      expect(hash.length, 64);
    });

    test('normalizeNotificationDeviceHash accepts only 64-char hex', () {
      expect(normalizeNotificationDeviceHash('ABCDEF'), isNull);
      expect(normalizeNotificationDeviceHash('KST'), isNull);
      expect(
        normalizeNotificationDeviceHash(
          'AF5E55F7F23364F56286BABEFAD5D6F13D51545CBADCA3869744426CC2670B37',
        ),
        'af5e55f7f23364f56286babefad5d6f13d51545cbadca3869744426cc2670b37',
      );
    });

    test('normalizeNotificationTimezone accepts IANA names only', () {
      expect(normalizeNotificationTimezone('Asia/Seoul'), 'Asia/Seoul');
      expect(
        normalizeNotificationTimezone('America/New_York'),
        'America/New_York',
      );
      expect(normalizeNotificationTimezone('KST'), isNull);
      expect(normalizeNotificationTimezone('+09:00'), isNull);
    });

    test(
      'buildNotificationDeviceRegistrationPayload includes valid optional fields',
      () {
        final payload = buildNotificationDeviceRegistrationPayload(
          platform: 'ANDROID',
          provider: 'FCM',
          deviceId: 'android-123',
          pushToken: 'token-xyz',
          locale: ' ko-KR ',
          timezone: 'Asia/Seoul',
          deviceHash:
              'AF5E55F7F23364F56286BABEFAD5D6F13D51545CBADCA3869744426CC2670B37',
        );

        expect(payload['platform'], 'ANDROID');
        expect(payload['provider'], 'FCM');
        expect(payload['deviceId'], 'android-123');
        expect(payload['pushToken'], 'token-xyz');
        expect(payload['locale'], 'ko-KR');
        expect(payload['timezone'], 'Asia/Seoul');
        expect(
          payload['deviceHash'],
          'af5e55f7f23364f56286babefad5d6f13d51545cbadca3869744426cc2670b37',
        );
      },
    );

    test(
      'buildNotificationDeviceRegistrationPayload omits invalid timezone/hash',
      () {
        final payload = buildNotificationDeviceRegistrationPayload(
          platform: 'ANDROID',
          provider: 'FCM',
          deviceId: 'android-123',
          pushToken: 'token-xyz',
          locale: '  ',
          timezone: 'KST',
          deviceHash: 'invalid',
        );

        expect(payload.containsKey('locale'), isFalse);
        expect(payload.containsKey('timezone'), isFalse);
        expect(payload.containsKey('deviceHash'), isFalse);
      },
    );
  });

  group('RemotePushService.trackNotificationOpen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
    });

    test(
      'posts open endpoint with secure deviceId query when available',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          SecureStorageKeys.notificationDeviceId: 'secure-123',
          SecureStorageKeys.notificationPushToken: 'secure-token',
        });
        SharedPreferences.setMockInitialValues(<String, Object>{
          LocalStorageKeys.notificationDeviceIdLegacy: 'legacy-android-123',
          LocalStorageKeys.notificationPushToken: 'legacy-token',
        });
        final storage = await LocalStorage.create();
        final apiClient = _FakeApiClient();
        final service = RemotePushService(
          apiClient: apiClient,
          secureStorage: SecureStorage(),
          localStorageFuture: Future<LocalStorage>.value(storage),
          localNotificationsService: LocalNotificationsService(),
        );

        await service.trackNotificationOpen('noti-1');

        expect(apiClient.postCalls, hasLength(1));
        final call = apiClient.postCalls.single;
        expect(call.path, ApiEndpoints.notificationOpen('noti-1'));
        expect(call.queryParameters?['deviceId'], 'secure-123');
        expect(call.data, isNull);
      },
    );

    test('migrates legacy deviceId into secure storage when needed', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalStorageKeys.notificationDeviceIdLegacy: 'legacy-android-123',
      });
      final storage = await LocalStorage.create();
      final apiClient = _FakeApiClient();
      final service = RemotePushService(
        apiClient: apiClient,
        secureStorage: SecureStorage(),
        localStorageFuture: Future<LocalStorage>.value(storage),
        localNotificationsService: LocalNotificationsService(),
      );

      await service.trackNotificationOpen('noti-2');

      expect(apiClient.postCalls, hasLength(1));
      final call = apiClient.postCalls.single;
      expect(call.path, ApiEndpoints.notificationOpen('noti-2'));
      expect(call.queryParameters?['deviceId'], 'legacy-android-123');
      expect(call.data, isNull);
      expect(
        await SecureStorage().getNotificationDeviceId(),
        'legacy-android-123',
      );
      expect(
        storage.getString(LocalStorageKeys.notificationDeviceIdLegacy),
        isNull,
      );
    });

    test('skips request when notificationId is blank', () async {
      final storage = await LocalStorage.create();
      final apiClient = _FakeApiClient();
      final service = RemotePushService(
        apiClient: apiClient,
        secureStorage: SecureStorage(),
        localStorageFuture: Future<LocalStorage>.value(storage),
        localNotificationsService: LocalNotificationsService(),
      );

      await service.trackNotificationOpen('   ');

      expect(apiClient.postCalls, isEmpty);
    });

    test(
      'deactivateCurrentDevice clears secure and legacy notification storage',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          SecureStorageKeys.notificationDeviceId: 'secure-123',
          SecureStorageKeys.notificationPushToken: 'secure-token',
        });
        SharedPreferences.setMockInitialValues(<String, Object>{
          LocalStorageKeys.notificationDeviceIdLegacy: 'legacy-123',
          LocalStorageKeys.notificationPushToken: 'legacy-token',
        });
        final storage = await LocalStorage.create();
        final apiClient = _FakeApiClient();
        apiClient.deleteResult = const Result.success(<String, dynamic>{});
        final secureStorage = SecureStorage();
        final service = RemotePushService(
          apiClient: apiClient,
          secureStorage: secureStorage,
          localStorageFuture: Future<LocalStorage>.value(storage),
          localNotificationsService: LocalNotificationsService(),
        );

        await service.deactivateCurrentDevice();

        expect(apiClient.deleteCalls, hasLength(1));
        expect(await secureStorage.getNotificationDeviceId(), isNull);
        expect(await secureStorage.getNotificationPushToken(), isNull);
        expect(
          storage.getString(LocalStorageKeys.notificationDeviceIdLegacy),
          isNull,
        );
        expect(
          storage.getString(LocalStorageKeys.notificationPushToken),
          isNull,
        );
      },
    );
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(secureStorage: SecureStorage());

  final List<_PostCall> postCalls = <_PostCall>[];
  final List<_DeleteCall> deleteCalls = <_DeleteCall>[];
  Result<dynamic> postResult = const Result.success(<String, dynamic>{});
  Result<dynamic> deleteResult = const Result.success(<String, dynamic>{});

  @override
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    postCalls.add(
      _PostCall(path: path, data: data, queryParameters: queryParameters),
    );
    return postResult as Result<T>;
  }

  @override
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    deleteCalls.add(
      _DeleteCall(path: path, data: data, queryParameters: queryParameters),
    );
    return deleteResult as Result<T>;
  }
}

class _PostCall {
  const _PostCall({
    required this.path,
    required this.data,
    required this.queryParameters,
  });

  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
}

class _DeleteCall {
  const _DeleteCall({
    required this.path,
    required this.data,
    required this.queryParameters,
  });

  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
}
