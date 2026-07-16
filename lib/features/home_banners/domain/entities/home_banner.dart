/// EN: Domain entity for a home page banner slide.
/// KO: 홈페이지 배너 슬라이드의 도메인 엔티티.
library;

/// EN: Action type when tapping a home banner.
/// KO: 홈 배너를 탭했을 때 동작 유형.
enum HomeBannerActionType {
  /// EN: Open an internal app route.
  /// KO: 앱 내부 라우트를 엽니다.
  internalRoute,

  /// EN: Open an external URL in the browser.
  /// KO: 브라우저에서 외부 URL을 엽니다.
  externalUrl,

  /// EN: No action.
  /// KO: 동작 없음.
  none;

  /// EN: Converts a raw string from the API into the enum value.
  /// KO: API에서 전달된 원시 문자열을 열거형 값으로 변환합니다.
  static HomeBannerActionType fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'internal_route' || 'internalroute' => HomeBannerActionType.internalRoute,
      'external_url' || 'externalurl' => HomeBannerActionType.externalUrl,
      _ => HomeBannerActionType.none,
    };
  }
}

/// EN: A single slide in the home page banner carousel.
/// KO: 홈 페이지 배너 캐러셀의 단일 슬라이드.
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.actionType = HomeBannerActionType.none,
    this.actionValue,
    this.sortOrder = 0,
  });

  /// EN: Unique identifier.
  /// KO: 고유 식별자.
  final String id;

  /// EN: Full-resolution image URL for the banner.
  /// KO: 배너의 전체 해상도 이미지 URL.
  final String imageUrl;

  /// EN: Optional overlay title text.
  /// KO: 선택적 오버레이 제목 텍스트.
  final String? title;

  /// EN: Optional overlay subtitle text.
  /// KO: 선택적 오버레이 부제목 텍스트.
  final String? subtitle;

  /// EN: What happens when the user taps the banner.
  /// KO: 사용자가 배너를 탭했을 때 동작.
  final HomeBannerActionType actionType;

  /// EN: The route path or URL for the action.
  /// KO: 동작에 사용할 라우트 경로 또는 URL.
  final String? actionValue;

  /// EN: Display order (lower = earlier).
  /// KO: 표시 순서 (낮을수록 앞에 표시).
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeBanner && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
