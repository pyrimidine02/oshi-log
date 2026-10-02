/// EN: Favorite DTO for saved items.
/// KO: 즐겨찾기 아이템 DTO.
library;

class FavoriteItemDto {
  const FavoriteItemDto({
    required this.entityType,
    required this.entityId,
    this.projectCode,
    this.title,
    this.thumbnailUrl,
  });

  final String entityType;
  final String entityId;
  final String? projectCode;
  final String? title;
  final String? thumbnailUrl;

  factory FavoriteItemDto.fromJson(Map<String, dynamic> json) {
    final entity = json['entity'];
    final entityMap = entity is Map<String, dynamic> ? entity : null;
    final projectMap = json['project'];
    final projectPayload = projectMap is Map<String, dynamic>
        ? projectMap
        : null;
    final entityProjectMap = entityMap?['project'];
    final entityProjectPayload = entityProjectMap is Map<String, dynamic>
        ? entityProjectMap
        : null;
    final normalizedEntityId = _normalizeEntityId(
      _firstNonEmptyString(json, const [
            'entityId',
            'targetId',
            'itemId',
            'id',
            'resourceId',
            'placeId',
            'postId',
            'newsId',
            'liveEventId',
          ]) ??
          _firstNonEmptyString(entityMap, const [
            'entityId',
            'targetId',
            'itemId',
            'id',
            'resourceId',
            'placeId',
            'postId',
            'newsId',
            'liveEventId',
          ]),
    );

    return FavoriteItemDto(
      entityType:
          _firstNonEmptyString(json, const [
            'entityType',
            'targetType',
            'type',
            'entity_type',
          ]) ??
          _firstNonEmptyString(entityMap, const [
            'entityType',
            'targetType',
            'type',
            'entity_type',
          ]) ??
          '',
      entityId: normalizedEntityId ?? '',
      projectCode:
          _firstNonEmptyString(json, const [
            'projectCode',
            'projectId',
            'project',
          ]) ??
          _firstNonEmptyString(entityMap, const [
            'projectCode',
            'projectId',
            'project',
          ]) ??
          _firstNonEmptyString(projectPayload, const [
            'code',
            'projectCode',
            'id',
            'projectId',
          ]) ??
          _firstNonEmptyString(entityProjectPayload, const [
            'code',
            'projectCode',
            'id',
            'projectId',
          ]),
      title:
          _firstNonEmptyString(json, const ['title', 'name']) ??
          _firstNonEmptyString(entityMap, const ['title', 'name']),
      thumbnailUrl:
          _firstNonEmptyString(json, const [
            'thumbnailUrl',
            'imageUrl',
            'image',
            'thumbnail',
          ]) ??
          _firstNonEmptyString(entityMap, const [
            'thumbnailUrl',
            'imageUrl',
            'image',
            'thumbnail',
          ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'projectCode': projectCode,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

String? _firstNonEmptyString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
  }
  return null;
}

String? _normalizeEntityId(String? raw) {
  if (raw == null) return null;
  var value = raw.trim();
  if (value.isEmpty) {
    return null;
  }

  // EN: Support deeplink/action style payloads by extracting known IDs.
  // KO: deeplink/action 형태 payload도 처리할 수 있도록 ID를 추출합니다.
  final uri = Uri.tryParse(value);
  if (uri != null) {
    final queryCandidate =
        uri.queryParameters['entityId'] ??
        uri.queryParameters['targetId'] ??
        uri.queryParameters['placeId'] ??
        uri.queryParameters['postId'] ??
        uri.queryParameters['newsId'] ??
        uri.queryParameters['liveEventId'];
    if (queryCandidate != null && queryCandidate.trim().isNotEmpty) {
      value = queryCandidate.trim();
    } else if (uri.pathSegments.isNotEmpty) {
      value = uri.pathSegments.last.trim();
    }
  }

  if (value.contains(':')) {
    final tail = value.split(':').last.trim();
    if (tail.isNotEmpty) {
      value = tail;
    }
  }

  if (value.contains('/')) {
    final tail = value.split('/').last.trim();
    if (tail.isNotEmpty) {
      value = tail;
    }
  }

  return value.isEmpty ? null : value;
}
