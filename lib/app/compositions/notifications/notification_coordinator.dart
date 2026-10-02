/// EN: Notification tap -> route decision, composed at the app layer so
///     feature controllers (notifications, titles) and the router are wired
///     together without platform/core depending on either.
/// KO: 알림 탭 -> 경로 결정을 app 레이어에서 조합합니다. feature 컨트롤러
///     (notifications, titles)와 router를 연결하되, platform/core는 둘 중
///     어느 쪽도 의존하지 않습니다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import 'package:oshi_log/features/shared/notifications/application/notifications_controller.dart';
import 'package:oshi_log/features/shared/notifications/domain/entities/notification_navigation.dart';
import 'package:oshi_log/features/identity/progression/application/titles_controller.dart';
import '../../../platform/notifications/local_notifications_service.dart';

/// EN: Origin of a notification tap — affects open-tracking behavior.
/// KO: 알림 탭의 출처입니다 — 오픈 추적 동작에 영향을 줍니다.
enum NotificationTapSource { localNotification, remotePush }

/// EN: Resolve the in-app destination path for a tap event (route decision).
/// KO: 탭 이벤트에 대한 앱 내 목적 경로를 해석합니다 (경로 결정).
String resolveNotificationTapTarget(LocalNotificationTapEvent tapEvent) {
  return resolveNotificationNavigationPath(
        type: tapEvent.type,
        deeplink: tapEvent.deeplink,
        actionUrl: tapEvent.actionUrl,
        entityId: tapEvent.entityId,
      ) ??
      '/notifications';
}

/// EN: Handle a notification tap end-to-end: mark-read, open-tracking,
///     title-cache invalidation, and navigation.
/// KO: 알림 탭을 끝까지 처리합니다: 읽음 처리, 오픈 추적, 칭호 캐시 무효화,
///     네비게이션.
void handleNotificationTap({
  required WidgetRef ref,
  required GoRouter router,
  required LocalNotificationTapEvent tapEvent,
  required NotificationTapSource source,
}) {
  final notifier = ref.read(notificationsControllerProvider.notifier);
  if (tapEvent.notificationId.isNotEmpty) {
    unawaited(notifier.markAsRead(tapEvent.notificationId, refresh: false));
    if (source == NotificationTapSource.localNotification) {
      unawaited(
        ref
            .read(remotePushServiceProvider)
            .trackNotificationOpen(tapEvent.notificationId),
      );
    }
  }

  final normalizedType = normalizeNotificationType(tapEvent.type);
  // EN: Ensure title caches are fresh before navigating so the title picker
  //     reflects earned titles granted since the last cache population.
  // KO: 탭 후 이동 전 칭호 캐시를 무효화하여 마지막 캐시 이후 부여된
  //     칭호가 칭호 피커에 반영되도록 합니다.
  if (normalizedType == notificationTypeTitleEarned) {
    unawaited(
      ref.read(titlesRepositoryProvider.future).then((repo) async {
        await repo.invalidateTitleCaches();
        unawaited(ref.read(activeTitleProvider.notifier).refresh());
      }),
    );
  }

  final targetPath = resolveNotificationTapTarget(tapEvent);
  final currentPath = router.routeInformationProvider.value.uri.path;
  if (currentPath != targetPath) {
    router.go(targetPath);
  }
  unawaited(notifier.refreshInBackground(minInterval: Duration.zero));
}
