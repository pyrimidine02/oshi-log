/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import 'package:oshi_log/features/identity/account/data/dto/consent_history_dto.dart';
import 'package:oshi_log/features/identity/account/domain/entities/consent_history.dart';

extension ConsentHistoryItemDtoDomainMapper on ConsentHistoryItemDto {
  ConsentHistoryItem toDomain() {
    final dto = this;

    return ConsentHistoryItem(
      type: dto.type,
      version: dto.version,
      agreed: dto.agreed,
      agreedAt: dto.agreedAt,
      label: dto.label,
    );
  }
}
