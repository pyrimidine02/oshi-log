/// EN: Domain entities for account-tools features.
/// KO: 계정 도구 기능 도메인 엔티티.
library;

/// EN: Result of the account restoration request.
/// KO: 계정 복구 요청 결과.
class RestoreAccountResult {
  const RestoreAccountResult({
    required this.result,
    required this.restoredAt,
    this.retentionUntil,
  });

  final String result;
  final DateTime restoredAt;
  final DateTime? retentionUntil;
}

class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
}

class UserBlock {
  const UserBlock({
    required this.id,
    required this.blockedUser,
    required this.createdAt,
    this.reason,
  });

  final String id;
  final BlockedUser blockedUser;
  final String? reason;
  final DateTime createdAt;
}

class VerificationAppeal {
  const VerificationAppeal({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.placeId,
    this.description,
    this.evidenceUrls = const <String>[],
    this.reviewerMemo,
    this.resolvedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String? placeId;
  final String reason;
  final String? description;
  final List<String> evidenceUrls;
  final String status;
  final String? reviewerMemo;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}

class ProjectRoleRequest {
  const ProjectRoleRequest({
    required this.id,
    required this.projectId,
    required this.requestedRole,
    required this.status,
    required this.justification,
    required this.createdAt,
    this.projectCode,
    this.projectName,
    this.adminMemo,
    this.reviewedAt,
    this.reviewerId,
    this.reviewerName,
  });

  final String id;
  final String projectId;
  final String? projectCode;
  final String? projectName;
  final String requestedRole;
  final String status;
  final String justification;
  final DateTime createdAt;
  final String? adminMemo;
  final DateTime? reviewedAt;
  final String? reviewerId;
  final String? reviewerName;

  bool get isPending {
    return status.toUpperCase() == 'PENDING' ||
        status.toUpperCase() == 'OPEN' ||
        status.toUpperCase() == 'REQUESTED';
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'OPEN':
      case 'REQUESTED':
        return '대기중';
      case 'APPROVED':
      case 'GRANTED':
        return '승인됨';
      case 'REJECTED':
      case 'DENIED':
        return '거절됨';
      case 'CANCELED':
      case 'CANCELLED':
        return '취소됨';
      default:
        return status;
    }
  }

  String get requestedRoleLabel {
    switch (requestedRole.toUpperCase()) {
      case 'PLACE_EDITOR':
        return '콘텐츠 편집';
      case 'COMMUNITY_MODERATOR':
        return '커뮤니티 운영';
      case 'ADMIN':
        return '프로젝트 관리자';
      case 'MEMBER':
        return '멤버';
      default:
        return requestedRole;
    }
  }
}
