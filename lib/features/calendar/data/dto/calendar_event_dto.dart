/// EN: DTO for calendar event API responses.
/// KO: 캘린더 이벤트 API 응답의 DTO.
library;

import '../../domain/entities/calendar_event.dart';

/// EN: Data transfer object representing a raw calendar event from the API.
/// KO: API에서 수신한 원시 캘린더 이벤트를 나타내는 데이터 전송 객체.
class CalendarEventDto {
  const CalendarEventDto({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.endDate,
    this.description,
    this.imageUrl,
    this.projectId,
    this.projectCode,
    this.relatedEntityId,
    this.relatedEntityType,
    this.isRecurringAnnually = false,
  });

  /// EN: Constructs a [CalendarEventDto] from a JSON map.
  /// KO: JSON 맵에서 [CalendarEventDto]를 생성합니다.
  factory CalendarEventDto.fromJson(Map<String, dynamic> json) {
    final characterId =
        json['characterId'] as String? ?? json['character_id'] as String?;
    return CalendarEventDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: _parseDateTime(json['date']),
      endDate: _parseOptionalDateTime(json['endDate'] ?? json['end_date']),
      type: json['type'] as String?,
      description: json['description'] as String?,
      imageUrl:
          json['imageUrl'] as String? ??
          json['image_url'] as String? ??
          json['characterImageUrl'] as String? ??
          json['character_image_url'] as String?,
      projectId: json['projectId'] as String? ?? json['project_id'] as String?,
      projectCode:
          json['projectCode'] as String? ??
          json['project_code'] as String? ??
          json['projectKey'] as String? ??
          json['project_key'] as String?,
      relatedEntityId:
          json['relatedEntityId'] as String? ??
          json['related_entity_id'] as String? ??
          characterId,
      relatedEntityType:
          json['relatedEntityType'] as String? ??
          json['related_entity_type'] as String? ??
          (characterId == null ? null : 'character'),
      isRecurringAnnually:
          json['isRecurringAnnually'] as bool? ??
          json['is_recurring_annually'] as bool? ??
          json['isAnnual'] as bool? ??
          json['is_annual'] as bool? ??
          false,
    );
  }

  /// EN: Projects a public live-event summary into the calendar contract.
  /// KO: 공개 라이브 이벤트 요약을 캘린더 계약으로 투영합니다.
  factory CalendarEventDto.fromLiveEventJson(
    Map<String, dynamic> json, {
    required String projectKey,
  }) {
    final sourceId = json['id'] as String? ?? '';
    final projectIds = _stringList(json['projectIds'] ?? json['project_ids']);
    return CalendarEventDto(
      id: 'live:$sourceId',
      title: json['title'] as String? ?? '',
      date: _parseDateTime(json['showStartTime'] ?? json['show_start_time']),
      endDate: _parseOptionalDateTime(json['endTime'] ?? json['end_time']),
      type: 'live',
      imageUrl: json['bannerUrl'] as String? ?? json['banner_url'] as String?,
      projectId: projectIds.firstOrNull,
      projectCode: projectKey,
      relatedEntityId: sourceId,
      relatedEntityType: 'live_event',
    );
  }

  final String id;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final String? type;
  final String? description;
  final String? imageUrl;
  final String? projectId;
  final String? projectCode;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final bool isRecurringAnnually;

  /// EN: Maps this DTO to the domain [CalendarEvent] entity.
  /// KO: 이 DTO를 도메인 [CalendarEvent] 엔티티로 매핑합니다.
  CalendarEvent toEntity() => CalendarEvent(
    id: id,
    title: title,
    date: date,
    type: CalendarEventType.fromString(type),
    description: description,
    imageUrl: imageUrl,
    projectId: projectId,
    projectCode: projectCode,
    relatedEntityId: relatedEntityId,
    relatedEntityType: relatedEntityType,
    isRecurringAnnually: isRecurringAnnually,
  );
}

DateTime _parseDateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseOptionalDateTime(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}
