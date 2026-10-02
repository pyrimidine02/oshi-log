/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/fan_subject_dto.dart';
import '../../domain/entities/fan_subject.dart';

extension FanSubjectDtoDomainMapper on FanSubjectDto {
  FanSubject toDomain() {
    final dto = this;

    return FanSubject(
      id: dto.id,
      kind: dto.type,
      entityId: dto.entityId,
      key: dto.key,
      name: dto.name,
      description: dto.description,
      imageUrl: dto.imageUrl,
    );
  }
}

extension FanSubjectSubscriptionDtoDomainMapper on FanSubjectSubscriptionDto {
  FanSubjectSubscription toDomain() {
    final dto = this;

    return FanSubjectSubscription(
      subject: dto.subject.toDomain(),
      subscribed: dto.subscribed,
      subscribedAt: dto.subscribedAt,
    );
  }
}
