/// EN: Community moderation repository implementation.
/// KO: 커뮤니티 신고/차단 리포지토리 구현.
library;

import '../../../../../platform/error/error_handler.dart';
import '../../../../../platform/error/failure.dart';
import '../../../../../platform/utils/result.dart';
import '../../domain/entities/community_moderation.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_data_source.dart';
import '../dto/community_moderation_dto.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl({required CommunityRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final CommunityRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> createReport({
    required CommunityReportTargetType targetType,
    required String targetId,
    required CommunityReportReason reason,
    String? description,
  }) async {
    try {
      final request = ReportCreateRequestDto(
        targetType: targetType.apiValue,
        targetId: targetId,
        reason: reason.requestApiValue,
        description: reason.buildRequestDescription(description),
      );
      final result = await _remoteDataSource.createReport(request: request);

      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown report create result',
          code: 'unknown_report_create',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<UserSanctionStatus>> getMySanctionStatus() async {
    try {
      final result = await _remoteDataSource.getMySanctionStatus();
      if (result is Success<UserSanctionStatusDto>) {
        final dto = result.data;
        return Result.success(
          UserSanctionStatus(
            level: UserSanctionLevelX.fromApiValue(dto.level),
            reason: dto.reason,
            expiresAt: dto.expiresAt == null
                ? null
                : DateTime.tryParse(dto.expiresAt!),
          ),
        );
      }
      if (result is Err<UserSanctionStatusDto>) {
        if (_shouldFallbackToNoSanction(result.failure)) {
          return _noSanction();
        }
        return Result.failure(result.failure);
      }

      return _noSanction();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      if (_shouldFallbackToNoSanction(failure)) {
        return _noSanction();
      }
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> submitAppeal({
    required CommunityReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    try {
      final request = AppealCreateRequestDto(
        targetType: targetType.apiValue,
        targetId: targetId,
        reason: reason,
      );
      final result = await _remoteDataSource.submitAppeal(request: request);
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown submit appeal result',
          code: 'unknown_submit_appeal',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<CommunityReportSummary>>> getMyReports({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.getMyReports(
        page: page,
        size: size,
      );
      if (result is Success<List<ReportSummaryDto>>) {
        final entities = result.data.map(_toReportSummary).toList();
        return Result.success(entities);
      }
      if (result is Err<List<ReportSummaryDto>>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown my reports result',
          code: 'unknown_my_reports',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<CommunityReportDetail>> getMyReportDetail({
    required String reportId,
  }) async {
    try {
      final result = await _remoteDataSource.getMyReportDetail(
        reportId: reportId,
      );
      if (result is Success<ReportDetailDto>) {
        return Result.success(_toReportDetail(result.data));
      }
      if (result is Err<ReportDetailDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown my report detail result',
          code: 'unknown_my_report_detail',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> cancelMyReport({required String reportId}) async {
    try {
      final result = await _remoteDataSource.cancelMyReport(reportId: reportId);
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown cancel report result',
          code: 'unknown_cancel_report',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<ProjectCommunityBan>>> listProjectBans({
    required String projectCode,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.listProjectBans(
        projectCode: projectCode,
        page: page,
        size: size,
      );
      if (result is Success<List<ProjectCommunityBanDto>>) {
        return Result.success(result.data.map(_toProjectBan).toList());
      }
      if (result is Err<List<ProjectCommunityBanDto>>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown project bans result',
          code: 'unknown_project_bans',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<ProjectCommunityBan>> getProjectBanStatus({
    required String projectCode,
    required String userId,
  }) async {
    try {
      final result = await _remoteDataSource.getProjectBanStatus(
        projectCode: projectCode,
        userId: userId,
      );
      if (result is Success<ProjectCommunityBanDto>) {
        return Result.success(_toProjectBan(result.data));
      }
      if (result is Err<ProjectCommunityBanDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown project ban status result',
          code: 'unknown_project_ban_status',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<ProjectCommunityBan>> banProjectUser({
    required String projectCode,
    required String userId,
    String? reason,
    DateTime? expiresAt,
  }) async {
    try {
      final result = await _remoteDataSource.banProjectUser(
        projectCode: projectCode,
        userId: userId,
        request: ProjectCommunityBanRequestDto(
          reason: reason,
          expiresAt: expiresAt,
        ),
      );
      if (result is Success<ProjectCommunityBanDto>) {
        return Result.success(_toProjectBan(result.data));
      }
      if (result is Err<ProjectCommunityBanDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown project ban user result',
          code: 'unknown_project_ban_user',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> unbanProjectUser({
    required String projectCode,
    required String userId,
  }) async {
    try {
      final result = await _remoteDataSource.unbanProjectUser(
        projectCode: projectCode,
        userId: userId,
      );
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown project unban user result',
          code: 'unknown_project_unban_user',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> moderateDeletePost({
    required String projectCode,
    required String postId,
  }) async {
    try {
      final result = await _remoteDataSource.moderateDeletePost(
        projectCode: projectCode,
        postId: postId,
      );
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown moderation post delete result',
          code: 'unknown_moderation_post_delete',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> moderateDeletePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
  }) async {
    try {
      final result = await _remoteDataSource.moderateDeletePostComment(
        projectCode: projectCode,
        postId: postId,
        commentId: commentId,
      );
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown moderation post comment delete result',
          code: 'unknown_moderation_post_comment_delete',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Result<UserSanctionStatus> _noSanction() {
    return const Result.success(
      UserSanctionStatus(level: UserSanctionLevel.none),
    );
  }

  bool _shouldFallbackToNoSanction(Failure failure) {
    return failure is NotFoundFailure || failure is NetworkFailure;
  }

  CommunityReportSummary _toReportSummary(ReportSummaryDto dto) {
    return CommunityReportSummary(
      id: dto.id,
      targetType: CommunityReportTargetTypeX.fromApiValue(dto.targetType),
      targetId: dto.targetId,
      reason: CommunityReportReasonX.fromApiValue(dto.reason),
      status: CommunityReportStatusX.fromApiValue(dto.status),
      priority: CommunityReportPriorityX.fromApiValue(dto.priority),
      createdAt: dto.createdAt,
    );
  }

  CommunityReportDetail _toReportDetail(ReportDetailDto dto) {
    return CommunityReportDetail(
      id: dto.id,
      targetType: CommunityReportTargetTypeX.fromApiValue(dto.targetType),
      targetId: dto.targetId,
      reason: CommunityReportReasonX.fromApiValue(dto.reason),
      status: CommunityReportStatusX.fromApiValue(dto.status),
      priority: CommunityReportPriorityX.fromApiValue(dto.priority),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      description: dto.description,
      adminAction: dto.adminAction == null
          ? null
          : CommunityAdminActionX.fromApiValue(dto.adminAction),
      resolvedAt: dto.resolvedAt,
    );
  }

  ProjectCommunityBan _toProjectBan(ProjectCommunityBanDto dto) {
    return ProjectCommunityBan(
      id: dto.id,
      projectId: dto.projectId,
      bannedUserId: dto.bannedUserId,
      moderatorUserId: dto.moderatorUserId,
      createdAt: dto.createdAt,
      bannedUserDisplayName: dto.bannedUserDisplayName,
      bannedUserEmail: dto.bannedUserEmail,
      bannedUserAvatarUrl: dto.bannedUserAvatarUrl,
      reason: dto.reason,
      expiresAt: dto.expiresAt,
    );
  }
}
