/// EN: Firebase remote push service for token lifecycle and tap routing.
/// KO: 토큰 생명주기/탭 라우팅을 위한 Firebase 원격 푸시 서비스입니다.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../features/notifications/domain/entities/notification_entities.dart';
import '../../features/notifications/domain/entities/notification_navigation.dart';
import '../constants/api_constants.dart';
import '../error/failure.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../security/secure_storage.dart';
import '../storage/local_storage.dart';
import '../utils/result.dart';
import 'firebase_runtime_options.dart';
import 'local_notifications_service.dart';

/// EN: Register Firebase background message handler once at startup.
/// KO: 앱 시작 시 Firebase 백그라운드 메시지 핸들러를 1회 등록합니다.
void registerRemotePushBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

const String _kPushChannelId = 'gbt_notifications_high';
const String _kPushChannelName = 'Oshi@log Notifications';
const String _kPushChannelDescription =
    'Realtime community and system notifications';
final FlutterLocalNotificationsPlugin _backgroundNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool _backgroundNotificationsInitialized = false;
const String _kDeviceHashSalt = 'gbt-salt-v1';
final RegExp _kNotificationDeviceHashPattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _kIanaTimezonePattern = RegExp(
  r'^[A-Za-z_]+(?:/[A-Za-z0-9._+\-]+)+$',
);

class _PushCredential {
  const _PushCredential({required this.provider, required this.token});

  final String provider;
  final String token;
}

Future<void> _ensureBackgroundNotificationPluginInitialized() async {
  if (_backgroundNotificationsInitialized) {
    return;
  }

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(android: android, iOS: ios);

  await _backgroundNotificationsPlugin.initialize(settings);

  const channel = AndroidNotificationChannel(
    _kPushChannelId,
    _kPushChannelName,
    description: _kPushChannelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await _backgroundNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  _backgroundNotificationsInitialized = true;
}

Future<void> _showBackgroundLocalNotificationIfNeeded(
  RemoteMessage message,
) async {
  // EN: Skip local duplication when OS will present remote notification itself.
  // KO: OS가 원격 알림을 직접 표시하는 경우 로컬 중복 표시를 건너뜁니다.
  if (message.notification != null) {
    return;
  }

  final title = _firstNonEmpty(_resolvePushTitle(message), 'Oshi@log');
  final body = _resolvePushBody(message);
  if (title == null || body == null || body.isEmpty) {
    return;
  }

  await _ensureBackgroundNotificationPluginInitialized();

  final details = NotificationDetails(
    android: const AndroidNotificationDetails(
      _kPushChannelId,
      _kPushChannelName,
      channelDescription: _kPushChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  final notificationId = _stableBackgroundNotificationId(
    _firstNonEmpty(
          message.data['notificationId']?.toString(),
          message.data['id']?.toString(),
          message.messageId,
        ) ??
        'fcm-${DateTime.now().microsecondsSinceEpoch}',
  );

  await _backgroundNotificationsPlugin.show(
    notificationId,
    title,
    body,
    details,
    payload: jsonEncode({
      'notificationId': _firstNonEmpty(
        message.data['notificationId']?.toString(),
        message.data['id']?.toString(),
        message.messageId,
      ),
      'type': _firstNonEmpty(
        message.data['notificationType']?.toString(),
        message.data['type']?.toString(),
        message.data['eventType']?.toString(),
      ),
      'notificationType': _firstNonEmpty(
        message.data['notificationType']?.toString(),
        message.data['type']?.toString(),
        message.data['eventType']?.toString(),
      ),
      'deeplink': _firstNonEmpty(
        message.data['deeplink']?.toString(),
        message.data['deepLink']?.toString(),
      ),
      'deepLink': _firstNonEmpty(
        message.data['deeplink']?.toString(),
        message.data['deepLink']?.toString(),
      ),
      'actionUrl': message.data['actionUrl']?.toString(),
      'entityId': _firstNonEmpty(
        message.data['targetId']?.toString(),
        message.data['entityId']?.toString(),
        message.data['contentId']?.toString(),
      ),
      'targetId': _firstNonEmpty(
        message.data['targetId']?.toString(),
        message.data['entityId']?.toString(),
        message.data['contentId']?.toString(),
      ),
      'projectCode': _firstNonEmpty(
        message.data['projectCode']?.toString(),
        message.data['projectId']?.toString(),
      ),
      'projectId': _firstNonEmpty(
        message.data['projectCode']?.toString(),
        message.data['projectId']?.toString(),
      ),
      'priority': _firstNonEmpty(
        message.data['priority']?.toString(),
        'normal',
      ),
    }),
  );
}

Future<void> _ensureFirebaseAppInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  try {
    await Firebase.initializeApp();
    return;
  } catch (_) {
    // EN: Fallback to dart-define runtime options when bundled config is absent.
    // KO: 번들 설정 파일이 없을 때 dart-define 런타임 옵션으로 대체 초기화합니다.
  }

  final runtimeOptions = FirebaseRuntimeOptions.resolveForCurrentPlatform();
  if (runtimeOptions == null) {
    throw StateError('Firebase options are missing for this platform.');
  }
  await Firebase.initializeApp(options: runtimeOptions);
  AppLogger.info(
    'Firebase initialized with runtime options',
    tag: 'RemotePushService',
  );
}

int _stableBackgroundNotificationId(String seed) {
  return seed.hashCode & 0x7fffffff;
}

/// EN: Compute salted SHA-256 hash for notification device fingerprinting.
/// KO: 알림 디바이스 지문용 salt 적용 SHA-256 해시를 계산합니다.
String computeNotificationDeviceHash(String rawDeviceId) {
  final normalizedRawDeviceId = rawDeviceId.trim();
  final digest = sha256.convert(
    utf8.encode('$normalizedRawDeviceId:$_kDeviceHashSalt'),
  );
  return digest.toString();
}

/// EN: Normalize and validate a notification device hash (64-char lowercase hex).
/// KO: 알림 디바이스 해시를 정규화/검증합니다 (64자 소문자 16진수).
String? normalizeNotificationDeviceHash(String? deviceHash) {
  if (deviceHash == null) {
    return null;
  }
  final normalized = deviceHash.trim().toLowerCase();
  if (normalized.isEmpty ||
      !_kNotificationDeviceHashPattern.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

/// EN: Normalize and validate IANA timezone names (for Quiet Hours).
/// KO: IANA 타임존 문자열을 정규화/검증합니다 (Quiet Hours 용).
String? normalizeNotificationTimezone(String? timezone) {
  if (timezone == null) {
    return null;
  }
  final normalized = timezone.trim();
  if (normalized.isEmpty || !_kIanaTimezonePattern.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

/// EN: Build notification device registration payload with optional metadata.
/// KO: 선택 메타데이터를 포함한 알림 디바이스 등록 payload를 구성합니다.
Map<String, dynamic> buildNotificationDeviceRegistrationPayload({
  required String platform,
  required String provider,
  required String deviceId,
  required String pushToken,
  String? locale,
  String? timezone,
  String? deviceHash,
}) {
  final normalizedLocale = locale?.trim();
  final normalizedTimezone = normalizeNotificationTimezone(timezone);
  final normalizedDeviceHash = normalizeNotificationDeviceHash(deviceHash);

  return <String, dynamic>{
    'platform': platform,
    'provider': provider,
    'deviceId': deviceId,
    'pushToken': pushToken,
    if (normalizedLocale != null && normalizedLocale.isNotEmpty)
      'locale': normalizedLocale,
    if (normalizedTimezone != null) 'timezone': normalizedTimezone,
    if (normalizedDeviceHash != null) 'deviceHash': normalizedDeviceHash,
  };
}

/// EN: Background entrypoint for Firebase Messaging.
/// KO: Firebase Messaging 백그라운드 엔트리포인트입니다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    widgets.WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await _ensureFirebaseAppInitialized();
    await _showBackgroundLocalNotificationIfNeeded(message);
  } catch (_) {
    // EN: Ignore to keep background isolate safe when Firebase config is absent.
    // KO: Firebase 설정 파일이 없을 때도 백그라운드 isolate 안정성을 위해 무시합니다.
  }
}

/// EN: Remote push coordinator.
/// KO: 원격 푸시 동기화 코디네이터입니다.
class RemotePushService {
  RemotePushService({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
    required Future<LocalStorage> localStorageFuture,
    required LocalNotificationsService localNotificationsService,
    FirebaseMessaging? messaging,
    Future<String?> Function()? deviceHashResolver,
    Future<String?> Function()? timezoneResolver,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage,
       _localStorageFuture = localStorageFuture,
       _localNotificationsService = localNotificationsService,
       _deviceHashResolver = deviceHashResolver,
       _timezoneResolver = timezoneResolver,
       _messaging = messaging;

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  final Future<LocalStorage> _localStorageFuture;
  final LocalNotificationsService _localNotificationsService;
  final Future<String?> Function()? _deviceHashResolver;
  final Future<String?> Function()? _timezoneResolver;
  FirebaseMessaging? _messaging;
  final StreamController<LocalNotificationTapEvent> _tapEventsController =
      StreamController<LocalNotificationTapEvent>.broadcast();

  // EN: Stream of foreground push messages for in-app banner display.
  // KO: 인앱 배너 표시를 위한 포그라운드 푸시 메시지 스트림입니다.
  final StreamController<NotificationItem> _foregroundMessageController =
      StreamController<NotificationItem>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _isAuthenticated = false;
  // EN: Prevents concurrent device registration/token sync calls.
  // KO: 디바이스 등록/토큰 동기화 동시 호출을 방지합니다.
  bool _isSyncing = false;
  String? _cachedDeviceHash;
  String? _cachedTimezone;

  /// EN: Stream of push-open tap events mapped to existing notification routing model.
  /// KO: 기존 알림 라우팅 모델로 매핑된 푸시 오픈 탭 이벤트 스트림입니다.
  Stream<LocalNotificationTapEvent> get tapEvents =>
      _tapEventsController.stream;

  /// EN: Stream of foreground push notification items for in-app banner display.
  /// KO: 인앱 배너 표시를 위한 포그라운드 푸시 알림 아이템 스트림입니다.
  Stream<NotificationItem> get foregroundMessages =>
      _foregroundMessageController.stream;

  /// EN: Initialize Firebase messaging hooks.
  /// KO: Firebase 메시징 훅을 초기화합니다.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final ready = await _ensureFirebaseReady();
    if (!ready) {
      return;
    }
    final messaging = _messaging;
    if (messaging == null) {
      return;
    }
    _firebaseReady = true;
    _initialized = true;

    await messaging.setForegroundNotificationPresentationOptions(
      // EN: Let iOS present push in foreground so it appears in notification center.
      // KO: iOS 포그라운드에서도 알림센터에 표시되도록 시스템 표시를 허용합니다.
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
      if (!_isAuthenticated || token.trim().isEmpty) {
        return;
      }
      unawaited(
        _upsertDeviceRegistration(
          token.trim(),
          provider: 'FCM',
          forceRegister: false,
        ),
      );
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }
  }

  /// EN: Update auth state and sync registration when authenticated.
  /// KO: 인증 상태를 갱신하고 인증됨 상태에서 디바이스 등록을 동기화합니다.
  Future<void> setAuthenticated(bool value) async {
    _isAuthenticated = value;
    if (!value) {
      return;
    }
    await syncRegistration();
  }

  /// EN: Request push permission from OS.
  /// KO: OS 푸시 권한을 요청합니다.
  Future<bool> requestPermission() async {
    final ready = await _ensureFirebaseReady();
    if (!ready) {
      return false;
    }
    final messaging = _messaging;
    if (messaging == null) {
      return false;
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  /// EN: Sync device registration/token with backend.
  /// EN: Concurrent calls are serialized: a second call while one is in
  /// EN: progress is silently dropped to prevent duplicate POST/PATCH requests.
  /// KO: 디바이스 등록/토큰을 백엔드와 동기화합니다.
  /// KO: 동시 호출은 직렬화됩니다: 진행 중에 두 번째 호출이 오면
  /// KO: 중복 POST/PATCH 요청을 방지하기 위해 조용히 무시됩니다.
  Future<void> syncRegistration() async {
    if (!_isAuthenticated) {
      return;
    }
    // EN: Drop concurrent sync to avoid duplicate device POST/PATCH races.
    // KO: 디바이스 POST/PATCH 경쟁을 방지하기 위해 동시 동기화를 건너뜁니다.
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      final ready = await _ensureFirebaseReady();
      if (!ready) {
        return;
      }
      final messaging = _messaging;
      if (messaging == null) {
        return;
      }

      final storage = await _localStorageFuture;
      final pushEnabled =
          storage.getBool(LocalStorageKeys.notificationsEnabled) ?? true;
      if (!pushEnabled) {
        return;
      }

      final credential = await _resolvePushCredential(messaging);
      if (credential == null) {
        AppLogger.warning(
          'Push token is unavailable; skip registration sync',
          tag: 'RemotePushService',
        );
        return;
      }

      await _upsertDeviceRegistration(
        credential.token,
        provider: credential.provider,
        forceRegister: false,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// EN: Deactivate current backend device registration and clear local keys.
  /// KO: 현재 백엔드 디바이스 등록을 비활성화하고 로컬 키를 정리합니다.
  Future<void> deactivateCurrentDevice() async {
    final storage = await _localStorageFuture;
    final deviceId = await _resolveStoredDeviceId(
      storage,
      migrateLegacyKeys: false,
    );
    if (deviceId == null || deviceId.isEmpty) {
      return;
    }

    final result = await _apiClient.delete<dynamic>(
      ApiEndpoints.notificationDevice(deviceId),
    );

    if (result is Success<dynamic>) {
      await _clearNotificationRegistration(storage);
      return;
    }

    if (result is Err<dynamic>) {
      final failure = result.failure;
      if (failure is NotFoundFailure && failure.code == '404') {
        await _clearNotificationRegistration(storage);
        return;
      }
      AppLogger.warning(
        'Failed to deactivate notification device registration',
        data: failure,
        tag: 'RemotePushService',
      );
    }
  }

  /// EN: Record notification-open event (best-effort, no UX impact on failure).
  /// KO: 알림 오픈 이벤트를 기록합니다 (실패 시 UX 영향 없이 best-effort).
  Future<void> trackNotificationOpen(
    String notificationId, {
    String? deviceId,
  }) async {
    final normalizedNotificationId = notificationId.trim();
    if (normalizedNotificationId.isEmpty) {
      return;
    }

    final storage = await _localStorageFuture;
    final resolvedDeviceId = _firstNonEmpty(
      deviceId,
      await _resolveStoredDeviceId(storage),
    );

    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.notificationOpen(normalizedNotificationId),
      queryParameters: resolvedDeviceId == null
          ? null
          : <String, dynamic>{'deviceId': resolvedDeviceId},
    );

    if (result is Err<dynamic>) {
      // EN: Do not surface open-tracking failures to users.
      // KO: 오픈 추적 실패는 사용자에게 노출하지 않습니다.
      AppLogger.debug(
        'Failed to record notification open',
        data: result.failure,
        tag: 'RemotePushService',
      );
    }
  }

  /// EN: Dispose stream/listener resources.
  /// KO: 스트림/리스너 리소스를 해제합니다.
  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    _tapEventsController.close();
    _foregroundMessageController.close();
  }

  Future<bool> _ensureFirebaseReady() async {
    if (_firebaseReady) {
      return true;
    }
    try {
      await _ensureFirebaseAppInitialized();
      _messaging ??= FirebaseMessaging.instance;
      _firebaseReady = true;
      return true;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Firebase is not configured; remote push is disabled',
        data: error,
        tag: 'RemotePushService',
      );
      AppLogger.error(
        'Firebase initialize failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'RemotePushService',
      );
      _firebaseReady = false;
      return false;
    }
  }

  Future<void> _upsertDeviceRegistration(
    String pushToken, {
    required String provider,
    required bool forceRegister,
  }) async {
    if (!_isAuthenticated) {
      return;
    }
    final storage = await _localStorageFuture;
    final existingDeviceId = await _resolveStoredDeviceId(storage);
    final deviceId = existingDeviceId ?? await _createAndStoreDeviceId(storage);
    if (deviceId.isEmpty) {
      return;
    }

    final shouldRegister = forceRegister || existingDeviceId == null;
    if (shouldRegister) {
      await _registerDevice(
        storage: storage,
        deviceId: deviceId,
        provider: provider,
        pushToken: pushToken,
      );
      return;
    }

    final patchResult = await _apiClient.patch<dynamic>(
      ApiEndpoints.notificationDeviceToken(deviceId),
      data: {'pushToken': pushToken, 'provider': provider},
    );
    if (patchResult is Success<dynamic>) {
      await _storeNotificationRegistration(
        storage: storage,
        deviceId: deviceId,
        pushToken: pushToken,
      );
      return;
    }

    if (patchResult is Err<dynamic>) {
      final failure = patchResult.failure;
      if (failure is NotFoundFailure && failure.code == '404') {
        await _registerDevice(
          storage: storage,
          deviceId: deviceId,
          provider: provider,
          pushToken: pushToken,
        );
        return;
      }
      AppLogger.warning(
        'Failed to update push token',
        data: failure,
        tag: 'RemotePushService',
      );
    }
  }

  Future<void> _registerDevice({
    required LocalStorage storage,
    required String deviceId,
    required String provider,
    required String pushToken,
  }) async {
    final payload = buildNotificationDeviceRegistrationPayload(
      platform: _platformValue(),
      provider: provider,
      deviceId: deviceId,
      pushToken: pushToken,
      locale: _resolveDeviceLocale(storage),
      timezone: await _resolveDeviceTimezone(),
      deviceHash: await _resolveDeviceHash(),
    );

    final registerResult = await _apiClient.post<dynamic>(
      ApiEndpoints.notificationDevices,
      data: payload,
    );
    if (registerResult is Success<dynamic>) {
      final responseData = registerResult.data;
      var persistedDeviceId = deviceId;
      if (responseData is Map<String, dynamic>) {
        final candidate = _firstNonEmpty(
          responseData['deviceId']?.toString(),
          responseData['id']?.toString(),
        );
        if (candidate != null && candidate.isNotEmpty) {
          persistedDeviceId = candidate;
        }
      }
      await _storeNotificationRegistration(
        storage: storage,
        deviceId: persistedDeviceId,
        pushToken: pushToken,
      );
      return;
    }

    if (registerResult is Err<dynamic>) {
      AppLogger.warning(
        'Failed to register notification device',
        data: registerResult.failure,
        tag: 'RemotePushService',
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final storage = await _localStorageFuture;
    final pushEnabled =
        storage.getBool(LocalStorageKeys.notificationsEnabled) ?? true;
    if (!pushEnabled) {
      return;
    }

    final item = _toNotificationItem(message);
    if (item == null) {
      return;
    }

    // EN: Emit item to the foreground stream so the in-app banner overlay
    //     can consume it — this works for both Android and iOS.
    // KO: 인앱 배너 오버레이가 소비할 수 있도록 포그라운드 스트림에 아이템을 발행합니다.
    //     Android와 iOS 모두 동일하게 처리합니다.
    _foregroundMessageController.add(item);

    // EN: On Android, also show a system notification as a reliable fallback
    //     because the in-app banner is only visible while the app is rendered.
    //     On iOS, setForegroundNotificationPresentationOptions already shows
    //     the system banner — skip local duplication.
    // KO: Android에서는 앱이 렌더링 중일 때만 인앱 배너가 보이므로
    //     시스템 알림을 fallback으로 함께 표시합니다.
    //     iOS에서는 setForegroundNotificationPresentationOptions가 이미
    //     시스템 배너를 표시하므로 중복 표시를 건너뜁니다.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotificationsService.showNotificationItem(item);
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final notificationId = _extractNotificationId(message);
    if (notificationId != null) {
      unawaited(trackNotificationOpen(notificationId));
    }
    _emitTapEvent(message, notificationId: notificationId);
  }

  void _emitTapEvent(RemoteMessage message, {String? notificationId}) {
    final data = message.data;
    final resolvedNotificationId =
        notificationId ?? _extractNotificationId(message);
    if (resolvedNotificationId == null || resolvedNotificationId.isEmpty) {
      return;
    }

    _tapEventsController.add(
      LocalNotificationTapEvent(
        notificationId: resolvedNotificationId,
        type: normalizeNotificationType(
          _firstNonEmpty(
            data['notificationType']?.toString(),
            data['type']?.toString(),
            data['eventType']?.toString(),
          ),
        ),
        deeplink: _firstNonEmpty(
          data['deeplink']?.toString(),
          data['deepLink']?.toString(),
        ),
        actionUrl: data['actionUrl']?.toString(),
        entityId: _firstNonEmpty(
          data['targetId']?.toString(),
          data['entityId']?.toString(),
          data['contentId']?.toString(),
        ),
        projectCode: _firstNonEmpty(
          data['projectCode']?.toString(),
          data['projectId']?.toString(),
        ),
      ),
    );
  }

  String? _extractNotificationId(RemoteMessage message) {
    return _firstNonEmpty(
      message.data['notificationId']?.toString(),
      message.data['id']?.toString(),
      message.messageId,
    );
  }

  NotificationItem? _toNotificationItem(RemoteMessage message) {
    final data = message.data;
    final id = _firstNonEmpty(
      data['notificationId']?.toString(),
      data['id']?.toString(),
      message.messageId,
      'fcm-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (id == null || id.isEmpty) {
      return null;
    }

    final title = _firstNonEmpty(_resolvePushTitle(message), 'Oshi@log');
    final body = _firstNonEmpty(_resolvePushBody(message), '');
    if (title == null || body == null) {
      return null;
    }

    return NotificationItem(
      id: id,
      title: title,
      body: body,
      createdAt: DateTime.now().toUtc(),
      isRead: false,
      type: normalizeNotificationType(
        _firstNonEmpty(
          data['notificationType']?.toString(),
          data['type']?.toString(),
          data['eventType']?.toString(),
        ),
      ),
      actionUrl: data['actionUrl']?.toString(),
      deeplink: _firstNonEmpty(
        data['deeplink']?.toString(),
        data['deepLink']?.toString(),
      ),
      entityId: _firstNonEmpty(
        data['targetId']?.toString(),
        data['entityId']?.toString(),
        data['contentId']?.toString(),
      ),
      projectCode: _firstNonEmpty(
        data['projectCode']?.toString(),
        data['projectId']?.toString(),
      ),
    );
  }

  Future<String?> _resolveStoredDeviceId(
    LocalStorage storage, {
    bool migrateLegacyKeys = true,
  }) async {
    final secureDeviceId = (await _secureStorage.getNotificationDeviceId())
        ?.trim();
    if (secureDeviceId != null && secureDeviceId.isNotEmpty) {
      if (migrateLegacyKeys) {
        await _clearLegacyRegistrationKeys(storage);
      }
      return secureDeviceId;
    }

    final primary = storage.getString(LocalStorageKeys.notificationDeviceId);
    if (primary != null && primary.trim().isNotEmpty) {
      final normalized = primary.trim();
      if (migrateLegacyKeys) {
        await _storeNotificationRegistration(
          storage: storage,
          deviceId: normalized,
          pushToken: storage.getString(LocalStorageKeys.notificationPushToken),
        );
      }
      return normalized;
    }

    final legacy = storage.getString(
      LocalStorageKeys.notificationDeviceIdLegacy,
    );
    if (legacy != null && legacy.trim().isNotEmpty) {
      final normalized = legacy.trim();
      if (migrateLegacyKeys) {
        await _storeNotificationRegistration(
          storage: storage,
          deviceId: normalized,
          pushToken: storage.getString(LocalStorageKeys.notificationPushToken),
        );
      }
      return normalized;
    }
    return null;
  }

  Future<String> _createAndStoreDeviceId(LocalStorage storage) async {
    final generated = '${_platformValue().toLowerCase()}-${const Uuid().v4()}';
    await _storeNotificationRegistration(storage: storage, deviceId: generated);
    return generated;
  }

  Future<void> _storeNotificationRegistration({
    required LocalStorage storage,
    required String deviceId,
    String? pushToken,
  }) async {
    final trimmedDeviceId = deviceId.trim();
    final trimmedPushToken = pushToken?.trim();
    await Future.wait([
      _secureStorage.saveNotificationDeviceId(trimmedDeviceId),
      if (trimmedPushToken != null && trimmedPushToken.isNotEmpty)
        _secureStorage.saveNotificationPushToken(trimmedPushToken),
      _clearLegacyRegistrationKeys(storage),
    ]);
  }

  Future<void> _clearLegacyRegistrationKeys(LocalStorage storage) async {
    await Future.wait([
      storage.remove(LocalStorageKeys.notificationDeviceId),
      storage.remove(LocalStorageKeys.notificationDeviceIdLegacy),
      storage.remove(LocalStorageKeys.notificationPushToken),
    ]);
  }

  Future<void> _clearNotificationRegistration(LocalStorage storage) async {
    await Future.wait([
      _secureStorage.clearNotificationRegistration(),
      _clearLegacyRegistrationKeys(storage),
    ]);
  }

  String _platformValue() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      _ => 'UNKNOWN',
    };
  }

  Future<_PushCredential?> _resolvePushCredential(
    FirebaseMessaging messaging,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = (await messaging.getAPNSToken())?.trim();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return _PushCredential(provider: 'APNS', token: apnsToken);
      }
      final fcmToken = (await messaging.getToken())?.trim();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        return _PushCredential(provider: 'FCM', token: fcmToken);
      }
      return null;
    }

    final fcmToken = (await messaging.getToken())?.trim();
    if (fcmToken == null || fcmToken.isEmpty) {
      return null;
    }
    return _PushCredential(provider: 'FCM', token: fcmToken);
  }

  String? _resolveDeviceLocale(LocalStorage storage) {
    final storedLocale = storage.getLocale()?.trim();
    if (storedLocale != null &&
        storedLocale.isNotEmpty &&
        storedLocale.toLowerCase() != 'system') {
      return storedLocale;
    }
    final currentLocale = Intl.getCurrentLocale().trim();
    return currentLocale.isEmpty ? null : currentLocale;
  }

  Future<String?> _resolveDeviceHash() async {
    if (_cachedDeviceHash != null) {
      return _cachedDeviceHash;
    }

    final hashResolver = _deviceHashResolver;
    if (hashResolver != null) {
      final customHash = normalizeNotificationDeviceHash(await hashResolver());
      if (customHash != null) {
        _cachedDeviceHash = customHash;
      }
      return customHash;
    }

    final rawDeviceIdentifier = await _resolveRawDeviceIdentifier();
    if (rawDeviceIdentifier == null || rawDeviceIdentifier.isEmpty) {
      return null;
    }

    final computedHash = computeNotificationDeviceHash(rawDeviceIdentifier);
    _cachedDeviceHash = computedHash;
    return computedHash;
  }

  Future<String?> _resolveRawDeviceIdentifier() async {
    if (kIsWeb) {
      return null;
    }

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _firstNonEmpty(await AndroidId().getId());
        case TargetPlatform.iOS:
          final iosInfo = await DeviceInfoPlugin().iosInfo;
          return _firstNonEmpty(iosInfo.identifierForVendor);
        default:
          return null;
      }
    } catch (error) {
      AppLogger.debug(
        'Failed to resolve raw device identifier for push registration',
        data: error,
        tag: 'RemotePushService',
      );
      return null;
    }
  }

  Future<String?> _resolveDeviceTimezone() async {
    if (_cachedTimezone != null) {
      return _cachedTimezone;
    }

    final timezoneResolver = _timezoneResolver;
    if (timezoneResolver != null) {
      final customTimezone = normalizeNotificationTimezone(
        await timezoneResolver(),
      );
      if (customTimezone != null) {
        _cachedTimezone = customTimezone;
      }
      return customTimezone;
    }

    try {
      final localTimezone = normalizeNotificationTimezone(
        await FlutterTimezone.getLocalTimezone(),
      );
      if (localTimezone != null) {
        _cachedTimezone = localTimezone;
        return localTimezone;
      }
    } catch (error) {
      AppLogger.debug(
        'Failed to resolve IANA timezone for push registration',
        data: error,
        tag: 'RemotePushService',
      );
    }

    final fallbackTimezone = normalizeNotificationTimezone(
      DateTime.now().timeZoneName,
    );
    if (fallbackTimezone != null) {
      _cachedTimezone = fallbackTimezone;
      return fallbackTimezone;
    }
    return null;
  }
}

String? _firstNonEmpty(
  String? first, [
  String? second,
  String? third,
  String? fourth,
]) {
  final values = [first, second, third, fourth];
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String? _resolvePushTitle(RemoteMessage message) {
  return _firstNonEmpty(
    message.notification?.title,
    message.data['title']?.toString(),
    message.data['notificationTitle']?.toString(),
    message.data['subject']?.toString(),
  );
}

String? _resolvePushBody(RemoteMessage message) {
  return _firstNonEmpty(
    message.notification?.body,
    message.data['body']?.toString(),
    message.data['message']?.toString(),
    message.data['content']?.toString(),
  );
}
