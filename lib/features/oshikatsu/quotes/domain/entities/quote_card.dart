/// EN: Domain entities for anime quote cards.
/// KO: 애니메이션 명대사 카드의 도메인 엔티티.
library;

/// EN: A single anime quote card.
/// KO: 단일 애니메이션 명대사 카드.
class QuoteCard {
  const QuoteCard({
    required this.id,
    required this.quoteText,
    required this.characterName,
    this.episodeContext,
    this.animeTitle,
    this.projectId,
    this.characterImageUrl,
    this.backgroundHexColor,
    this.backgroundGradientColors = const [],
    this.likeCount = 0,
    this.isLiked = false,
    this.tags = const [],
  });

  final String id;

  /// EN: The quote text (may be multi-line).
  /// KO: 명대사 텍스트 (여러 줄일 수 있음).
  final String quoteText;

  /// EN: Name of the character who said the quote.
  /// KO: 명대사를 말한 캐릭터 이름.
  final String characterName;

  /// EN: Episode or scene context (e.g. "Episode 8, final scene").
  /// KO: 에피소드 또는 장면 맥락 (예: "8화 마지막 장면").
  final String? episodeContext;

  final String? animeTitle;
  final String? projectId;
  final String? characterImageUrl;

  /// EN: Background hex color for the card (e.g. "#6366F1").
  /// KO: 카드 배경 16진수 색상 (예: "#6366F1").
  final String? backgroundHexColor;

  /// EN: Background gradient hex color list (2+ colors).
  /// KO: 배경 그라디언트 16진수 색상 목록 (2개 이상).
  final List<String> backgroundGradientColors;

  final int likeCount;
  final bool isLiked;
  final List<String> tags;

  /// EN: Returns a copy of this quote with optional field overrides.
  /// KO: 선택적 필드 오버라이드를 포함한 복사본을 반환합니다.
  QuoteCard copyWith({bool? isLiked, int? likeCount}) => QuoteCard(
    id: id,
    quoteText: quoteText,
    characterName: characterName,
    episodeContext: episodeContext,
    animeTitle: animeTitle,
    projectId: projectId,
    characterImageUrl: characterImageUrl,
    backgroundHexColor: backgroundHexColor,
    backgroundGradientColors: backgroundGradientColors,
    likeCount: likeCount ?? this.likeCount,
    isLiked: isLiked ?? this.isLiked,
    tags: tags,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
