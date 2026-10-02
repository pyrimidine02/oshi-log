/// EN: Remote data source for community moderation.
/// KO: 커뮤니티 신고/차단 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/community_moderation_dto.dart';

class CommunityRemoteDataSource {
  CommunityRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Create a community report.
  /// KO: 커뮤니티 신고를 생성합니다.
  Future<Result<void>> createReport({required ReportCreateRequestDto request}) {
    return _apiClient.post<void>(
      ApiEndpoints.communityReports,
      data: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// EN: Get report list for current user.
  /// KO: 현재 사용자 신고 목록을 조회합니다.
  Future<Result<List<ReportSummaryDto>>> getMyReports({
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<ReportSummaryDto>>(
      ApiEndpoints.communityReportsMe,
      queryParameters: {'page': page, 'size': size, 'pageable': '$page,$size'},
      fromJson: (json) {
        final list = json is List ? json : const <dynamic>[];
        return list
            .whereType<Map<String, dynamic>>()
            .map(ReportSummaryDto.fromJson)
            .toList();
      },
    );
  }

  /// EN: Get report detail for current user.
  /// KO: 현재 사용자 신고 상세를 조회합니다.
  Future<Result<ReportDetailDto>> getMyReportDetail({
    required String reportId,
  }) {
    return _apiClient.get<ReportDetailDto>(
      ApiEndpoints.communityReport(reportId),
      fromJson: (json) => ReportDetailDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Cancel an open report created by current user.
  /// KO: 현재 사용자의 접수 중 신고를 취소합니다.
  Future<Result<void>> cancelMyReport({required String reportId}) {
    return _apiClient.delete<void>(
      ApiEndpoints.communityReport(reportId),
      fromJson: (_) {},
    );
  }

  /// EN: Get sanction status for authenticated user.
  /// KO: 로그인 사용자의 제재 상태를 조회합니다.
  Future<Result<UserSanctionStatusDto>> getMySanctionStatus() {
    return _apiClient.get<UserSanctionStatusDto>(
      ApiEndpoints.userMe,
      fromJson: (json) {
        final data = json as Map<String, dynamic>;
        return UserSanctionStatusDto(
          level:
              (data['sanctionLevel'] ??
                      data['sanctionStatus'] ??
                      data['actionableStatus'] ??
                      'NONE')
                  .toString(),
          reason: data['sanctionReason'] as String?,
          expiresAt: data['sanctionExpiresAt'] as String?,
        );
      },
    );
  }

  /// EN: Submit moderation appeal.
  /// KO: 모더레이션 이의제기를 제출합니다.
  Future<Result<void>> submitAppeal({required AppealCreateRequestDto request}) {
    // EN: The current OpenAPI v3 spec does not expose a community appeal endpoint.
    // KO: 현재 OpenAPI v3 스펙에는 커뮤니티 이의제기 엔드포인트가 없습니다.
    return Future.value(
      const Result.failure(
        NotFoundFailure(
          'Community appeal endpoint is not available in current API spec.',
          code: 'community_appeal_unsupported',
        ),
      ),
    );
  }

  /// EN: List project community bans.
  /// KO: 프로젝트 커뮤니티 제재 목록을 조회합니다.
  Future<Result<List<ProjectCommunityBanDto>>> listProjectBans({
    required String projectCode,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<ProjectCommunityBanDto>>(
      ApiEndpoints.moderationBans(projectCode),
      queryParameters: {'page': page, 'size': size, 'pageable': '$page,$size'},
      fromJson: (json) {
        final list = json is List ? json : const <dynamic>[];
        return list
            .whereType<Map<String, dynamic>>()
            .map(ProjectCommunityBanDto.fromJson)
            .toList();
      },
    );
  }

  /// EN: Get project community ban status for a user.
  /// KO: 사용자 프로젝트 커뮤니티 제재 상태를 조회합니다.
  Future<Result<ProjectCommunityBanDto>> getProjectBanStatus({
    required String projectCode,
    required String userId,
  }) {
    return _apiClient.get<ProjectCommunityBanDto>(
      ApiEndpoints.moderationBan(projectCode, userId),
      fromJson: (json) => ProjectCommunityBanDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Ban a user in project community.
  /// KO: 프로젝트 커뮤니티에서 사용자를 제재합니다.
  Future<Result<ProjectCommunityBanDto>> banProjectUser({
    required String projectCode,
    required String userId,
    required ProjectCommunityBanRequestDto request,
  }) {
    return _apiClient.post<ProjectCommunityBanDto>(
      ApiEndpoints.moderationBan(projectCode, userId),
      data: request.toJson(),
      fromJson: (json) => ProjectCommunityBanDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Unban a user in project community.
  /// KO: 프로젝트 커뮤니티 사용자 제재를 해제합니다.
  Future<Result<void>> unbanProjectUser({
    required String projectCode,
    required String userId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.moderationBan(projectCode, userId),
      fromJson: (_) {},
    );
  }

  /// EN: Delete a post via moderator endpoint.
  /// KO: 모더레이터 엔드포인트로 게시글을 삭제합니다.
  Future<Result<void>> moderateDeletePost({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.moderationPost(projectCode, postId),
      fromJson: (_) {},
    );
  }

  /// EN: Delete a comment via moderator endpoint.
  /// KO: 모더레이터 엔드포인트로 댓글을 삭제합니다.
  Future<Result<void>> moderateDeletePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.moderationPostComment(projectCode, postId, commentId),
      fromJson: (_) {},
    );
  }
}
