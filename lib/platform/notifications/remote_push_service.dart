/// EN: Firebase remote push service for token lifecycle and tap routing.
/// KO: 토큰 생명주기/탭 라우팅을 위한 Firebase 원격 푸시 서비스입니다.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logging/app_logger.dart';
import '../storage/local_storage.dart';
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

/// EN: Push token credential resolved for the current platform.
/// KO: 현재 플랫폼에서 해석된 푸시 토큰 자격 증명입니다.
class PushCredential {
  const PushCredential({required this.provider, required this.token});

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

/// EN: Remote push coordinator. Deals only in raw Firebase/platform types —
///     feature-typed conversion and device-registration persistence are
///     injected/consumed by `features/notifications`.
/// KO: 원격 푸시 동기화 코디네이터입니다. 원시 Firebase/플랫폼 타입만 다루며,
///     업무 타입 변환과 디바이스 등록 영속화는 `features/notifications`에서
///     주입/소비합니다.
class RemotePushService {
  RemotePushService({
    required Future<LocalStorage> localStorageFuture,
    required Future<void> Function(
      String pushToken, {
      required String provider,
      required bool forceRegister,
    })
    upsertDeviceRegistration,
    required Future<void> Function() deactivateCurrentDevice,
    required Future<void> Function(String notificationId, {String? deviceId})
    trackNotificationOpen,
    FirebaseMessaging? messaging,
  }) : _localStorageFuture = localStorageFuture,
       _upsertDeviceRegistration = upsertDeviceRegistration,
       _deactivateCurrentDeviceImpl = deactivateCurrentDevice,
       _trackNotificationOpenImpl = trackNotificationOpen,
       _messaging = messaging;

  final Future<LocalStorage> _localStorageFuture;
  final Future<void> Function(
    String pushToken, {
    required String provider,
    required bool forceRegister,
  })
  _upsertDeviceRegistration;
  final Future<void> Function() _deactivateCurrentDeviceImpl;
  final Future<void> Function(String notificationId, {String? deviceId})
  _trackNotificationOpenImpl;
  FirebaseMessaging? _messaging;
  final StreamController<LocalNotificationTapEvent> _tapEventsController =
      StreamController<LocalNotificationTapEvent>.broadcast();

  // EN: Stream of raw foreground push messages for in-app banner display.
  //     Feature-typed conversion happens in notification_delivery.dart.
  // KO: 인앱 배너 표시를 위한 원시 포그라운드 푸시 메시지 스트림입니다.
  //     업무 타입 변환은 notification_delivery.dart에서 처리합니다.
  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _isAuthenticated = false;
  // EN: Prevents concurrent device registration/token sync calls.
  // KO: 디바이스 등록/토큰 동기화 동시 호출을 방지합니다.
  bool _isSyncing = false;

  /// EN: Stream of push-open tap events mapped to existing notification routing model.
  /// KO: 기존 알림 라우팅 모델로 매핑된 푸시 오픈 탭 이벤트 스트림입니다.
  Stream<LocalNotificationTapEvent> get tapEvents =>
      _tapEventsController.stream;

  /// EN: Stream of raw foreground push messages for in-app banner display.
  /// KO: 인앱 배너 표시를 위한 원시 포그라운드 푸시 메시지 스트림입니다.
  Stream<RemoteMessage> get foregroundMessages =>
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
  Future<void> deactivateCurrentDevice() => _deactivateCurrentDeviceImpl();

  /// EN: Record notification-open event (best-effort, no UX impact on failure).
  /// KO: 알림 오픈 이벤트를 기록합니다 (실패 시 UX 영향 없이 best-effort).
  Future<void> trackNotificationOpen(
    String notificationId, {
    String? deviceId,
  }) => _trackNotificationOpenImpl(notificationId, deviceId: deviceId);

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

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final storage = await _localStorageFuture;
    final pushEnabled =
        storage.getBool(LocalStorageKeys.notificationsEnabled) ?? true;
    if (!pushEnabled) {
      return;
    }

    // EN: Emit the raw message so the feature delivery adapter can convert
    //     and decide how to display it (in-app banner, local system alert).
    // KO: 업무 전달 어댑터가 변환·표시 방식(인앱 배너, 로컬 시스템 알림)을
    //     결정할 수 있도록 원시 메시지를 발행합니다.
    _foregroundMessageController.add(message);
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
        // EN: Raw type, unnormalized — normalization is a business concern
        //     applied by the delivery/navigation adapter.
        // KO: 정규화되지 않은 원시 타입입니다 — 정규화는 delivery/navigation
        //     어댑터가 처리하는 업무 로직입니다.
        type: _firstNonEmpty(
          data['notificationType']?.toString(),
          data['type']?.toString(),
          data['eventType']?.toString(),
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

  Future<PushCredential?> _resolvePushCredential(
    FirebaseMessaging messaging,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = (await messaging.getAPNSToken())?.trim();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return PushCredential(provider: 'APNS', token: apnsToken);
      }
      final fcmToken = (await messaging.getToken())?.trim();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        return PushCredential(provider: 'FCM', token: fcmToken);
      }
      return null;
    }

    final fcmToken = (await messaging.getToken())?.trim();
    if (fcmToken == null || fcmToken.isEmpty) {
      return null;
    }
    return PushCredential(provider: 'FCM', token: fcmToken);
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
