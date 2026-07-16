import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/feed/data/dto/travel_review_dto.dart';

void main() {
  test(
    'decodes the complete travel review aggregate from the server contract',
    () {
      final dto = TravelReviewDetailDto.fromJson({
        'id': 'review-1',
        'postId': 'post-1',
        'projectId': 'project-1',
        'post': {
          'id': 'post-1',
          'projectId': 'project-1',
          'authorId': 'subject-1',
          'authorName': '타비맨니아',
          'authorProfile': {
            'id': 'subject-1',
            'displayName': '타비맨니아',
            'avatarUrl': 'https://cdn.example/avatar.webp',
          },
          'title': '도쿄 순례',
          'content': '좋은 여행이었어요.',
          'topic': 'TRAVEL_REVIEW',
          'tags': ['도쿄'],
          'images': [
            {'url': 'https://cdn.example/review.webp'},
          ],
          'commentCount': 8,
          'likeCount': 42,
          'createdAt': '2026-07-15T10:00:00+09:00',
          'updatedAt': '2026-07-15T11:00:00+09:00',
        },
        'tripStartedOn': '2026-07-14',
        'tripEndedOn': '2026-07-15',
        'routeNote': '아침에 출발',
        'stops': [
          {
            'order': 0,
            'place': {
              'id': 'place-1',
              'name': '도쿄 역',
              'address': '도쿄도 치요다구',
              'latitude': 35.6812,
              'longitude': 139.7671,
            },
            'verified': true,
            'verifiedVisitId': 'visit-1',
            'note': '첫 장소',
          },
        ],
        'events': [
          {
            'order': 0,
            'event': {
              'id': 'event-1',
              'title': 'MyGO!!!!! LIVE',
              'startTime': '2026-07-15T18:00:00+09:00',
              'endTime': '2026-07-15T20:00:00+09:00',
              'placeId': 'place-1',
              'posterUrl': 'https://cdn.example/poster.webp',
            },
            'verified': true,
            'verifiedAttendanceId': 'attendance-1',
            'note': '라이브 참가',
          },
        ],
        'fanSubjects': [
          {
            'id': 'subject-2',
            'type': 'UNIT',
            'name': 'MyGO!!!!!',
            'imageUrl': 'https://cdn.example/mygo.webp',
            'primary': true,
          },
        ],
        'createdAt': '2026-07-15T10:00:00+09:00',
        'updatedAt': '2026-07-15T11:00:00+09:00',
      });

      expect(dto.post.authorName, '타비맨니아');
      expect(dto.post.imageUrls, ['https://cdn.example/review.webp']);
      expect(dto.stops.single.order, 0);
      expect(dto.stops.single.verifiedVisitId, 'visit-1');
      expect(dto.events.single.event.title, 'MyGO!!!!! LIVE');
      expect(dto.events.single.verifiedAttendanceId, 'attendance-1');
      expect(dto.fanSubjects.single.type, 'UNIT');
      expect(dto.tripStartedOn, DateTime(2026, 7, 14));
      expect(dto.tripEndedOn, DateTime(2026, 7, 15));
    },
  );

  test('serializes ordered proof references and optional trip metadata', () {
    final request = TravelReviewCreateRequestDto(
      title: '도쿄 순례',
      content: '여행 기록',
      tags: const ['도쿄'],
      stops: const [
        TravelReviewStopRequestDto(
          placeId: 'place-1',
          verifiedVisitId: 'visit-1',
          note: '첫 번째',
        ),
        TravelReviewStopRequestDto(placeId: 'place-2'),
      ],
      events: const [
        TravelReviewEventRequestDto(
          liveEventId: 'event-1',
          verifiedAttendanceId: 'attendance-1',
        ),
      ],
      fanSubjectIds: const ['subject-1', 'subject-2'],
      tripStartedOn: DateTime(2026, 7, 14),
      tripEndedOn: DateTime(2026, 7, 15),
      routeNote: '아침에 출발',
    );

    expect(request.toJson(), {
      'title': '도쿄 순례',
      'content': '여행 기록',
      'imageUploadIds': <String>[],
      'tags': ['도쿄'],
      'stops': [
        {'placeId': 'place-1', 'verifiedVisitId': 'visit-1', 'note': '첫 번째'},
        {'placeId': 'place-2'},
      ],
      'events': [
        {'liveEventId': 'event-1', 'verifiedAttendanceId': 'attendance-1'},
      ],
      'fanSubjectIds': ['subject-1', 'subject-2'],
      'tripStartedOn': '2026-07-14',
      'tripEndedOn': '2026-07-15',
      'routeNote': '아침에 출발',
    });
  });
}
