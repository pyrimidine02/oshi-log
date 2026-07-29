import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/feed/data/datasources/travel_reviews_remote_data_source.dart';
import 'package:oshi_log/features/feed/data/dto/travel_review_dto.dart';

void main() {
  late _MockApiClient apiClient;
  late TravelReviewsRemoteDataSource dataSource;

  setUp(() {
    apiClient = _MockApiClient();
    dataSource = TravelReviewsRemoteDataSource(apiClient);
  });

  test(
    'creates a review at the project-code endpoint with exact body',
    () async {
      final response = _detailDto();
      when(
        () => apiClient.post<TravelReviewDetailDto>(
          any(),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => Result.success(response));
      const request = TravelReviewCreateRequestDto(
        title: '필드 노트',
        content: '여행 기록',
        stops: [TravelReviewStopRequestDto(placeId: 'place-1')],
        events: [TravelReviewEventRequestDto(liveEventId: 'event-1')],
        fanSubjectIds: ['subject-1'],
      );

      await dataSource.create(projectCode: 'bang-dream', request: request);

      final captured = verify(
        () => apiClient.post<TravelReviewDetailDto>(
          ApiEndpoints.travelReviews('bang-dream'),
          data: captureAny(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).captured.single;
      expect(captured, request.toJson());
    },
  );

  test('lists and mutates through the review aggregate endpoint', () async {
    when(
      () => apiClient.get<List<TravelReviewSummaryDto>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => apiClient.patch<TravelReviewDetailDto>(
        any(),
        data: any(named: 'data'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => Result.success(_detailDto()));
    when(
      () => apiClient.delete<void>(any(), fromJson: any(named: 'fromJson')),
    ).thenAnswer((_) async => const Result.success(null));

    await dataSource.list(projectCode: 'bang-dream', page: 2, size: 30);
    await dataSource.update(
      projectCode: 'bang-dream',
      reviewId: 'review-1',
      request: const TravelReviewUpdateRequestDto(routeNote: '수정된 메모'),
    );
    await dataSource.delete(projectCode: 'bang-dream', reviewId: 'review-1');

    verify(
      () => apiClient.get<List<TravelReviewSummaryDto>>(
        ApiEndpoints.travelReviews('bang-dream'),
        queryParameters: {'page': 2, 'size': 30},
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
    verify(
      () => apiClient.patch<TravelReviewDetailDto>(
        ApiEndpoints.travelReview('bang-dream', 'review-1'),
        data: {'routeNote': '수정된 메모'},
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
    verify(
      () => apiClient.delete<void>(
        ApiEndpoints.travelReview('bang-dream', 'review-1'),
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });
}

TravelReviewDetailDto _detailDto() {
  return TravelReviewDetailDto.fromJson({
    'id': 'review-1',
    'postId': 'post-1',
    'projectId': 'project-1',
    'post': {
      'id': 'post-1',
      'projectId': 'project-1',
      'authorId': 'author-1',
      'title': '필드 노트',
      'content': '여행 기록',
      'createdAt': '2026-07-15T10:00:00+09:00',
    },
    'stops': const [],
    'events': const [],
    'fanSubjects': const [],
    'createdAt': '2026-07-15T10:00:00+09:00',
  });
}

class _MockApiClient extends Mock implements ApiClient {}
