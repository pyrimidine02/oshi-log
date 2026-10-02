/// EN: Notification settings DTO for push/email preferences.
/// KO: 푸시/이메일 알림 설정 DTO.
library;

class NotificationSettingsDto {
  const NotificationSettingsDto({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.categories,
    this.version,
    this.updatedAt,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final List<String> categories;
  final int? version;
  final DateTime? updatedAt;

  factory NotificationSettingsDto.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['categories'];
    final categories = <String>[];
    if (categoriesRaw is List) {
      categories.addAll(categoriesRaw.whereType<String>());
    }

    return NotificationSettingsDto(
      pushEnabled: _bool(json, ['pushEnabled', 'push', 'push_enabled'], true),
      emailEnabled: _bool(json, [
        'emailEnabled',
        'email',
        'email_enabled',
      ], true),
      categories: _normalizeCategories(categories),
      version: _int(json, ['version']),
      updatedAt: _dateTime(json, ['updatedAt', 'updated_at']),
    );
  }

  /// EN: Serialize full DTO for cache/local persistence.
  /// KO: 캐시/로컬 저장용으로 DTO 전체 필드를 직렬화합니다.
  Map<String, dynamic> toJson() {
    final normalizedCategories = _normalizeCategories(categories);
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'categories': normalizedCategories,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }

  /// EN: Serialize request payload for PUT /notifications/settings.
  /// KO: PUT /notifications/settings 요청 페이로드를 직렬화합니다.
  Map<String, dynamic> toRequestJson() {
    final normalizedCategories = _normalizeCategories(categories);
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'categories': normalizedCategories,
      if (version != null) 'version': version,
    };
  }
}

bool _bool(Map<String, dynamic> json, List<String> keys, bool fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
        return false;
      }
    }
  }
  return fallback;
}

List<String> _normalizeCategories(List<String> categories) {
  final normalized = <String>[];
  for (final raw in categories) {
    final upper = raw.trim().toUpperCase();
    if (upper.isEmpty) {
      continue;
    }
    final canonical = switch (upper) {
      'LIVE_EVENTS' => 'LIVE_EVENT',
      'FOLLOWING_POSTS' ||
      'FOLLOWING_POST_CREATED' ||
      'FOLLOWING_POST_NOTIFICATION' => 'FOLLOWING_POST',
      'COMMENTS' ||
      'COMMENT_CREATED' ||
      'COMMENT_REPLY_CREATED' ||
      'MY_POST_COMMENT_CREATED' ||
      'MY_COMMENT_REPLY_CREATED' => 'COMMENT',
      _ => upper,
    };
    if (!normalized.contains(canonical)) {
      normalized.add(canonical);
    }
  }
  return normalized;
}

int? _int(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

DateTime? _dateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}
