/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/account_tools_dto.dart';
import '../../domain/entities/account_tools.dart';

extension RestoreAccountResultDtoDomainMapper on RestoreAccountResultDto {
  RestoreAccountResult toDomain() {
    final dto = this;

    return RestoreAccountResult(
      result: dto.result,
      restoredAt: dto.restoredAt,
      retentionUntil: dto.retentionUntil,
    );
  }
}

extension BlockedUserDtoDomainMapper on BlockedUserDto {
  BlockedUser toDomain() {
    final dto = this;

    return BlockedUser(
      id: dto.id,
      displayName: dto.displayName,
      avatarUrl: dto.avatarUrl,
    );
  }
}

extension UserBlockDtoDomainMapper on UserBlockDto {
  UserBlock toDomain() {
    final dto = this;

    return UserBlock(
      id: dto.id,
      blockedUser: dto.blockedUser.toDomain(),
      reason: dto.reason,
      createdAt: dto.createdAt,
    );
  }
}

extension VerificationAppealDtoDomainMapper on VerificationAppealDto {
  VerificationAppeal toDomain() {
    final dto = this;

    return VerificationAppeal(
      id: dto.id,
      targetType: dto.targetType,
      targetId: dto.targetId,
      placeId: dto.placeId,
      reason: dto.reason,
      description: dto.description,
      evidenceUrls: List.unmodifiable(dto.evidenceUrls),
      status: dto.status,
      reviewerMemo: dto.reviewerMemo,
      createdAt: dto.createdAt,
      resolvedAt: dto.resolvedAt,
    );
  }
}

extension ProjectRoleRequestDtoDomainMapper on ProjectRoleRequestDto {
  ProjectRoleRequest toDomain() {
    final dto = this;

    return ProjectRoleRequest(
      id: dto.id,
      projectId: dto.projectId,
      projectCode: dto.projectCode,
      projectName: dto.projectName,
      requestedRole: dto.requestedRole,
      status: dto.status,
      justification: dto.justification,
      createdAt: dto.createdAt,
      adminMemo: dto.adminMemo,
      reviewedAt: dto.reviewedAt,
      reviewerId: dto.reviewerId,
      reviewerName: dto.reviewerName,
    );
  }
}
