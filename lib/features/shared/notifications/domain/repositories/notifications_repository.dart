/// EN: Notifications repository interface.
/// KO: 알림 리포지토리 인터페이스.
library;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/shared/notifications/domain/entities/notification_entities.dart';

abstract class NotificationsRepository {
  /// EN: Get paginated notifications for the current user.
  /// KO: 현재 사용자의 페이지네이션된 알림을 가져옵니다.
  Future<Result<List<NotificationItem>>> getNotifications({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  Future<Result<void>> markAsRead(String notificationId);

  /// EN: Delete a single notification by ID.
  /// KO: ID로 단일 알림을 삭제합니다.
  Future<Result<void>> deleteNotification(String notificationId);

  /// EN: Delete all notifications for the current user.
  /// KO: 현재 사용자의 모든 알림을 삭제합니다.
  Future<Result<void>> deleteAllNotifications();
}
