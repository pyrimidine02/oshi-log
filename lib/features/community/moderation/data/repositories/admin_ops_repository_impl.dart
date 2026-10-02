/// EN: Admin operations repository implementation.
/// KO: 운영/관리자 리포지토리 구현.
library;

import 'package:oshi_log/core/cache/cache_manager.dart';
import 'package:oshi_log/core/cache/cache_profiles.dart';
import 'package:oshi_log/core/error/error_handler.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/community/moderation/domain/entities/admin_ops_entities.dart';
import 'package:oshi_log/features/community/moderation/domain/repositories/admin_ops_repository.dart';
import 'package:oshi_log/features/community/moderation/data/datasources/admin_ops_remote_data_source.dart';
import 'package:oshi_log/features/community/moderation/data/dto/admin_ops_dto.dart';

class AdminOpsRepositoryImpl implements AdminOpsRepository {
  AdminOpsRepositoryImpl({
    required AdminOpsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final AdminOpsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<AdminDashboardSummary>> getDashboard({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.adminDashboard;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<AdminDashboardDto>(
        key: 'admin_dashboard_summary',
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchDashboardWithFallback,
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => AdminDashboardDto.fromJson(json),
      );

      return Result.success(_toDashboardEntity(cacheResult.data));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<AdminCommunityReport>>> getCommunityReports({
    String? status,
    int page = 0,
    int size = 30,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.adminCommunityReports;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    final cacheKey = 'admin_reports:${status ?? 'ALL'}:$page:$size';

    try {
      final cacheResult = await _cacheManager
          .resolve<List<AdminCommunityReportDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () =>
                _fetchCommunityReports(status: status, page: page, size: size),
            toJson: (dtos) => {
              'items': dtos.map((dto) => dto.toJson()).toList(growable: false),
            },
            fromJson: (json) {
              final raw = json['items'];
              return AdminCommunityReportDto.listFromAny(raw);
            },
          );

      return Result.success(
        cacheResult.data.map(_toReportEntity).toList(growable: false),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<AdminCommunityReport>> getCommunityReportDetail({
    required String reportId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.adminCommunityReportDetail;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<AdminCommunityReportDto>(
        key: 'admin_report_detail:$reportId',
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchCommunityReportDetail(reportId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => AdminCommunityReportDto.fromJson(json),
      );

      return Result.success(_toReportEntity(cacheResult.data));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> assignCommunityReport({
    required String reportId,
    required String assigneeUserId,
  }) async {
    try {
      final result = await _remoteDataSource.assignCommunityReport(
        reportId: reportId,
        assigneeUserId: assigneeUserId,
      );

      if (result is Success<void>) {
        await _cacheManager.remove('admin_report_detail:$reportId');
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown assign report result',
          code: 'unknown_assign_report_result',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> updateCommunityReportStatus({
    required String reportId,
    required AdminReportStatus status,
    String? note,
  }) async {
    try {
      final result = await _remoteDataSource.updateCommunityReportStatus(
        reportId: reportId,
        status: status.apiValue,
        note: note,
      );

      if (result is Success<void>) {
        await _cacheManager.remove('admin_report_detail:$reportId');
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown update report status result',
          code: 'unknown_update_report_status_result',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<AdminProjectRoleRequest>>> getProjectRoleRequests({
    String? status,
    int page = 0,
    int size = 30,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.adminProjectRoleRequests;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    final cacheKey =
        'admin_project_role_requests:${status ?? 'ALL'}:$page:$size';

    try {
      final cacheResult = await _cacheManager
          .resolve<List<AdminProjectRoleRequestDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchProjectRoleRequests(
              status: status,
              page: page,
              size: size,
            ),
            toJson: (dtos) => {
              'items': dtos.map((dto) => dto.toJson()).toList(growable: false),
            },
            fromJson: (json) {
              final raw = json['items'];
              return AdminProjectRoleRequestDto.listFromAny(raw);
            },
          );

      return Result.success(
        cacheResult.data.map(_toRoleRequestEntity).toList(growable: false),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> reviewProjectRoleRequest({
    required String requestId,
    required AdminRoleRequestDecision decision,
    String? adminMemo,
  }) async {
    try {
      final result = await _remoteDataSource.reviewProjectRoleRequest(
        requestId: requestId,
        decision: decision.apiValue,
        adminMemo: adminMemo,
      );

      if (result is Success<void>) {
        await _cacheManager.removeByPrefix('admin_project_role_requests:');
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown role request review result',
          code: 'unknown_role_request_review_result',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> grantProjectRole({
    required String projectId,
    required String userId,
    required String role,
    String? reason,
  }) async {
    try {
      final result = await _remoteDataSource.grantProjectRole(
        projectId: projectId,
        userId: userId,
        role: role,
        reason: reason,
      );
      if (result is Success<void>) {
        await _cacheManager.removeByPrefix('admin_project_role_requests:');
      }
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> revokeProjectRole({
    required String projectId,
    required String userId,
    required String role,
    String? reason,
  }) async {
    try {
      final result = await _remoteDataSource.revokeProjectRole(
        projectId: projectId,
        userId: userId,
        role: role,
        reason: reason,
      );
      if (result is Success<void>) {
        await _cacheManager.removeByPrefix('admin_project_role_requests:');
      }
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> grantUserAccess({
    required String userId,
    required String accessLevel,
    String? expiresAt,
    String? reason,
  }) async {
    try {
      return await _remoteDataSource.grantUserAccess(
        userId: userId,
        accessLevel: accessLevel,
        expiresAt: expiresAt,
        reason: reason,
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> revokeUserAccessGrant({
    required String userId,
    required String grantId,
    String? reason,
  }) async {
    try {
      return await _remoteDataSource.revokeUserAccessGrant(
        userId: userId,
        grantId: grantId,
        reason: reason,
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<AdminMediaDeletionRequest>>> getMediaDeletionRequests({
    String status = 'PENDING',
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final dtos = await _fetchMediaDeletionRequests(
        status: status,
        page: page,
        size: size,
      );
      return Result.success(
        dtos.map(_toMediaDeletionEntity).toList(growable: false),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> approveMediaDeletion({
    required String requestId,
    required bool deleteLinkedContents,
  }) async {
    try {
      final result = await _remoteDataSource.approveMediaDeletion(
        requestId: requestId,
        deleteLinkedContents: deleteLinkedContents,
      );
      if (result is Success<AdminMediaDeletionActionResponseDto>) {
        if (!result.data.success) {
          return const Result.failure(
            UnknownFailure(
              'Failed to approve media deletion request',
              code: 'admin_media_deletion_approve_failed',
            ),
          );
        }
        await _cacheManager.remove('admin_dashboard_summary');
        return const Result.success(null);
      }
      if (result is Err<AdminMediaDeletionActionResponseDto>) {
        return Result.failure(result.failure);
      }
      return const Result.failure(
        UnknownFailure(
          'Unknown media deletion approve result',
          code: 'unknown_admin_media_deletion_approve_result',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> rejectMediaDeletion({required String requestId}) async {
    try {
      final result = await _remoteDataSource.rejectMediaDeletion(
        requestId: requestId,
      );
      if (result is Success<AdminMediaDeletionActionResponseDto>) {
        if (!result.data.success) {
          return const Result.failure(
            UnknownFailure(
              'Failed to reject media deletion request',
              code: 'admin_media_deletion_reject_failed',
            ),
          );
        }
        await _cacheManager.remove('admin_dashboard_summary');
        return const Result.success(null);
      }
      if (result is Err<AdminMediaDeletionActionResponseDto>) {
        return Result.failure(result.failure);
      }
      return const Result.failure(
        UnknownFailure(
          'Unknown media deletion reject result',
          code: 'unknown_admin_media_deletion_reject_result',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<AdminDashboardDto> _fetchDashboardWithFallback() async {
    final dashboardResult = await _remoteDataSource.fetchDashboard();
    if (dashboardResult is Success<AdminDashboardDto>) {
      return dashboardResult.data;
    }

    if (dashboardResult is Err<AdminDashboardDto>) {
      final fallbackResult = await _remoteDataSource.fetchModerationDashboard();
      if (fallbackResult is Success<AdminDashboardDto>) {
        return fallbackResult.data;
      }

      if (dashboardResult.failure is NotFoundFailure &&
          fallbackResult is Err<AdminDashboardDto>) {
        throw fallbackResult.failure;
      }
      throw dashboardResult.failure;
    }

    throw const UnknownFailure(
      'Unknown dashboard fetch result',
      code: 'unknown_admin_dashboard_result',
    );
  }

  Future<List<AdminCommunityReportDto>> _fetchCommunityReports({
    String? status,
    int page = 0,
    int size = 30,
  }) async {
    final result = await _remoteDataSource.fetchCommunityReports(
      status: status,
      page: page,
      size: size,
    );

    if (result is Success<List<AdminCommunityReportDto>>) {
      return result.data;
    }
    if (result is Err<List<AdminCommunityReportDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown report list result',
      code: 'unknown_admin_report_list_result',
    );
  }

  Future<AdminCommunityReportDto> _fetchCommunityReportDetail(
    String reportId,
  ) async {
    final result = await _remoteDataSource.fetchCommunityReportDetail(
      reportId: reportId,
    );

    if (result is Success<AdminCommunityReportDto>) {
      return result.data;
    }
    if (result is Err<AdminCommunityReportDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown report detail result',
      code: 'unknown_admin_report_detail_result',
    );
  }

  Future<List<AdminProjectRoleRequestDto>> _fetchProjectRoleRequests({
    String? status,
    int page = 0,
    int size = 30,
  }) async {
    final result = await _remoteDataSource.fetchProjectRoleRequests(
      status: status,
      page: page,
      size: size,
    );

    if (result is Success<List<AdminProjectRoleRequestDto>>) {
      return result.data;
    }
    if (result is Err<List<AdminProjectRoleRequestDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown project role requests result',
      code: 'unknown_admin_project_role_requests_result',
    );
  }

  Future<List<AdminMediaDeletionRequestDto>> _fetchMediaDeletionRequests({
    String status = 'PENDING',
    int page = 0,
    int size = 20,
  }) async {
    final result = await _remoteDataSource.fetchMediaDeletionRequests(
      status: status,
      page: page,
      size: size,
    );

    if (result is Success<List<AdminMediaDeletionRequestDto>>) {
      return result.data;
    }
    if (result is Err<List<AdminMediaDeletionRequestDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown media deletion request list result',
      code: 'unknown_admin_media_deletion_requests_result',
    );
  }

  AdminDashboardSummary _toDashboardEntity(AdminDashboardDto dto) {
    return AdminDashboardSummary(
      openReports: dto.openReports,
      inReviewReports: dto.inReviewReports,
      pendingAccessGrantRequests: dto.pendingAccessGrantRequests,
      pendingVerificationAppeals: dto.pendingVerificationAppeals,
      pendingMediaDeletionRequests: dto.pendingMediaDeletionRequests,
      activeSanctions: dto.activeSanctions,
      extraMetrics: dto.extraMetrics,
    );
  }

  AdminCommunityReport _toReportEntity(AdminCommunityReportDto dto) {
    return AdminCommunityReport(
      id: dto.id,
      targetType: dto.targetType,
      targetId: dto.targetId,
      reason: dto.reason,
      status: AdminReportStatusX.fromApiValue(dto.status),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      reporterId: dto.reporterId,
      reporterName: dto.reporterName,
      assigneeId: dto.assigneeId,
      assigneeName: dto.assigneeName,
      description: dto.description,
      previewText: dto.previewText,
    );
  }

  AdminProjectRoleRequest _toRoleRequestEntity(AdminProjectRoleRequestDto dto) {
    return AdminProjectRoleRequest(
      id: dto.id,
      projectId: dto.projectId,
      projectCode: dto.projectCode,
      projectName: dto.projectName,
      requesterId: dto.requesterId,
      requesterName: dto.requesterName,
      requestedRole: dto.requestedRole,
      status: dto.status,
      justification: dto.justification,
      createdAt: dto.createdAt,
      adminMemo: dto.adminMemo,
      reviewedAt: dto.reviewedAt,
    );
  }

  AdminMediaDeletionRequest _toMediaDeletionEntity(
    AdminMediaDeletionRequestDto dto,
  ) {
    return AdminMediaDeletionRequest(
      id: dto.id,
      entityType: dto.entityType,
      linkId: dto.linkId,
      uploadId: dto.uploadId,
      requestedBy: dto.requestedBy,
      status: AdminMediaDeletionStatusX.fromApiValue(dto.status),
      createdAt: dto.createdAt,
    );
  }
}
