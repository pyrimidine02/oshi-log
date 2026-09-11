/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/notification_settings_dto.dart';
import '../../domain/entities/notification_settings.dart';

/// EN: Parse a wire snapshot and map it to the settings domain entity.
/// KO: 와이어 스냅샷을 파싱하여 설정 도메인 엔티티로 변환합니다.
NotificationSettings notificationSettingsFromJson(Map<String, dynamic> json) {
  return NotificationSettingsDto.fromJson(json).toDomain();
}

extension NotificationSettingsDtoDomainMapper on NotificationSettingsDto {
  NotificationSettings toDomain() {
    final dto = this;

    return NotificationSettings(
      pushEnabled: dto.pushEnabled,
      emailEnabled: dto.emailEnabled,
      categories: List.unmodifiable(dto.categories),
      version: dto.version,
      updatedAt: dto.updatedAt,
    );
  }
}
