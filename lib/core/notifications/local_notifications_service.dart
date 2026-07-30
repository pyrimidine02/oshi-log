/// EN: Local notifications service for in-app alert delivery.
/// KO: 인앱 알림 전달을 위한 로컬 알림 서비스입니다.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/notifications/domain/entities/notification_entities.dart';
import '../../features/notifications/domain/entities/notification_navigation.dart';

/// EN: Structured tap payload from local notification click.
/// KO: 로컬 알림 클릭 시 전달되는 구조화 페이로드입니다.
class LocalNotificationTapEvent {
  const LocalNotificationTapEvent({
    required this.notificationId,
    this.type,
    this.deeplink,
    this.actionUrl,
    this.entityId,
    this.projectCode,
  });

  final String notificationId;
  final String? type;
  final String? deeplink;
  final String? actionUrl;
  final String? entityId;
  final String? projectCode;

  factory LocalNotificationTapEvent.fromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return LocalNotificationTapEvent(
          notificationId:
              decoded['notificationId']?.toString() ??
              decoded['id']?.toString() ??
              '',
          type:
              decoded['notificationType']?.toString() ??
              decoded['type']?.toString(),
          deeplink:
              decoded['deeplink']?.toString() ??
              decoded['deepLink']?.toString(),
          actionUrl: decoded['actionUrl']?.toString(),
          entityId:
              decoded['targetId']?.toString() ??
              decoded['entityId']?.toString(),
          projectCode:
              decoded['projectCode']?.toString() ??
              decoded['projectId']?.toString(),
        );
      }
    } catch (_) {
      // EN: Backward compatibility for plain-id payload.
      // KO: 단순 ID payload 하위 호환 처리.
    }

    return LocalNotificationTapEvent(notificationId: payload);
  }
}

class LocalNotificationsService {
  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<LocalNotificationTapEvent> _tapEventsController =
      StreamController<LocalNotificationTapEvent>.broadcast();
  bool _initialized = false;
  String? _lastTapDedupKey;
  DateTime? _lastTapAt;

  static const String _channelId = 'gbt_notifications_high';
  static const String _channelName = 'Oshi@log Notifications';
  static const String _channelDescription =
      'Realtime community and system notifications';

  /// EN: Stream of local-notification tap events.
  /// KO: 로컬 알림 탭 이벤트 스트림입니다.
  Stream<LocalNotificationTapEvent> get tapEvents =>
      _tapEventsController.stream;

  /// EN: Dispose internal stream resources.
  /// KO: 내부 스트림 리소스를 해제합니다.
  void dispose() {
    _tapEventsController.close();
  }

  /// EN: Initialize plugin and Android channel.
  /// KO: 플러그인과 Android 채널을 초기화합니다.
  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleTapPayload(response.payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse != null) {
      _handleTapPayload(launchResponse.payload);
    }

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// EN: Request runtime notification permissions.
  /// KO: 런타임 알림 권한을 요청합니다.
  Future<bool> requestPermissions() async {
    await initialize();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final grantedValues = <bool>[
      if (iosGranted != null) iosGranted,
      if (macGranted != null) macGranted,
      if (androidGranted != null) androidGranted,
    ];

    if (grantedValues.isEmpty) {
      return true;
    }
    return grantedValues.any((value) => value);
  }

  /// EN: Show a local alert for a newly arrived notification item.
  /// KO: 새로 도착한 알림 항목에 대해 로컬 알림을 표시합니다.
  Future<void> showNotificationItem(NotificationItem item) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _stableNotificationId(item.id),
      item.title,
      item.body,
      details,
      payload: _encodePayload(item),
    );
  }

  void _handleTapPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return;
    }

    final tapEvent = LocalNotificationTapEvent.fromPayload(rawPayload);
    if (tapEvent.notificationId.isEmpty) {
      return;
    }

    final dedupKey = [
      tapEvent.notificationId,
      tapEvent.type ?? '',
      tapEvent.deeplink ?? '',
      tapEvent.actionUrl ?? '',
    ].join('|');
    final now = DateTime.now();
    if (_lastTapDedupKey == dedupKey &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) < const Duration(milliseconds: 500)) {
      return;
    }

    _lastTapDedupKey = dedupKey;
    _lastTapAt = now;
    _tapEventsController.add(tapEvent);
  }

  String _encodePayload(NotificationItem item) {
    final normalizedType = normalizeNotificationType(item.type);
    return jsonEncode({
      'notificationId': item.id,
      if (normalizedType.isNotEmpty) ...{
        'type': normalizedType,
        'notificationType': normalizedType,
      },
      if (item.deeplink != null && item.deeplink!.isNotEmpty) ...{
        'deeplink': item.deeplink,
        'deepLink': item.deeplink,
      },
      if (item.actionUrl != null && item.actionUrl!.isNotEmpty)
        'actionUrl': item.actionUrl,
      if (item.entityId != null && item.entityId!.isNotEmpty) ...{
        'entityId': item.entityId,
        'targetId': item.entityId,
      },
      if (item.projectCode != null && item.projectCode!.isNotEmpty) ...{
        'projectCode': item.projectCode,
        'projectId': item.projectCode,
      },
    });
  }

  int _stableNotificationId(String raw) {
    return raw.hashCode & 0x7fffffff;
  }
}
