/// EN: DTOs for the project-scoped pilgrimage travel-review aggregate.
/// KO: 프로젝트 범위 성지순례 여행 후기 애그리거트 DTO입니다.
library;

import 'post_dto.dart';

class TravelReviewStopRequestDto {
  const TravelReviewStopRequestDto({
    required this.placeId,
    this.verifiedVisitId,
    this.note,
  });

  final String placeId;
  final String? verifiedVisitId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    if (_hasText(verifiedVisitId)) 'verifiedVisitId': verifiedVisitId!.trim(),
    if (_hasText(note)) 'note': note!.trim(),
  };
}

class TravelReviewEventRequestDto {
  const TravelReviewEventRequestDto({
    required this.liveEventId,
    this.verifiedAttendanceId,
    this.note,
  });

  final String liveEventId;
  final String? verifiedAttendanceId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'liveEventId': liveEventId,
    if (_hasText(verifiedAttendanceId))
      'verifiedAttendanceId': verifiedAttendanceId!.trim(),
    if (_hasText(note)) 'note': note!.trim(),
  };
}

class TravelReviewCreateRequestDto {
  const TravelReviewCreateRequestDto({
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
  final List<TravelReviewStopRequestDto> stops;
  final List<TravelReviewEventRequestDto> events;
  final List<String> fanSubjectIds;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'content': content,
    'imageUploadIds': imageUploadIds,
    if (tags != null) 'tags': tags,
    'stops': stops.map((stop) => stop.toJson()).toList(growable: false),
    'events': events.map((event) => event.toJson()).toList(growable: false),
    'fanSubjectIds': fanSubjectIds,
    if (tripStartedOn != null)
      'tripStartedOn': _localDateString(tripStartedOn!),
    if (tripEndedOn != null) 'tripEndedOn': _localDateString(tripEndedOn!),
    if (_hasText(routeNote)) 'routeNote': routeNote!.trim(),
  };
}

class TravelReviewUpdateRequestDto {
  const TravelReviewUpdateRequestDto({
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
  final List<TravelReviewStopRequestDto>? stops;
  final List<TravelReviewEventRequestDto>? events;
  final List<String>? fanSubjectIds;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title!.trim(),
    if (content != null) 'content': content,
    if (imageUploadIds != null) 'imageUploadIds': imageUploadIds,
    if (tags != null) 'tags': tags,
    if (stops != null)
      'stops': stops!.map((stop) => stop.toJson()).toList(growable: false),
    if (events != null)
      'events': events!.map((event) => event.toJson()).toList(growable: false),
    if (fanSubjectIds != null) 'fanSubjectIds': fanSubjectIds,
    if (tripStartedOn != null)
      'tripStartedOn': _localDateString(tripStartedOn!),
    if (tripEndedOn != null) 'tripEndedOn': _localDateString(tripEndedOn!),
    if (routeNote != null) 'routeNote': routeNote!.trim(),
  };
}

class TravelReviewPlaceSummaryDto {
  const TravelReviewPlaceSummaryDto({
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

  factory TravelReviewPlaceSummaryDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewPlaceSummaryDto(
      id: _string(json['id']),
      name: _string(json['name']),
      address: _nullableString(json['address']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
    );
  }
}

class TravelReviewLiveEventSummaryDto {
  const TravelReviewLiveEventSummaryDto({
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

  factory TravelReviewLiveEventSummaryDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewLiveEventSummaryDto(
      id: _string(json['id']),
      title: _string(json['title']),
      startTime: _dateTime(json['startTime']),
      endTime: _dateTimeOrNull(json['endTime']),
      placeId: _nullableString(json['placeId']),
      posterUrl: _nullableString(json['posterUrl']),
    );
  }
}

class TravelReviewStopDto {
  const TravelReviewStopDto({
    required this.order,
    required this.place,
    required this.verified,
    this.verifiedVisitId,
    this.note,
  });

  final int order;
  final TravelReviewPlaceSummaryDto place;
  final bool verified;
  final String? verifiedVisitId;
  final String? note;

  factory TravelReviewStopDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewStopDto(
      order: _int(json['order']),
      place: TravelReviewPlaceSummaryDto.fromJson(_map(json['place'])),
      verified: json['verified'] == true,
      verifiedVisitId: _nullableString(json['verifiedVisitId']),
      note: _nullableString(json['note']),
    );
  }
}

class TravelReviewEventDto {
  const TravelReviewEventDto({
    required this.order,
    required this.event,
    required this.verified,
    this.verifiedAttendanceId,
    this.note,
  });

  final int order;
  final TravelReviewLiveEventSummaryDto event;
  final bool verified;
  final String? verifiedAttendanceId;
  final String? note;

  factory TravelReviewEventDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewEventDto(
      order: _int(json['order']),
      event: TravelReviewLiveEventSummaryDto.fromJson(_map(json['event'])),
      verified: json['verified'] == true,
      verifiedAttendanceId: _nullableString(json['verifiedAttendanceId']),
      note: _nullableString(json['note']),
    );
  }
}

class TravelReviewFanSubjectSummaryDto {
  const TravelReviewFanSubjectSummaryDto({
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

  factory TravelReviewFanSubjectSummaryDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewFanSubjectSummaryDto(
      id: _string(json['id']),
      type: _string(json['type']),
      name: _string(json['name']),
      imageUrl: _nullableString(json['imageUrl']),
      primary: json['primary'] == true,
    );
  }
}

class TravelReviewDetailDto {
  const TravelReviewDetailDto({
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
  final PostDetailDto post;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;
  final List<TravelReviewStopDto> stops;
  final List<TravelReviewEventDto> events;
  final List<TravelReviewFanSubjectSummaryDto> fanSubjects;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory TravelReviewDetailDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewDetailDto(
      id: _string(json['id']),
      postId: _string(json['postId']),
      projectId: _string(json['projectId']),
      post: PostDetailDto.fromJson(_map(json['post'])),
      tripStartedOn: _localDateOrNull(json['tripStartedOn']),
      tripEndedOn: _localDateOrNull(json['tripEndedOn']),
      routeNote: _nullableString(json['routeNote']),
      stops: _list(json['stops'], TravelReviewStopDto.fromJson),
      events: _list(json['events'], TravelReviewEventDto.fromJson),
      fanSubjects: _list(
        json['fanSubjects'],
        TravelReviewFanSubjectSummaryDto.fromJson,
      ),
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTimeOrNull(json['updatedAt']),
    );
  }
}

class TravelReviewSummaryDto {
  const TravelReviewSummaryDto({
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
  final PostSummaryDto post;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final String? routeNote;
  final List<TravelReviewStopDto> stops;
  final List<TravelReviewEventDto> events;
  final List<TravelReviewFanSubjectSummaryDto> fanSubjects;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory TravelReviewSummaryDto.fromJson(Map<String, dynamic> json) {
    return TravelReviewSummaryDto(
      id: _string(json['id']),
      postId: _string(json['postId']),
      projectId: _string(json['projectId']),
      post: PostSummaryDto.fromJson(_map(json['post'])),
      tripStartedOn: _localDateOrNull(json['tripStartedOn']),
      tripEndedOn: _localDateOrNull(json['tripEndedOn']),
      routeNote: _nullableString(json['routeNote']),
      stops: _list(json['stops'], TravelReviewStopDto.fromJson),
      events: _list(json['events'], TravelReviewEventDto.fromJson),
      fanSubjects: _list(
        json['fanSubjects'],
        TravelReviewFanSubjectSummaryDto.fromJson,
      ),
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTimeOrNull(json['updatedAt']),
    );
  }
}

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return <T>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

Map<String, dynamic> _map(dynamic value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}

String _string(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _dateTime(dynamic value) {
  return _dateTimeOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateTimeOrNull(dynamic value) {
  return value is String ? DateTime.tryParse(value) : null;
}

DateTime? _localDateOrNull(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String _localDateString(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
}
