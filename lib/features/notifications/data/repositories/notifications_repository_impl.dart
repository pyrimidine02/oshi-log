/// EN: Notifications repository implementation with caching.
/// KO: 캐시를 포함한 알림 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../dto/notification_dto.dart';
import '../mappers/notification_entities_mappers.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final NotificationsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<NotificationItem>>> getNotifications({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _pagedCacheKey(page, size);
    final profile = CacheProfiles.notificationsList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<NotificationItemDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchNotifications(page, size),
            toJson: (dtos) => {
              'items': dtos.map((dto) => dto.toJson()).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(NotificationItemDto.fromJson)
                    .toList();
              }
              return <NotificationItemDto>[];
            },
          );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      final result = await _remoteDataSource.markAsRead(notificationId);

      if (result is Success<void>) {
        // EN: Invalidate default page cache on mark-as-read.
        // KO: 읽음 처리 시 기본 페이지 캐시를 무효화합니다.
        await _cacheManager.remove(_pagedCacheKey(0, 20));
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown notification read result',
          code: 'unknown_notification_read',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      final result = await _remoteDataSource.deleteNotification(notificationId);
      if (result is Success<void>) {
        await _cacheManager.remove(_pagedCacheKey(0, 20));
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure('Unknown delete result', code: 'unknown_delete'),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteAllNotifications() async {
    try {
      final result = await _remoteDataSource.deleteAllNotifications();
      if (result is Success<void>) {
        await _cacheManager.remove(_pagedCacheKey(0, 20));
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown delete-all result',
          code: 'unknown_delete_all',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<List<NotificationItemDto>> _fetchNotifications(
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchNotifications(
      page: page,
      size: size,
    );

    if (result is Success<List<NotificationItemDto>>) {
      return result.data;
    }
    if (result is Err<List<NotificationItemDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown notifications result',
      code: 'unknown_notifications',
    );
  }

  static const String _cacheKeyPrefix = 'notifications_list';

  String _pagedCacheKey(int page, int size) {
    return '$_cacheKeyPrefix:p$page:s$size';
  }
}
