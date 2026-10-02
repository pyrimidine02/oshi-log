/// EN: Notification settings domain entity.
/// KO: 알림 설정 도메인 엔티티.
library;

class NotificationSettings {
  const NotificationSettings({
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

  static const String categoryLiveEvents = 'LIVE_EVENT';
  static const String categoryFavorites = 'FAVORITE';
  static const String categoryComments = 'COMMENT';
  static const String categoryFollowingPost = 'FOLLOWING_POST';

  bool get liveEventsEnabled => _hasCategory(categories, categoryLiveEvents);
  bool get favoritesEnabled => _hasCategory(categories, categoryFavorites);
  bool get commentsEnabled => _hasCategory(categories, categoryComments);
  bool get followingPostsEnabled =>
      _hasCategory(categories, categoryFollowingPost);

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    List<String>? categories,
    int? version,
    DateTime? updatedAt,
    bool? liveEventsEnabled,
    bool? favoritesEnabled,
    bool? commentsEnabled,
    bool? followingPostsEnabled,
  }) {
    final updatedCategories = categories ?? List<String>.from(this.categories);

    if (liveEventsEnabled != null) {
      _toggleCategory(updatedCategories, categoryLiveEvents, liveEventsEnabled);
    }
    if (favoritesEnabled != null) {
      _toggleCategory(updatedCategories, categoryFavorites, favoritesEnabled);
    }
    if (commentsEnabled != null) {
      _toggleCategory(updatedCategories, categoryComments, commentsEnabled);
    }
    if (followingPostsEnabled != null) {
      _toggleCategory(
        updatedCategories,
        categoryFollowingPost,
        followingPostsEnabled,
      );
    }

    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      categories: updatedCategories,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationSettings.initial() {
    return const NotificationSettings(
      pushEnabled: true,
      emailEnabled: true,
      categories: <String>[
        categoryLiveEvents,
        categoryFavorites,
        categoryComments,
        categoryFollowingPost,
      ],
    );
  }
}

bool _hasCategory(List<String> categories, String target) {
  return categories.any((value) => value.toUpperCase() == target);
}

void _toggleCategory(List<String> categories, String target, bool enabled) {
  final existingIndex = categories.indexWhere(
    (value) => value.toUpperCase() == target,
  );
  if (enabled) {
    if (existingIndex == -1) {
      categories.add(target);
    }
    return;
  }
  if (existingIndex != -1) {
    categories.removeAt(existingIndex);
  }
}
