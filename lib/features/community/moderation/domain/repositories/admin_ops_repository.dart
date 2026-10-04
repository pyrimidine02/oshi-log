/// EN: Admin operations repository interface.
/// KO: 운영/관리자 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/community/moderation/domain/entities/admin_ops_entities.dart';

abstract class AdminOpsRepository {
  /// EN: Fetches admin dashboard summary metrics.
  /// KO: 관리자 대시보드 요약 지표를 조회합니다.
  Future<Result<AdminDashboardSummary>> getDashboard({
    bool forceRefresh = false,
  });

  /// EN: Fetches community reports for moderation.
  /// KO: 모더레이션용 커뮤니티 신고 목록을 조회합니다.
  Future<Result<List<AdminCommunityReport>>> getCommunityReports({
    String? status,
    int page = 0,
    int size = 30,
    bool forceRefresh = false,
  });

  /// EN: Fetches a single community report detail.
  /// KO: 단일 커뮤니티 신고 상세를 조회합니다.
  Future<Result<AdminCommunityReport>> getCommunityReportDetail({
    required String reportId,
    bool forceRefresh = false,
  });

  /// EN: Assigns a report to a specific admin user.
  /// KO: 신고를 특정 운영자에게 할당합니다.
  Future<Result<void>> assignCommunityReport({
    required String reportId,
    required String assigneeUserId,
  });

  /// EN: Updates moderation status for a report.
  /// KO: 신고 처리 상태를 업데이트합니다.
  Future<Result<void>> updateCommunityReportStatus({
    required String reportId,
    required AdminReportStatus status,
    String? note,
  });

  Future<Result<List<AdminProjectRoleRequest>>> getProjectRoleRequests({
    String? status,
    int page = 0,
    int size = 30,
    bool forceRefresh = false,
  });

  Future<Result<void>> reviewProjectRoleRequest({
    required String requestId,
    required AdminRoleRequestDecision decision,
    String? adminMemo,
  });

  Future<Result<void>> grantProjectRole({
    required String projectId,
    required String userId,
    required String role,
    String? reason,
  });

  Future<Result<void>> revokeProjectRole({
    required String projectId,
    required String userId,
    required String role,
    String? reason,
  });

  Future<Result<void>> grantUserAccess({
    required String userId,
    required String accessLevel,
    String? expiresAt,
    String? reason,
  });

  Future<Result<void>> revokeUserAccessGrant({
    required String userId,
    required String grantId,
    String? reason,
  });

  Future<Result<List<AdminMediaDeletionRequest>>> getMediaDeletionRequests({
    String status = 'PENDING',
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  Future<Result<void>> approveMediaDeletion({
    required String requestId,
    required bool deleteLinkedContents,
  });

  Future<Result<void>> rejectMediaDeletion({required String requestId});
}
