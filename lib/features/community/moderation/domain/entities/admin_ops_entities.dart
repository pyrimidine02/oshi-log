/// EN: Admin operations domain entities.
/// KO: 운영/관리자 기능 도메인 엔티티.
library;

import 'package:oshi_log/core/security/user_access_level.dart';

/// EN: Community report moderation status.
/// KO: 커뮤니티 신고 처리 상태.
enum AdminReportStatus {
  open,
  inReview,
  resolved,
  rejected,
  duplicate,
  dismissed,
  unknown,
}

extension AdminReportStatusX on AdminReportStatus {
  String get apiValue {
    switch (this) {
      case AdminReportStatus.open:
        return 'OPEN';
      case AdminReportStatus.inReview:
        return 'IN_REVIEW';
      case AdminReportStatus.resolved:
        return 'RESOLVED';
      case AdminReportStatus.rejected:
        return 'REJECTED';
      case AdminReportStatus.duplicate:
        return 'DUPLICATE';
      case AdminReportStatus.dismissed:
        return 'DISMISSED';
      case AdminReportStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case AdminReportStatus.open:
        return '접수됨';
      case AdminReportStatus.inReview:
        return '검토 중';
      case AdminReportStatus.resolved:
        return '조치 완료';
      case AdminReportStatus.rejected:
        return '반려';
      case AdminReportStatus.duplicate:
        return '중복';
      case AdminReportStatus.dismissed:
        return '종결';
      case AdminReportStatus.unknown:
        return '알 수 없음';
    }
  }

  static AdminReportStatus fromApiValue(String? rawValue) {
    switch (rawValue?.toUpperCase()) {
      case 'OPEN':
      case 'PENDING':
      case 'NEW':
        return AdminReportStatus.open;
      case 'IN_REVIEW':
      case 'PROCESSING':
      case 'UNDER_REVIEW':
        return AdminReportStatus.inReview;
      case 'RESOLVED':
      case 'CLOSED':
      case 'ACTIONED':
        return AdminReportStatus.resolved;
      case 'REJECTED':
        return AdminReportStatus.rejected;
      case 'DUPLICATE':
        return AdminReportStatus.duplicate;
      case 'DISMISSED':
        return AdminReportStatus.dismissed;
      default:
        return AdminReportStatus.unknown;
    }
  }
}

/// EN: Report list filter options.
/// KO: 신고 목록 필터 옵션.
enum AdminReportFilter { all, open, inReview, resolved, rejected }

extension AdminReportFilterX on AdminReportFilter {
  String get label {
    switch (this) {
      case AdminReportFilter.all:
        return '전체';
      case AdminReportFilter.open:
        return '접수됨';
      case AdminReportFilter.inReview:
        return '검토 중';
      case AdminReportFilter.resolved:
        return '완료';
      case AdminReportFilter.rejected:
        return '반려';
    }
  }

  String? get apiStatus {
    switch (this) {
      case AdminReportFilter.all:
        return null;
      case AdminReportFilter.open:
        return AdminReportStatus.open.apiValue;
      case AdminReportFilter.inReview:
        return AdminReportStatus.inReview.apiValue;
      case AdminReportFilter.resolved:
        return AdminReportStatus.resolved.apiValue;
      case AdminReportFilter.rejected:
        return AdminReportStatus.rejected.apiValue;
    }
  }
}

enum AdminProjectRoleRequestFilter { all, pending, approved, rejected }

extension AdminProjectRoleRequestFilterX on AdminProjectRoleRequestFilter {
  String get label {
    switch (this) {
      case AdminProjectRoleRequestFilter.all:
        return '전체';
      case AdminProjectRoleRequestFilter.pending:
        return '대기';
      case AdminProjectRoleRequestFilter.approved:
        return '승인';
      case AdminProjectRoleRequestFilter.rejected:
        return '거절';
    }
  }

  String? get apiStatus {
    switch (this) {
      case AdminProjectRoleRequestFilter.all:
        return null;
      case AdminProjectRoleRequestFilter.pending:
        return 'PENDING';
      case AdminProjectRoleRequestFilter.approved:
        return 'APPROVED';
      case AdminProjectRoleRequestFilter.rejected:
        return 'REJECTED';
    }
  }
}

enum AdminRoleRequestDecision { approve, reject }

extension AdminRoleRequestDecisionX on AdminRoleRequestDecision {
  String get apiValue {
    switch (this) {
      case AdminRoleRequestDecision.approve:
        return 'APPROVE';
      case AdminRoleRequestDecision.reject:
        return 'REJECT';
    }
  }

  String get label {
    switch (this) {
      case AdminRoleRequestDecision.approve:
        return '승인';
      case AdminRoleRequestDecision.reject:
        return '거절';
    }
  }
}

class AdminProjectRoleRequest {
  const AdminProjectRoleRequest({
    required this.id,
    required this.projectId,
    required this.requestedRole,
    required this.status,
    required this.justification,
    required this.createdAt,
    this.projectCode,
    this.projectName,
    this.requesterId,
    this.requesterName,
    this.adminMemo,
    this.reviewedAt,
  });

  final String id;
  final String projectId;
  final String? projectCode;
  final String? projectName;
  final String? requesterId;
  final String? requesterName;
  final String requestedRole;
  final String status;
  final String justification;
  final DateTime createdAt;
  final String? adminMemo;
  final DateTime? reviewedAt;

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

enum AdminMediaDeletionStatus { pending, approved, rejected, unknown }

extension AdminMediaDeletionStatusX on AdminMediaDeletionStatus {
  String get label {
    switch (this) {
      case AdminMediaDeletionStatus.pending:
        return '대기';
      case AdminMediaDeletionStatus.approved:
        return '승인';
      case AdminMediaDeletionStatus.rejected:
        return '반려';
      case AdminMediaDeletionStatus.unknown:
        return '알 수 없음';
    }
  }

  static AdminMediaDeletionStatus fromApiValue(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return AdminMediaDeletionStatus.pending;
      case 'APPROVED':
        return AdminMediaDeletionStatus.approved;
      case 'REJECTED':
        return AdminMediaDeletionStatus.rejected;
      default:
        return AdminMediaDeletionStatus.unknown;
    }
  }
}

class AdminMediaDeletionRequest {
  const AdminMediaDeletionRequest({
    required this.id,
    required this.entityType,
    required this.linkId,
    required this.uploadId,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String linkId;
  final String uploadId;
  final String requestedBy;
  final AdminMediaDeletionStatus status;
  final DateTime createdAt;

  String get entityTypeLabel {
    switch (entityType.toUpperCase()) {
      case 'PLACE':
        return '장소';
      case 'NEWS':
        return '뉴스';
      case 'LIVE':
        return '이벤트';
      default:
        return entityType;
    }
  }
}

/// EN: Dashboard metrics for admin operations.
/// KO: 운영 대시보드 지표.
class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.openReports,
    required this.inReviewReports,
    required this.pendingAccessGrantRequests,
    required this.pendingVerificationAppeals,
    required this.pendingMediaDeletionRequests,
    required this.activeSanctions,
    this.extraMetrics = const <String, int>{},
  });

  final int openReports;
  final int inReviewReports;
  final int pendingAccessGrantRequests;
  final int pendingVerificationAppeals;
  final int pendingMediaDeletionRequests;
  final int activeSanctions;
  final Map<String, int> extraMetrics;

  int get totalPendingItems {
    return openReports +
        inReviewReports +
        pendingAccessGrantRequests +
        pendingVerificationAppeals +
        pendingMediaDeletionRequests;
  }
}

/// EN: Community report entity for admin moderation UI.
/// KO: 운영 신고 관리 UI용 커뮤니티 신고 엔티티.
class AdminCommunityReport {
  const AdminCommunityReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reporterId,
    this.reporterName,
    this.assigneeId,
    this.assigneeName,
    this.description,
    this.previewText,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final AdminReportStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reporterId;
  final String? reporterName;
  final String? assigneeId;
  final String? assigneeName;
  final String? description;
  final String? previewText;

  String get targetLabel {
    switch (targetType.toUpperCase()) {
      case 'POST':
        return '게시글';
      case 'COMMENT':
        return '댓글';
      case 'USER':
        return '사용자';
      default:
        return targetType;
    }
  }
}

/// EN: Returns true when user can access admin operations screens.
/// KO: 사용자에게 운영/관리 화면 접근 권한이 있는지 반환합니다.
bool hasAdminOpsAccess({String? effectiveAccessLevel, String? accountRole}) {
  return canAccessNonSensitiveAdmin(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
}
