/// EN: Notification navigation resolver helpers.
/// KO: 알림 네비게이션 경로 해석 헬퍼입니다.
library;

const String notificationTypePostCreated = 'POST_CREATED';
const String notificationTypeSystemNotice = 'SYSTEM_NOTICE';

/// EN: Notification type for automatic title grant.
/// KO: 칭호 자동 부여 알림 타입.
const String notificationTypeTitleEarned = 'TITLE_EARNED';

/// EN: Normalize notification type with legacy alias compatibility.
/// KO: 레거시 별칭을 포함해 알림 타입을 정규화합니다.
String normalizeNotificationType(String? rawType) {
  final upper = rawType?.trim().toUpperCase() ?? '';
  return switch (upper) {
    'FOLLOWING_POST' ||
    'FOLLOWING_POSTS' ||
    'FOLLOWING_POST_CREATED' ||
    'FOLLOWED_POST_CREATED' ||
    'FOLLOWED_USER_POST_CREATED' ||
    'FOLLOWER_POST_CREATED' => notificationTypePostCreated,
    'MY_POST_COMMENT_CREATED' ||
    'POST_COMMENT_CREATED' ||
    'COMMUNITY_COMMENT' ||
    'COMMENT_ADDED' => 'COMMENT_CREATED',
    'MY_COMMENT_REPLY_CREATED' ||
    'POST_COMMENT_REPLY_CREATED' ||
    'COMMUNITY_REPLY' ||
    'COMMENT_REPLIED' ||
    'REPLY_CREATED' => 'COMMENT_REPLY_CREATED',
    'COMMUNITY_LIKE' => 'POST_LIKED',
    'TITLE_GRANTED' => notificationTypeTitleEarned,
    'SYSTEM_BROADCAST' || 'SYSTEM' => notificationTypeSystemNotice,
    _ => upper,
  };
}

/// EN: Resolve in-app destination path from notification payload fields.
/// KO: 알림 페이로드 필드로부터 앱 내 목적 경로를 해석합니다.
String? resolveNotificationNavigationPath({
  String? type,
  String? deeplink,
  String? actionUrl,
  String? entityId,
}) {
  final normalizedType = normalizeNotificationType(type);
  // EN: Contract v1.1.0 prefers deeplink over actionUrl for all types.
  // KO: 계약 v1.1.0 기준으로 모든 타입에서 deeplink를 actionUrl보다 우선합니다.
  final primaryLink = _firstNonEmpty(deeplink, actionUrl);
  final secondaryLink = _firstNonEmpty(actionUrl, deeplink);

  final directPath =
      _resolveInAppPath(primaryLink) ?? _resolveInAppPath(secondaryLink);
  if (directPath != null) {
    return directPath;
  }

  final postId =
      _extractPostId(entityId) ??
      _extractPostId(primaryLink) ??
      _extractPostId(secondaryLink);
  if (_isPostScopedType(normalizedType) &&
      postId != null &&
      postId.isNotEmpty) {
    return '/overlay/board/posts/$postId';
  }

  if (_isPostScopedType(normalizedType)) {
    return '/community';
  }

  if (normalizedType == notificationTypeSystemNotice) {
    return '/notifications';
  }

  // EN: Title earned — navigate to the catalog page, optionally pre-selecting
  //     the earned title via the titleId query parameter (entityId = titleId).
  // KO: 칭호 획득 알림 — 칭호 카탈로그 페이지로 이동합니다.
  //     entityId(= titleId)를 titleId 쿼리 파라미터로 전달해 해당 칭호를
  //     자동으로 선택합니다.
  if (normalizedType == notificationTypeTitleEarned) {
    final titleId = entityId?.trim();
    if (titleId != null && titleId.isNotEmpty) {
      return '/title-picker?titleId=$titleId';
    }
    return '/title-picker';
  }

  // EN: Live event notifications — navigate to event detail if entityId provided,
  //     otherwise fall back to the live events tab.
  // KO: 라이브이벤트 알림 — entityId가 있으면 이벤트 상세로, 없으면 라이브이벤트 탭으로 이동.
  if (_isLiveEventType(normalizedType)) {
    final eventId = entityId?.trim();
    if (eventId != null && eventId.isNotEmpty) {
      return '/overlay/events/$eventId';
    }
    return '/visits?tab=live';
  }

  // EN: Moderation notifications — stay within the notification center.
  // KO: 제재 알림 — 알림 센터에 머뭅니다.
  if (normalizedType == 'MODERATION') {
    return '/notifications';
  }

  return null;
}

String? _resolveInAppPath(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final trimmed = raw.trim();

  if (trimmed.startsWith('/')) {
    return _normalizePath(trimmed);
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return null;
  }

  if (uri.scheme.toLowerCase() == 'gbt') {
    final host = uri.host.trim();
    final segments = <String>[
      if (host.isNotEmpty) host,
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
    ];
    final path = '/${segments.join('/')}';
    return _normalizePath(path, query: uri.query);
  }

  if (uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.path.isNotEmpty) {
    return _normalizePath(uri.path, query: uri.query);
  }

  return null;
}

String? _normalizePath(String rawPath, {String? query}) {
  final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';

  if (path.startsWith('/api/v1/projects/')) {
    final postMatch = RegExp(
      r'^/api/v1/projects/[^/]+/posts/([^/?#]+)',
    ).firstMatch(path);
    if (postMatch != null) {
      final postId = postMatch.group(1);
      if (postId != null && postId.isNotEmpty) {
        return '/overlay/board/posts/$postId';
      }
    }
  }
  if (path.startsWith('/community/posts/')) {
    final postId = _extractPostId(path);
    if (postId != null && postId.isNotEmpty) {
      return _appendQuery('/overlay/board/posts/$postId', query);
    }
  }

  if (path == '/api/v1/notifications' || path == '/notifications') {
    return '/notifications';
  }
  if (path.startsWith('/board/posts/')) {
    return _appendQuery('/overlay$path', query);
  }
  if (path.startsWith('/overlay/board/posts/')) {
    return _appendQuery(path, query);
  }
  if (path.startsWith('/info/news/')) {
    final newsId = path.split('/').where((s) => s.isNotEmpty).lastOrNull;
    if (newsId != null && newsId.isNotEmpty) {
      return _appendQuery('/overlay/info/news/$newsId', query);
    }
  }
  if (path.startsWith('/overlay/info/news/')) {
    return _appendQuery(path, query);
  }
  if (path.startsWith('/users/')) {
    return _appendQuery(path, query);
  }
  if (path.startsWith('/live/')) {
    final eventId = path.split('/').where((s) => s.isNotEmpty).lastOrNull;
    if (eventId != null && eventId.isNotEmpty) {
      return _appendQuery('/overlay/events/$eventId', query);
    }
  }
  if (path.startsWith('/overlay/events/')) {
    return _appendQuery(path, query);
  }
  if (path.startsWith('/places/')) {
    final placeId = path.split('/').where((s) => s.isNotEmpty).lastOrNull;
    if (placeId != null && placeId.isNotEmpty) {
      return _appendQuery('/overlay/places/$placeId', query);
    }
  }
  if (path.startsWith('/overlay/places/')) {
    return _appendQuery(path, query);
  }
  if (path.startsWith('/notifications')) {
    return _appendQuery(path, query);
  }
  if (path == '/title-picker' ||
      path.startsWith('/title-picker') ||
      path.startsWith('/titles')) {
    return _appendQuery('/title-picker', query);
  }

  return null;
}

String _appendQuery(String path, String? query) {
  if (query == null || query.isEmpty) {
    return path;
  }
  return '$path?$query';
}

String? _extractPostId(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final trimmed = raw.trim();
  final directUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (directUuid.hasMatch(trimmed)) {
    return trimmed;
  }
  final match = RegExp(r'/posts/([0-9a-zA-Z-]{8,})').firstMatch(trimmed);
  return match?.group(1);
}

String? _firstNonEmpty(String? first, String? second) {
  if (first != null && first.trim().isNotEmpty) {
    return first.trim();
  }
  if (second != null && second.trim().isNotEmpty) {
    return second.trim();
  }
  return null;
}

bool _isLiveEventType(String normalizedType) {
  return normalizedType == 'LIVE_EVENT_UPDATED' ||
      normalizedType == 'LIVE_EVENT_CANCELLED' ||
      normalizedType == 'LIVE_EVENT_ATTENDANCE_VERIFIED';
}

bool _isPostScopedType(String normalizedType) {
  if (normalizedType == notificationTypePostCreated) {
    return true;
  }
  return switch (normalizedType) {
    'COMMENT_CREATED' ||
    'COMMENT_REPLY_CREATED' ||
    'POST_LIKED' ||
    'COMMUNITY_COMMENT' ||
    'COMMUNITY_REPLY' ||
    'COMMUNITY_LIKE' => true,
    _ => false,
  };
}
