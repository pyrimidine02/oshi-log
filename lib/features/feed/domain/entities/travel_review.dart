/// EN: Immutable travel-review domain aggregate and write commands.
/// KO: 불변 여행 후기 도메인 애그리거트와 쓰기 명령입니다.
library;

import 'package:intl/intl.dart';

import '../../data/dto/travel_review_dto.dart';
import 'feed_entities.dart';

class TravelReviewPlace {
  const TravelReviewPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  factory TravelReviewPlace.fromDto(TravelReviewPlaceSummaryDto dto) {
    return TravelReviewPlace(
      id: dto.id,
      name: dto.name,
      address: dto.address,
      latitude: dto.latitude,
      longitude: dto.longitude,
    );
  }
}

class TravelReviewLiveEvent {
  const TravelReviewLiveEvent({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.placeId,
    this.posterUrl,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? placeId;
  final String? posterUrl;

  String get dateLabel =>
      DateFormat('yyyy.MM.dd HH:mm').format(startTime.toLocal());

  factory TravelReviewLiveEvent.fromDto(TravelReviewLiveEventSummaryDto dto) {
    return TravelReviewLiveEvent(
      id: dto.id,
      title: dto.title,
      startTime: dto.startTime,
      endTime: dto.endTime,
      placeId: dto.placeId,
      posterUrl: dto.posterUrl,
    );
  }
}

class TravelReviewStop {
  const TravelReviewStop({
    required this.order,
    required this.place,
    required this.verified,
    this.verifiedVisitId,
    this.note,
  });

  final int order;
  final TravelReviewPlace place;
  final bool verified;
  final String? verifiedVisitId;
  final String? note;

  factory TravelReviewStop.fromDto(TravelReviewStopDto dto) {
    return TravelReviewStop(
      order: dto.order,
      place: TravelReviewPlace.fromDto(dto.place),
      verified: dto.verified,
      verifiedVisitId: dto.verifiedVisitId,
      note: dto.note,
    );
  }
}

class TravelReviewEvent {
  const TravelReviewEvent({
    required this.order,
    required this.event,
    required this.verified,
    this.verifiedAttendanceId,
    this.note,
  });

  final int order;
  final TravelReviewLiveEvent event;
  final bool verified;
  final String? verifiedAttendanceId;
  final String? note;

  factory TravelReviewEvent.fromDto(TravelReviewEventDto dto) {
    return TravelReviewEvent(
      order: dto.order,
      event: TravelReviewLiveEvent.fromDto(dto.event),
      verified: dto.verified,
      verifiedAttendanceId: dto.verifiedAttendanceId,
      note: dto.note,
    );
  }
}

class TravelReviewFanSubject {
  const TravelReviewFanSubject({
    required this.id,
    required this.type,
    required this.name,
    required this.primary,
    this.imageUrl,
  });

  final String id;
  final String type;
  final String name;
  final String? imageUrl;
  final bool primary;

  factory TravelReviewFanSubject.fromDto(TravelReviewFanSubjectSummaryDto dto) {
    return TravelReviewFanSubject(
      id: dto.id,
      type: dto.type,
      name: dto.name,
      imageUrl: dto.imageUrl,
      primary: dto.primary,
    );
  }
}

class TravelReviewSummary {
  const TravelReviewSummary({
    required this.id,
    required this.postId,
    required this.projectId,
    required this.post,
    required this.stops,
    required this.events,
    required this.fanSubjects,
    required this.createdAt,
    this.tripStartedOn,
    this.tripEndedOn,
    this.routeNote,
    this.updatedAt,
  });

  final String id;
  final String postId;
  final String projectId;
  final PostSummary post;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;
  final List<TravelReviewStop> stops;
  final List<TravelReviewEvent> events;
  final List<TravelReviewFanSubject> fanSubjects;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory TravelReviewSummary.fromDto(TravelReviewSummaryDto dto) {
    return TravelReviewSummary(
      id: dto.id,
      postId: dto.postId,
      projectId: dto.projectId,
      post: PostSummary.fromDto(dto.post),
      tripStartedOn: dto.tripStartedOn,
      tripEndedOn: dto.tripEndedOn,
      routeNote: dto.routeNote,
      stops: dto.stops.map(TravelReviewStop.fromDto).toList(growable: false),
      events: dto.events.map(TravelReviewEvent.fromDto).toList(growable: false),
      fanSubjects: dto.fanSubjects
          .map(TravelReviewFanSubject.fromDto)
          .toList(growable: false),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}

class TravelReviewDetail {
  const TravelReviewDetail({
    required this.id,
    required this.postId,
    required this.projectId,
    required this.post,
    required this.stops,
    required this.events,
    required this.fanSubjects,
    required this.createdAt,
    this.tripStartedOn,
    this.tripEndedOn,
    this.routeNote,
    this.updatedAt,
  });

  final String id;
  final String postId;
  final String projectId;
  final PostDetail post;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;
  final List<TravelReviewStop> stops;
  final List<TravelReviewEvent> events;
  final List<TravelReviewFanSubject> fanSubjects;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get tripDateLabel {
    final start = tripStartedOn;
    final end = tripEndedOn;
    if (start == null && end == null) return '';
    if (start == null) return DateFormat('yyyy.MM.dd').format(end!);
    final startLabel = DateFormat('yyyy.MM.dd').format(start);
    if (end == null || _isSameDate(start, end)) return startLabel;
    return '$startLabel – ${DateFormat('yyyy.MM.dd').format(end)}';
  }

  factory TravelReviewDetail.fromDto(TravelReviewDetailDto dto) {
    return TravelReviewDetail(
      id: dto.id,
      postId: dto.postId,
      projectId: dto.projectId,
      post: PostDetail.fromDto(dto.post),
      tripStartedOn: dto.tripStartedOn,
      tripEndedOn: dto.tripEndedOn,
      routeNote: dto.routeNote,
      stops: dto.stops.map(TravelReviewStop.fromDto).toList(growable: false),
      events: dto.events.map(TravelReviewEvent.fromDto).toList(growable: false),
      fanSubjects: dto.fanSubjects
          .map(TravelReviewFanSubject.fromDto)
          .toList(growable: false),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}

class TravelReviewStopDraft {
  const TravelReviewStopDraft({
    required this.placeId,
    this.verifiedVisitId,
    this.note,
  });

  final String placeId;
  final String? verifiedVisitId;
  final String? note;
}

class TravelReviewEventDraft {
  const TravelReviewEventDraft({
    required this.liveEventId,
    this.verifiedAttendanceId,
    this.note,
  });

  final String liveEventId;
  final String? verifiedAttendanceId;
  final String? note;
}

class TravelReviewDraft {
  const TravelReviewDraft({
    required this.title,
    required this.content,
    required this.stops,
    this.imageUploadIds = const [],
    this.tags,
    this.events = const [],
    this.fanSubjectIds = const [],
    this.tripStartedOn,
    this.tripEndedOn,
    this.routeNote,
  });

  final String title;
  final String content;
  final List<String> imageUploadIds;
  final List<String>? tags;
  final List<TravelReviewStopDraft> stops;
  final List<TravelReviewEventDraft> events;
  final List<String> fanSubjectIds;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;
}

class TravelReviewPatch {
  const TravelReviewPatch({
    this.title,
    this.content,
    this.imageUploadIds,
    this.tags,
    this.stops,
    this.events,
    this.fanSubjectIds,
    this.tripStartedOn,
    this.tripEndedOn,
    this.routeNote,
  });

  final String? title;
  final String? content;
  final List<String>? imageUploadIds;
  final List<String>? tags;
  final List<TravelReviewStopDraft>? stops;
  final List<TravelReviewEventDraft>? events;
  final List<String>? fanSubjectIds;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
