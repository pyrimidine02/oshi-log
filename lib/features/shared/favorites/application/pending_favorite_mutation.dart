/// EN: Offline pending mutation model for favorites toggle sync.
/// KO: 즐겨찾기 토글 동기화를 위한 오프라인 대기 작업 모델입니다.
library;

import 'package:oshi_log/features/shared/favorites/domain/entities/favorite_entities.dart';

class PendingFavoriteMutation {
  const PendingFavoriteMutation({
    required this.entityId,
    required this.type,
    required this.isFavorite,
    required this.queuedAt,
  });

  final String entityId;
  final FavoriteType type;
  final bool isFavorite;
  final DateTime queuedAt;

  factory PendingFavoriteMutation.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').toLowerCase();
    return PendingFavoriteMutation(
      entityId: json['entityId'] as String? ?? '',
      type: _typeFromRaw(rawType),
      isFavorite: json['isFavorite'] as bool? ?? false,
      queuedAt:
          DateTime.tryParse(json['queuedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'type': type.name,
      'isFavorite': isFavorite,
      'queuedAt': queuedAt.toIso8601String(),
    };
  }
}

FavoriteType _typeFromRaw(String raw) {
  return switch (raw) {
    'place' => FavoriteType.place,
    'liveevent' => FavoriteType.liveEvent,
    'news' => FavoriteType.news,
    'post' => FavoriteType.post,
    _ => FavoriteType.unknown,
  };
}
