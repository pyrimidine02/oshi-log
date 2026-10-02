/// EN: Controllers for admin operations pages.
/// KO: 운영/관리자 페이지 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/identity/account/application/settings_controller.dart';
import 'package:oshi_log/features/community/moderation/data/datasources/admin_ops_remote_data_source.dart';
import 'package:oshi_log/features/community/moderation/data/repositories/admin_ops_repository_impl.dart';
import 'package:oshi_log/features/community/moderation/domain/entities/admin_ops_entities.dart';
import 'package:oshi_log/features/community/moderation/domain/repositories/admin_ops_repository.dart';

/// EN: Admin operations repository provider.
/// KO: 운영/관리자 리포지토리 프로바이더.
final adminOpsRepositoryProvider = FutureProvider<AdminOpsRepository>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return AdminOpsRepositoryImpl(
    remoteDataSource: AdminOpsRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});

/// EN: Dashboard controller for admin metrics.
/// KO: 관리자 지표 대시보드 컨트롤러.
class AdminDashboardController
    extends StateNotifier<AsyncValue<AdminDashboardSummary>> {
  AdminDashboardController(this._ref) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;

  Future<void> load({bool forceRefresh = false}) async {
    if (!_canAccessAdminOps(_ref)) {
      state = AsyncError(
        const AuthFailure('Admin access required', code: '403'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.getDashboard(forceRefresh: forceRefresh);

    if (result is Success<AdminDashboardSummary>) {
      state = AsyncData(result.data);
      return;
    }
    if (result is Err<AdminDashboardSummary>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

class AdminReportsState {
  const AdminReportsState({
    required this.filter,
    required this.reports,
    this.isMutating = false,
  });

  factory AdminReportsState.initial() {
    return const AdminReportsState(
      filter: AdminReportFilter.all,
      reports: AsyncLoading(),
      isMutating: false,
    );
  }

  final AdminReportFilter filter;
  final AsyncValue<List<AdminCommunityReport>> reports;
  final bool isMutating;

  AdminReportsState copyWith({
    AdminReportFilter? filter,
    AsyncValue<List<AdminCommunityReport>>? reports,
    bool? isMutating,
  }) {
    return AdminReportsState(
      filter: filter ?? this.filter,
      reports: reports ?? this.reports,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

/// EN: Community report list + actions controller.
/// KO: 커뮤니티 신고 목록/액션 컨트롤러.
class AdminReportsController extends StateNotifier<AdminReportsState> {
  AdminReportsController(this._ref) : super(AdminReportsState.initial()) {
    load();
  }

  final Ref _ref;

  Future<void> load({
    bool forceRefresh = false,
    AdminReportFilter? filter,
  }) async {
    if (!_canAccessAdminOps(_ref)) {
      state = state.copyWith(
        filter: filter ?? state.filter,
        reports: AsyncError(
          const AuthFailure('Admin access required', code: '403'),
          StackTrace.current,
        ),
      );
      return;
    }
    final nextFilter = filter ?? state.filter;
    state = state.copyWith(filter: nextFilter, reports: const AsyncLoading());

    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.getCommunityReports(
      status: nextFilter.apiStatus,
      page: 0,
      size: 50,
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<AdminCommunityReport>>) {
      state = state.copyWith(reports: AsyncData(result.data));
      return;
    }

    if (result is Err<List<AdminCommunityReport>>) {
      state = state.copyWith(
        reports: AsyncError(result.failure, StackTrace.current),
      );
    }
  }

  Future<Result<void>> assignToUser({
    required String reportId,
    required String assigneeUserId,
  }) async {
    state = state.copyWith(isMutating: true);
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.assignCommunityReport(
      reportId: reportId,
      assigneeUserId: assigneeUserId,
    );
    state = state.copyWith(isMutating: false);

    if (result is Success<void>) {
      await load(forceRefresh: true);
      return const Result.success(null);
    }
    if (result is Err<void>) {
      return Result.failure(result.failure);
    }

    return const Result.success(null);
  }

  Future<Result<void>> updateStatus({
    required String reportId,
    required AdminReportStatus status,
    String? note,
  }) async {
    state = state.copyWith(isMutating: true);
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.updateCommunityReportStatus(
      reportId: reportId,
      status: status,
      note: note,
    );
    state = state.copyWith(isMutating: false);

    if (result is Success<void>) {
      await load(forceRefresh: true);
      return const Result.success(null);
    }
    if (result is Err<void>) {
      return Result.failure(result.failure);
    }

    return const Result.success(null);
  }
}

class AdminRoleRequestsState {
  const AdminRoleRequestsState({
    required this.filter,
    required this.requests,
    this.isMutating = false,
  });

  factory AdminRoleRequestsState.initial() {
    return const AdminRoleRequestsState(
      filter: AdminProjectRoleRequestFilter.pending,
      requests: AsyncLoading(),
      isMutating: false,
    );
  }

  final AdminProjectRoleRequestFilter filter;
  final AsyncValue<List<AdminProjectRoleRequest>> requests;
  final bool isMutating;

  AdminRoleRequestsState copyWith({
    AdminProjectRoleRequestFilter? filter,
    AsyncValue<List<AdminProjectRoleRequest>>? requests,
    bool? isMutating,
  }) {
    return AdminRoleRequestsState(
      filter: filter ?? this.filter,
      requests: requests ?? this.requests,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class AdminRoleRequestsController
    extends StateNotifier<AdminRoleRequestsState> {
  AdminRoleRequestsController(this._ref)
    : super(AdminRoleRequestsState.initial()) {
    load();
  }

  final Ref _ref;

  Future<void> load({
    bool forceRefresh = false,
    AdminProjectRoleRequestFilter? filter,
  }) async {
    if (!_canAccessAdminOps(_ref)) {
      state = state.copyWith(
        filter: filter ?? state.filter,
        requests: AsyncError(
          const AuthFailure('Admin access required', code: '403'),
          StackTrace.current,
        ),
      );
      return;
    }
    final nextFilter = filter ?? state.filter;
    state = state.copyWith(filter: nextFilter, requests: const AsyncLoading());

    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.getProjectRoleRequests(
      status: nextFilter.apiStatus,
      page: 0,
      size: 50,
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<AdminProjectRoleRequest>>) {
      state = state.copyWith(requests: AsyncData(result.data));
      return;
    }
    if (result is Err<List<AdminProjectRoleRequest>>) {
      state = state.copyWith(
        requests: AsyncError(result.failure, StackTrace.current),
      );
    }
  }

  Future<Result<void>> review({
    required String requestId,
    required AdminRoleRequestDecision decision,
    String? adminMemo,
  }) async {
    state = state.copyWith(isMutating: true);
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.reviewProjectRoleRequest(
      requestId: requestId,
      decision: decision,
      adminMemo: adminMemo,
    );
    state = state.copyWith(isMutating: false);

    if (result is Success<void>) {
      await load(forceRefresh: true);
      return const Result.success(null);
    }
    if (result is Err<void>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }
}

class AdminMediaDeletionsState {
  const AdminMediaDeletionsState({
    required this.requests,
    this.isMutating = false,
  });

  factory AdminMediaDeletionsState.initial() {
    return const AdminMediaDeletionsState(requests: AsyncLoading());
  }

  final AsyncValue<List<AdminMediaDeletionRequest>> requests;
  final bool isMutating;

  AdminMediaDeletionsState copyWith({
    AsyncValue<List<AdminMediaDeletionRequest>>? requests,
    bool? isMutating,
  }) {
    return AdminMediaDeletionsState(
      requests: requests ?? this.requests,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class AdminMediaDeletionsController
    extends StateNotifier<AdminMediaDeletionsState> {
  AdminMediaDeletionsController(this._ref)
    : super(AdminMediaDeletionsState.initial()) {
    load();
  }

  final Ref _ref;

  Future<void> load({bool forceRefresh = false}) async {
    if (!_canAccessAdminOps(_ref)) {
      state = state.copyWith(
        requests: AsyncError(
          const AuthFailure('Admin access required', code: '403'),
          StackTrace.current,
        ),
      );
      return;
    }
    state = state.copyWith(requests: const AsyncLoading());
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.getMediaDeletionRequests(
      status: 'PENDING',
      page: 0,
      size: 50,
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<AdminMediaDeletionRequest>>) {
      state = state.copyWith(requests: AsyncData(result.data));
      return;
    }
    if (result is Err<List<AdminMediaDeletionRequest>>) {
      state = state.copyWith(
        requests: AsyncError(result.failure, StackTrace.current),
      );
    }
  }

  Future<Result<void>> approve({
    required String requestId,
    required bool deleteLinkedContents,
  }) async {
    state = state.copyWith(isMutating: true);
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.approveMediaDeletion(
      requestId: requestId,
      deleteLinkedContents: deleteLinkedContents,
    );
    state = state.copyWith(isMutating: false);

    if (result is Success<void>) {
      await load(forceRefresh: true);
      return const Result.success(null);
    }
    if (result is Err<void>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }

  Future<Result<void>> reject({required String requestId}) async {
    state = state.copyWith(isMutating: true);
    final repository = await _ref.read(adminOpsRepositoryProvider.future);
    final result = await repository.rejectMediaDeletion(requestId: requestId);
    state = state.copyWith(isMutating: false);

    if (result is Success<void>) {
      await load(forceRefresh: true);
      return const Result.success(null);
    }
    if (result is Err<void>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }
}

/// EN: Dashboard controller provider.
/// KO: 운영 대시보드 컨트롤러 프로바이더.
final adminDashboardControllerProvider =
    StateNotifierProvider<
      AdminDashboardController,
      AsyncValue<AdminDashboardSummary>
    >((ref) {
      return AdminDashboardController(ref);
    });

/// EN: Reports controller provider.
/// KO: 운영 신고 목록 컨트롤러 프로바이더.
final adminReportsControllerProvider =
    StateNotifierProvider<AdminReportsController, AdminReportsState>((ref) {
      return AdminReportsController(ref);
    });

final adminRoleRequestsControllerProvider =
    StateNotifierProvider<AdminRoleRequestsController, AdminRoleRequestsState>((
      ref,
    ) {
      return AdminRoleRequestsController(ref);
    });

final adminMediaDeletionsControllerProvider =
    StateNotifierProvider<
      AdminMediaDeletionsController,
      AdminMediaDeletionsState
    >((ref) {
      return AdminMediaDeletionsController(ref);
    });

/// EN: Report detail provider.
/// KO: 신고 상세 프로바이더.
final adminReportDetailProvider = FutureProvider.autoDispose
    .family<AdminCommunityReport?, String>((ref, reportId) async {
      if (reportId.isEmpty) {
        return null;
      }

      final repository = await ref.read(adminOpsRepositoryProvider.future);
      final result = await repository.getCommunityReportDetail(
        reportId: reportId,
      );
      if (result is Success<AdminCommunityReport>) {
        return result.data;
      }
      return null;
    });

bool _canAccessAdminOps(Ref ref) {
  final profile = ref.read(userProfileControllerProvider).valueOrNull;
  return hasAdminOpsAccess(
    effectiveAccessLevel: profile?.effectiveAccessLevel,
    accountRole: profile?.accountRole,
  );
}
