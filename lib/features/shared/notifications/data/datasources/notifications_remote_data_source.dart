/// EN: Remote data source for notifications APIs.
/// KO: 알림 API 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/shared/notifications/data/dto/notification_dto.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Fetch paginated notifications for the current user.
  /// KO: 현재 사용자의 페이지네이션된 알림을 조회합니다.
  Future<Result<List<NotificationItemDto>>> fetchNotifications({
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<NotificationItemDto>>(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(NotificationItemDto.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          const listKeys = ['items', 'content', 'data', 'results'];
          for (final key in listKeys) {
            final value = json[key];
            if (value is List) {
              return value
                  .whereType<Map<String, dynamic>>()
                  .map(NotificationItemDto.fromJson)
                  .toList();
            }
          }
        }
        return <NotificationItemDto>[];
      },
    );
  }

  Future<Result<void>> markAsRead(String notificationId) {
    return _apiClient.post<void>(
      ApiEndpoints.notificationRead(notificationId),
      fromJson: (_) {},
    );
  }

  /// EN: Delete a single notification by ID.
  /// KO: ID로 단일 알림을 삭제합니다.
  Future<Result<void>> deleteNotification(String notificationId) {
    return _apiClient.delete<void>(
      ApiEndpoints.notificationDelete(notificationId),
    );
  }

  /// EN: Delete all notifications for the current user.
  /// KO: 현재 사용자의 모든 알림을 삭제합니다.
  Future<Result<void>> deleteAllNotifications() {
    return _apiClient.delete<void>(ApiEndpoints.notificationsDeleteAll);
  }
}
