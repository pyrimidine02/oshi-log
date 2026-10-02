/// EN: DTOs for community on-demand translation endpoint.
/// KO: 커뮤니티 요청형 번역 엔드포인트 DTO입니다.
library;

/// EN: Request DTO for `POST /api/v1/community/translations`.
/// KO: `POST /api/v1/community/translations` 요청 DTO입니다.
class CommunityTranslationRequestDto {
  const CommunityTranslationRequestDto({
    required this.text,
    required this.targetLanguage,
    this.sourceLanguage,
  });

  final String text;
  final String targetLanguage;
  final String? sourceLanguage;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'targetLanguage': targetLanguage,
      if (sourceLanguage != null && sourceLanguage!.trim().isNotEmpty)
        'sourceLanguage': sourceLanguage,
    };
  }
}

/// EN: Response DTO for community translation result.
/// KO: 커뮤니티 번역 결과 응답 DTO입니다.
class CommunityTranslationDto {
  const CommunityTranslationDto({
    required this.originalText,
    required this.translatedText,
    required this.targetLanguage,
    required this.translated,
    this.sourceLanguage,
  });

  final String originalText;
  final String translatedText;
  final String? sourceLanguage;
  final String targetLanguage;
  final bool translated;

  factory CommunityTranslationDto.fromJson(Map<String, dynamic> json) {
    return CommunityTranslationDto(
      originalText: json['originalText'] as String? ?? '',
      translatedText: json['translatedText'] as String? ?? '',
      sourceLanguage: json['sourceLanguage'] as String?,
      targetLanguage: json['targetLanguage'] as String? ?? '',
      translated: json['translated'] as bool? ?? false,
    );
  }
}
