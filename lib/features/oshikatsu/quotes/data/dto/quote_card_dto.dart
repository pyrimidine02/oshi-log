/// EN: DTOs for quote card API responses.
/// KO: 명대사 카드 API 응답의 DTO.
library;

import 'package:oshi_log/features/oshikatsu/quotes/domain/entities/quote_card.dart';

/// EN: Data Transfer Object for a single quote card.
/// KO: 단일 명대사 카드 데이터 전송 객체.
class QuoteCardDto {
  const QuoteCardDto({
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

  /// EN: Deserialises from JSON, tolerating both camelCase and snake_case keys.
  /// KO: camelCase와 snake_case 키를 모두 허용하며 JSON에서 역직렬화합니다.
  factory QuoteCardDto.fromJson(Map<String, dynamic> json) {
    final gradients =
        json['backgroundGradientColors'] as List<dynamic>? ??
        json['background_gradient_colors'] as List<dynamic>? ??
        [];
    final tags = json['tags'] as List<dynamic>? ?? [];
    return QuoteCardDto(
      id: json['id'] as String? ?? '',
      quoteText:
          json['quoteText'] as String? ?? json['quote_text'] as String? ?? '',
      characterName:
          json['characterName'] as String? ??
          json['character_name'] as String? ??
          '',
      episodeContext:
          json['episodeContext'] as String? ??
          json['episode_context'] as String?,
      animeTitle:
          json['animeTitle'] as String? ?? json['anime_title'] as String?,
      projectId: json['projectId'] as String? ?? json['project_id'] as String?,
      characterImageUrl:
          json['characterImageUrl'] as String? ??
          json['character_image_url'] as String?,
      backgroundHexColor:
          json['backgroundHexColor'] as String? ??
          json['background_hex_color'] as String?,
      backgroundGradientColors: gradients.cast<String>(),
      likeCount: json['likeCount'] as int? ?? json['like_count'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? json['is_liked'] as bool? ?? false,
      tags: tags.cast<String>(),
    );
  }

  final String id;
  final String quoteText;
  final String characterName;
  final String? episodeContext;
  final String? animeTitle;
  final String? projectId;
  final String? characterImageUrl;
  final String? backgroundHexColor;
  final List<String> backgroundGradientColors;
  final int likeCount;
  final bool isLiked;
  final List<String> tags;

  /// EN: Maps this DTO to the domain [QuoteCard] entity.
  /// KO: 이 DTO를 도메인 [QuoteCard] 엔티티로 매핑합니다.
  QuoteCard toEntity() => QuoteCard(
    id: id,
    quoteText: quoteText,
    characterName: characterName,
    episodeContext: episodeContext,
    animeTitle: animeTitle,
    projectId: projectId,
    characterImageUrl: characterImageUrl,
    backgroundHexColor: backgroundHexColor,
    backgroundGradientColors: backgroundGradientColors,
    likeCount: likeCount,
    isLiked: isLiked,
    tags: tags,
  );
}
