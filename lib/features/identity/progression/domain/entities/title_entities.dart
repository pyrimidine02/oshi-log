/// EN: Domain entities for the title (칭호) system feature.
/// KO: 칭호(Title) 시스템 기능의 도메인 엔티티.
library;

/// EN: Category that classifies how a title is obtained.
///     Maps to the raw API strings ACTIVITY / COMMEMORATIVE / EVENT / ADMIN.
/// KO: 칭호 취득 방식을 분류하는 카테고리.
///     API 원시 문자열 ACTIVITY / COMMEMORATIVE / EVENT / ADMIN 에 대응합니다.
enum TitleCategory {
  /// EN: Earned through in-app activities (check-ins, visits, etc.).
  /// KO: 앱 내 활동(체크인, 방문 등)을 통해 획득.
  activity,

  /// EN: Commemorative titles for special milestones or anniversaries.
  /// KO: 특별한 마일스톤 또는 기념일을 위한 기념 칭호.
  commemorative,

  /// EN: Granted during a limited-time event period.
  /// KO: 한정 이벤트 기간 중 부여되는 칭호.
  event,

  /// EN: Manually assigned by an administrator.
  /// KO: 관리자가 수동으로 부여하는 칭호.
  admin;

  /// EN: Parses a raw API string (case-insensitive) into [TitleCategory].
  ///     Falls back to [TitleCategory.activity] for unrecognised values.
  /// KO: API 원시 문자열(대소문자 무관)을 [TitleCategory]로 변환합니다.
  ///     인식할 수 없는 값은 [TitleCategory.activity]로 폴백됩니다.
  static TitleCategory fromString(String? raw) {
    return switch (raw?.toUpperCase()) {
      'COMMEMORATIVE' => TitleCategory.commemorative,
      'EVENT' => TitleCategory.event,
      'ADMIN' => TitleCategory.admin,
      _ => TitleCategory.activity,
    };
  }
}

/// EN: A single item in the title catalog, representing one obtainable title
///     together with its earned/active state for the current user.
///     [isEarned] and [isActive] are null when the caller is unauthenticated.
/// KO: 칭호 카탈로그의 단일 항목. 획득 가능한 칭호 하나와 현재 사용자의
///     획득/활성 상태를 함께 나타냅니다.
///     비인증 상태에서는 [isEarned] 와 [isActive] 가 null 입니다.
class TitleCatalogItem {
  const TitleCatalogItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.sortOrder,
    this.description,
    this.projectId,
    this.isEarned,
    this.isActive,
  });

  /// EN: Unique server-side identifier for this title.
  /// KO: 이 칭호의 서버 측 고유 식별자.
  final String id;

  /// EN: Short machine-readable code (e.g. `"FIRST_VISIT"`).
  /// KO: 짧은 기계 판독 가능 코드 (예: `"FIRST_VISIT"`).
  final String code;

  /// EN: Human-readable display name of the title.
  /// KO: 칭호의 사람이 읽을 수 있는 표시 이름.
  final String name;

  /// EN: Optional longer description of how the title is obtained.
  /// KO: 칭호 획득 방법에 대한 선택적 상세 설명.
  final String? description;

  /// EN: Category that groups this title by its unlock mechanism.
  /// KO: 해금 메커니즘 기준으로 칭호를 묶는 카테고리.
  final TitleCategory category;

  /// EN: Project-scoped identifier.
  ///     null means the title is common across all projects;
  ///     non-null restricts it to the specific project.
  /// KO: 프로젝트 범위 식별자.
  ///     null 이면 전체 프로젝트 공통 칭호,
  ///     non-null 이면 해당 프로젝트 전용 칭호입니다.
  final String? projectId;

  /// EN: Display order within the catalog. Lower values appear first.
  /// KO: 카탈로그 내 표시 순서. 낮은 값이 먼저 표시됩니다.
  final int sortOrder;

  /// EN: Whether the current user has earned this title.
  ///     null when the user is unauthenticated.
  /// KO: 현재 사용자가 이 칭호를 획득했는지 여부.
  ///     비인증 상태에서는 null 입니다.
  final bool? isEarned;

  /// EN: Whether this title is currently active for the user.
  ///     null when the user is unauthenticated.
  /// KO: 현재 이 칭호가 사용자에게 활성화되어 있는지 여부.
  ///     비인증 상태에서는 null 입니다.
  final bool? isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleCatalogItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TitleCatalogItem(id: $id, code: $code, name: $name, '
      'category: $category, sortOrder: $sortOrder)';
}

/// EN: The currently active title for a user.
///     An empty [titleId] means no title is set (use [hasTitle] to check).
/// KO: 사용자의 현재 활성 칭호.
///     [titleId] 가 빈 문자열이면 칭호가 설정되지 않은 상태입니다
///     ([hasTitle] 로 확인하세요).
class ActiveTitleItem {
  const ActiveTitleItem({
    required this.titleId,
    required this.code,
    required this.name,
    required this.category,
    this.description,
  });

  /// EN: Unique identifier of the active title.
  ///     Empty string indicates no title is currently set.
  /// KO: 활성 칭호의 고유 식별자.
  ///     빈 문자열은 현재 칭호가 설정되지 않음을 나타냅니다.
  final String titleId;

  /// EN: Short machine-readable code of the active title.
  /// KO: 활성 칭호의 짧은 기계 판독 가능 코드.
  final String code;

  /// EN: Human-readable display name of the active title.
  /// KO: 활성 칭호의 사람이 읽을 수 있는 표시 이름.
  final String name;

  /// EN: Optional description of the active title.
  /// KO: 활성 칭호의 선택적 설명.
  final String? description;

  /// EN: Category of the active title.
  /// KO: 활성 칭호의 카테고리.
  final TitleCategory category;

  /// EN: Convenience getter — true when a title is currently set.
  /// KO: 편의 게터 — 현재 칭호가 설정된 경우 true.
  bool get hasTitle => titleId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveTitleItem &&
          runtimeType == other.runtimeType &&
          titleId == other.titleId;

  @override
  int get hashCode => titleId.hashCode;

  @override
  String toString() =>
      'ActiveTitleItem(titleId: $titleId, code: $code, name: $name, '
      'category: $category)';
}
