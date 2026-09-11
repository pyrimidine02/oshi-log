/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/privacy_rights_dto.dart';
import '../../domain/entities/privacy_rights.dart';

extension PrivacySettingsDtoDomainMapper on PrivacySettingsDto {
  PrivacySettings toDomain() {
    final dto = this;

    return PrivacySettings(
      allowAutoTranslation: dto.allowAutoTranslation,
      version: dto.version,
      updatedAt: dto.updatedAt,
    );
  }
}

extension PrivacyRequestRecordDtoDomainMapper on PrivacyRequestRecordDto {
  PrivacyRequestRecord toDomain() {
    final dto = this;

    return PrivacyRequestRecord(
      requestType: dto.requestType,
      status: dto.status,
      requestedAt: dto.requestedAt,
      reason: dto.reason,
    );
  }
}
