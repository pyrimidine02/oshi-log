/// EN: Riverpod boundaries for project-scoped travel reviews.
/// KO: 프로젝트 범위 여행 후기를 위한 Riverpod 경계입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../../live_events/domain/entities/live_event_entities.dart';
import '../../visits/domain/entities/visit_entities.dart';
import '../data/datasources/travel_reviews_remote_data_source.dart';
import '../data/repositories/travel_reviews_repository_impl.dart';
import '../domain/entities/travel_review.dart';
import '../domain/repositories/travel_reviews_repository.dart';

/// EN: Returns a server-owned attendance proof only for a verified record that
///     belongs to the selected live event. Missing IDs fail closed.
/// KO: 선택한 라이브와 일치하고 서버 ID가 있는 검증 완료 참석 기록만 증빙으로
///     반환합니다. ID가 없으면 실패-폐쇄로 연결하지 않습니다.
String? verifiedAttendanceProofId(
  Iterable<LiveAttendanceHistoryRecord> records,
  String eventId,
) {
  final normalizedEventId = eventId.trim();
  if (normalizedEventId.isEmpty) return null;

  for (final record in records) {
    final attendanceId = record.attendanceId?.trim();
    if (record.eventId.trim() == normalizedEventId &&
        record.isVerified &&
        attendanceId != null &&
        attendanceId.isNotEmpty) {
      return attendanceId;
    }
  }
  return null;
}

/// EN: Returns the newest server-verified visit for the selected place.
///     Distance is presentation metadata and never proof of verification.
/// KO: 선택한 장소의 최신 서버 인증 방문 ID를 반환합니다. 거리는 표시용
///     메타데이터이며 인증 증빙으로 사용하지 않습니다.
String? verifiedVisitProofId(Iterable<VisitEvent> visits, String placeId) {
  final normalizedPlaceId = placeId.trim();
  if (normalizedPlaceId.isEmpty) return null;

  final matches =
      visits
          .where(
            (visit) =>
                visit.placeId.trim() == normalizedPlaceId && visit.isVerified,
          )
          .toList(growable: false)
        ..sort((left, right) {
          final leftTime =
              left.visitedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final rightTime =
              right.visitedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return rightTime.compareTo(leftTime);
        });
  return matches.isEmpty ? null : matches.first.id;
}

final travelReviewsRepositoryProvider = Provider<TravelReviewsRepository>((
  ref,
) {
  return TravelReviewsRepositoryImpl(
    TravelReviewsRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final travelReviewsProvider = FutureProvider.autoDispose
    .family<List<TravelReviewSummary>, String>((ref, projectCode) async {
      final normalizedProjectCode = projectCode.trim();
      if (normalizedProjectCode.isEmpty) return const [];
      final result = await ref
          .watch(travelReviewsRepositoryProvider)
          .getReviews(projectCode: normalizedProjectCode);
      return switch (result) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };
    });

typedef TravelReviewDetailArgs = ({String projectCode, String reviewId});

final travelReviewDetailProvider = FutureProvider.autoDispose
    .family<TravelReviewDetail, TravelReviewDetailArgs>((ref, args) async {
      final result = await ref
          .watch(travelReviewsRepositoryProvider)
          .getReview(
            projectCode: args.projectCode.trim(),
            reviewId: args.reviewId.trim(),
          );
      return switch (result) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };
    });

final travelReviewMutationControllerProvider =
    StateNotifierProvider.autoDispose<
      TravelReviewMutationController,
      AsyncValue<TravelReviewDetail?>
    >((ref) => TravelReviewMutationController(ref));

class TravelReviewMutationController
    extends StateNotifier<AsyncValue<TravelReviewDetail?>> {
  TravelReviewMutationController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<Result<TravelReviewDetail>> create({
    required String projectCode,
    required TravelReviewDraft draft,
  }) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(travelReviewsRepositoryProvider)
        .create(projectCode: projectCode, draft: draft);
    if (!mounted) return result;
    switch (result) {
      case Success(:final data):
        state = AsyncData(data);
        _ref.invalidate(travelReviewsProvider(projectCode));
      case Err(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  Future<Result<TravelReviewDetail>> update({
    required String projectCode,
    required String reviewId,
    required TravelReviewPatch patch,
  }) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(travelReviewsRepositoryProvider)
        .update(projectCode: projectCode, reviewId: reviewId, patch: patch);
    if (!mounted) return result;
    switch (result) {
      case Success(:final data):
        state = AsyncData(data);
        _invalidate(projectCode, reviewId);
      case Err(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> delete({
    required String projectCode,
    required String reviewId,
  }) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(travelReviewsRepositoryProvider)
        .delete(projectCode: projectCode, reviewId: reviewId);
    if (!mounted) return result;
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _invalidate(projectCode, reviewId);
      case Err(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  void _invalidate(String projectCode, String reviewId) {
    _ref.invalidate(travelReviewsProvider(projectCode));
    _ref.invalidate(
      travelReviewDetailProvider((
        projectCode: projectCode,
        reviewId: reviewId,
      )),
    );
  }
}
