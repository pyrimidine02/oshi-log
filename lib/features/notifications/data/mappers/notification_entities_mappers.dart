/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/notification_dto.dart';
import '../../domain/entities/notification_navigation.dart';
import '../../domain/entities/notification_entities.dart';

extension NotificationItemDtoDomainMapper on NotificationItemDto {
  NotificationItem toDomain() {
    final dto = this;

    return NotificationItem(
      id: dto.id,
      title: dto.title,
      body: dto.body,
      createdAt: dto.createdAt,
      isRead: dto.isRead,
      type: normalizeNotificationType(dto.type),
      actionUrl: dto.actionUrl,
      deeplink: dto.deeplink,
      entityId: dto.entityId,
      projectCode: dto.projectCode,
    );
  }
}
