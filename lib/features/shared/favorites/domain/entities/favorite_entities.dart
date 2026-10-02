/// EN: Favorite domain entities.
/// KO: 즐겨찾기 도메인 엔티티.
library;

enum FavoriteType { place, liveEvent, news, post, unknown }

class FavoriteItem {
  const FavoriteItem({
    required this.entityId,
    required this.type,
    this.projectCode,
    this.title,
    this.thumbnailUrl,
  });

  final String entityId;
  final FavoriteType type;
  final String? projectCode;
  final String? title;
  final String? thumbnailUrl;
}
