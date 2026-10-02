/// EN: Community moderation repository interface.
/// KO: 커뮤니티 신고/차단 리포지토리 인터페이스.
library;

import '../../../../../core/utils/result.dart';
import '../entities/community_moderation.dart';

abstract class CommunityRepository {
  /// EN: Create a report.
  /// KO: 신고를 생성합니다.
  Future<Result<void>> createReport({
    required CommunityReportTargetType targetType,
    required String targetId,
    required CommunityReportReason reason,
    String? description,
  });

  /// EN: Get sanction status for the authenticated user.
  /// KO: 로그인 사용자의 제재 상태를 조회합니다.
  Future<Result<UserSanctionStatus>> getMySanctionStatus();

  /// EN: Submit moderation appeal.
  /// KO: 모더레이션 이의제기를 제출합니다.
  Future<Result<void>> submitAppeal({
    required CommunityReportTargetType targetType,
    required String targetId,
    required String reason,
  });

  /// EN: Get reports created by the current user.
  /// KO: 현재 사용자가 생성한 신고 목록을 조회합니다.
  Future<Result<List<CommunityReportSummary>>> getMyReports({
    int page = 0,
    int size = 20,
  });

  /// EN: Get current user's report detail.
  /// KO: 현재 사용자의 신고 상세를 조회합니다.
  Future<Result<CommunityReportDetail>> getMyReportDetail({
    required String reportId,
  });

  /// EN: Cancel current user's open report.
  /// KO: 현재 사용자의 접수 중 신고를 취소합니다.
  Future<Result<void>> cancelMyReport({required String reportId});

  /// EN: List moderation bans in a project community.
  /// KO: 프로젝트 커뮤니티의 제재(밴) 목록을 조회합니다.
  Future<Result<List<ProjectCommunityBan>>> listProjectBans({
    required String projectCode,
    int page = 0,
    int size = 20,
  });

  /// EN: Get ban status of a user in project community.
  /// KO: 프로젝트 커뮤니티에서 특정 사용자 제재 상태를 조회합니다.
  Future<Result<ProjectCommunityBan>> getProjectBanStatus({
    required String projectCode,
    required String userId,
  });

  /// EN: Ban a user in a project community.
  /// KO: 프로젝트 커뮤니티에서 사용자를 제재합니다.
  Future<Result<ProjectCommunityBan>> banProjectUser({
    required String projectCode,
    required String userId,
    String? reason,
    DateTime? expiresAt,
  });

  /// EN: Unban a user in a project community.
  /// KO: 프로젝트 커뮤니티에서 사용자 제재를 해제합니다.
  Future<Result<void>> unbanProjectUser({
    required String projectCode,
    required String userId,
  });

  /// EN: Remove a post by moderator action.
  /// KO: 모더레이터 권한으로 게시글을 삭제합니다.
  Future<Result<void>> moderateDeletePost({
    required String projectCode,
    required String postId,
  });

  /// EN: Remove a post comment by moderator action.
  /// KO: 모더레이터 권한으로 댓글을 삭제합니다.
  Future<Result<void>> moderateDeletePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
  });
}
