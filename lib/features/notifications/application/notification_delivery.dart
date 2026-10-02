/// EN: Notification delivery adapter — converts raw platform envelopes
///     (Firebase `RemoteMessage`, local-notification tap payloads) into
///     feature-typed [NotificationItem]s, and wires the platform
///     `RemotePushService`/`LocalNotificationsService` providers. The
///     platform layer never imports feature types; this file is the single
///     seam where that conversion happens.
/// KO: 원시 플랫폼 envelope(Firebase `RemoteMessage`, 로컬 알림 탭 payload)을
///     업무 타입 [NotificationItem]으로 변환하는 어댑터입니다. 플랫폼
///     레이어는 feature 타입을 import하지 않으며, 이 파일이 변환이
///     일어나는 유일한 경계입니다.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../platform/notifications/local_notifications_service.dart';
import '../data/notification_device_registration.dart';
import '../domain/entities/notification_entities.dart';
import '../domain/entities/notification_navigation.dart';

/// EN: Convert a raw Firebase [RemoteMessage] into a [NotificationItem], or
///     `null` when required fields are missing.
/// KO: 원시 Firebase [RemoteMessage]를 [NotificationItem]으로 변환합니다.
///     필수 필드가 없으면 `null`을 반환합니다.
NotificationItem? notificationItemFromRemoteMessage(RemoteMessage message) {
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

/// EN: Show a local system notification for a business [NotificationItem] by
///     translating it into the platform's raw envelope parameters.
/// KO: 업무 [NotificationItem]을 플랫폼의 원시 envelope 파라미터로 변환해
///     로컬 시스템 알림으로 표시합니다.
Future<void> showLocalNotificationItem(
  LocalNotificationsService service,
  NotificationItem item,
) {
  return service.showNotification(
    id: item.id,
    title: item.title,
    body: item.body,
    type: normalizeNotificationType(item.type),
    deeplink: item.deeplink,
    actionUrl: item.actionUrl,
    entityId: item.entityId,
    projectCode: item.projectCode,
  );
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

// ========================================
// EN: Providers — device registration lives here (feature data); the
//     `RemotePushService` itself is composed in `core_providers.dart` via
//     override-able callback seams (see `notificationUpsertDeviceRegistrationProvider`
//     and friends) so that core/platform never imports this feature, and so
//     that other features (e.g. auth) depending on `remotePushServiceProvider`
//     do not create a feature->feature edge back into notifications.
// KO: 프로바이더 — 디바이스 등록은 feature data에 둡니다. `RemotePushService`
//     자체는 override 가능한 콜백 seam(`notificationUpsertDeviceRegistrationProvider`
//     등)을 통해 `core_providers.dart`에서 조합됩니다. core/platform이 이
//     feature를 import하지 않게 하고, `remotePushServiceProvider`에 의존하는
//     다른 feature(예: auth)가 notifications로의 feature->feature 간선을
//     만들지 않도록 하기 위함입니다.
// ========================================

/// EN: Notification device registration provider.
/// KO: 알림 디바이스 등록 프로바이더입니다.
final notificationDeviceRegistrationProvider =
    Provider<NotificationDeviceRegistration>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      final secureStorage = ref.watch(secureStorageProvider);
      final localStorageFuture = ref.watch(localStorageProvider.future);
      return NotificationDeviceRegistration(
        apiClient: apiClient,
        secureStorage: secureStorage,
        localStorageFuture: localStorageFuture,
      );
    });

/// EN: Stream provider for foreground FCM messages, converted to
///     [NotificationItem] — feeds the in-app banner queue.
/// KO: [NotificationItem]으로 변환된 포그라운드 FCM 메시지 스트림
///     프로바이더입니다 — 인앱 배너 큐에 공급합니다.
final remotePushForegroundMessagesProvider = StreamProvider<NotificationItem>((
  ref,
) {
  return ref
      .watch(remotePushServiceProvider)
      .foregroundMessages
      .map(notificationItemFromRemoteMessage)
      .where((item) => item != null)
      .cast<NotificationItem>();
});

/// EN: Stream provider for remote-push open tap events.
/// KO: 원격 푸시 오픈 탭 이벤트 스트림 프로바이더입니다.
final remotePushTapEventsProvider = StreamProvider<LocalNotificationTapEvent>((
  ref,
) {
  return ref.watch(remotePushServiceProvider).tapEvents;
});
