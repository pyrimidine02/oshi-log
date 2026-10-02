/// EN: Domain entities for the profile banner customization feature.
/// KO: 프로필 배너 커스터마이징 기능의 도메인 엔티티.
library;

/// EN: Rarity tier of a banner item.
/// KO: 배너 아이템의 희귀도 등급.
enum BannerRarity {
  /// EN: Common — freely available or low-effort unlock.
  /// KO: 일반 — 자유롭게 사용 가능하거나 낮은 난이도로 해금.
  common,

  /// EN: Rare — requires moderate achievement.
  /// KO: 레어 — 중간 정도의 달성이 필요.
  rare,

  /// EN: Epic — requires significant achievement.
  /// KO: 에픽 — 상당한 달성이 필요.
  epic,

  /// EN: Legendary — highest tier achievement reward.
  /// KO: 레전더리 — 최고 등급 달성 보상.
  legendary;

  /// EN: Parses a raw string value (case-insensitive) into [BannerRarity].
  /// KO: 원시 문자열(대소문자 무관)을 [BannerRarity]로 변환합니다.
  static BannerRarity fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'rare' => BannerRarity.rare,
      'epic' => BannerRarity.epic,
      'legendary' => BannerRarity.legendary,
      _ => BannerRarity.common,
    };
  }
}

/// EN: How a banner is unlocked.
/// KO: 배너 해금 방법.
enum BannerUnlockType {
  /// EN: Default banner available to all users.
  /// KO: 모든 사용자에게 제공되는 기본 배너.
  defaultBanner,

  /// EN: Unlocked by reaching a certain tier level.
  /// KO: 특정 티어에 도달하면 해금.
  tier,

  /// EN: Unlocked by earning a specific title/achievement.
  /// KO: 특정 칭호/업적 달성 시 해금.
  title,

  /// EN: Unlocked during a limited-time event.
  /// KO: 한정 이벤트 기간 중 해금.
  event,

  /// EN: Granted by admin.
  /// KO: 관리자가 직접 부여.
  adminGrant;

  /// EN: Parses a raw string value (case-insensitive) into [BannerUnlockType].
  /// KO: 원시 문자열(대소문자 무관)을 [BannerUnlockType]로 변환합니다.
  static BannerUnlockType fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'tier' => BannerUnlockType.tier,
      'title' => BannerUnlockType.title,
      'event' => BannerUnlockType.event,
      'admingrant' || 'admin_grant' => BannerUnlockType.adminGrant,
      _ => BannerUnlockType.defaultBanner,
    };
  }
}

/// EN: A single banner item from the catalog, including unlock state.
/// KO: 카탈로그의 단일 배너 아이템 (해금 상태 포함).
class BannerItem {
  const BannerItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.rarity,
    required this.unlockType,
    required this.isUnlocked,
    required this.isActive,
    this.unlockDescription,
  });

  /// EN: Unique identifier.
  /// KO: 고유 식별자.
  final String id;

  /// EN: Display name of the banner.
  /// KO: 배너의 표시 이름.
  final String name;

  /// EN: Full-resolution image URL.
  /// KO: 전체 해상도 이미지 URL.
  final String imageUrl;

  /// EN: Thumbnail URL for grid display.
  /// KO: 그리드 표시용 썸네일 URL.
  final String thumbnailUrl;

  /// EN: Rarity tier.
  /// KO: 희귀도 등급.
  final BannerRarity rarity;

  /// EN: How this banner is unlocked.
  /// KO: 배너 해금 방법.
  final BannerUnlockType unlockType;

  /// EN: Human-readable description of the unlock requirement.
  /// KO: 해금 조건에 대한 사람이 읽을 수 있는 설명.
  final String? unlockDescription;

  /// EN: Whether the current user has unlocked this banner.
  /// KO: 현재 사용자가 이 배너를 해금했는지 여부.
  final bool isUnlocked;

  /// EN: Whether this is the user's currently active banner.
  /// KO: 현재 사용자가 활성화한 배너인지 여부.
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BannerItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BannerItem(id: $id, name: $name, rarity: $rarity)';
}

/// EN: The currently active banner for the authenticated user.
///     All fields are nullable because the user may not have set a banner.
/// KO: 인증된 사용자의 현재 활성 배너.
///     사용자가 배너를 설정하지 않았을 수 있으므로 모든 필드가 nullable입니다.
class ActiveBanner {
  const ActiveBanner({
    this.bannerId,
    this.imageUrl,
    this.thumbnailUrl,
    this.name,
  });

  /// EN: The id of the active banner, or null if no banner is set.
  /// KO: 활성 배너의 ID. 배너가 설정되지 않은 경우 null.
  final String? bannerId;

  /// EN: Full-resolution image URL.
  /// KO: 전체 해상도 이미지 URL.
  final String? imageUrl;

  /// EN: Thumbnail URL.
  /// KO: 썸네일 URL.
  final String? thumbnailUrl;

  /// EN: Display name of the active banner.
  /// KO: 활성 배너의 표시 이름.
  final String? name;

  /// EN: Convenience getter — true when a banner is set.
  /// KO: 편의 게터 — 배너가 설정된 경우 true.
  bool get hasBanner => bannerId != null && bannerId!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveBanner &&
          runtimeType == other.runtimeType &&
          bannerId == other.bannerId;

  @override
  int get hashCode => bannerId.hashCode;

  @override
  String toString() => 'ActiveBanner(bannerId: $bannerId, name: $name)';
}
