/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import 'package:oshi_log/features/identity/account/data/dto/privacy_rights_dto.dart';
import 'package:oshi_log/features/identity/account/domain/entities/privacy_rights.dart';

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
