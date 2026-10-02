/// EN: Utilities for matching and labeling place types in search UI.
/// KO: 검색 UI에서 장소 유형 매칭/라벨링에 사용하는 유틸리티입니다.
library;

const Map<String, List<String>> _placeTypeSynonyms = {
  'filming location': ['촬영지', '성지', '성지순례지'],
  'anime location': ['촬영지', '성지'],
  'live house': ['라이브하우스', '공연장'],
  'concert hall': ['공연장', '콘서트홀'],
  'station': ['역', '기차역', '지하철역'],
  'landmark': ['명소', '랜드마크'],
  'shop': ['상점', '매장', '굿즈샵'],
  'store': ['상점', '매장', '굿즈샵'],
  'restaurant': ['식당', '음식점', '레스토랑'],
  'cafe': ['카페'],
  'school': ['학교'],
  'park': ['공원'],
  'street': ['거리'],
  'studio': ['스튜디오'],
  'temple': ['사찰', '신사'],
  'shrine': ['신사', '사찰'],
  'bridge': ['다리', '교량'],
  'other': ['기타'],
};

/// EN: Normalizes free-text for case-insensitive place search.
/// KO: 대소문자/구분자에 영향받지 않도록 장소 검색 텍스트를 정규화합니다.
String normalizePlaceSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// EN: Returns true when `source` contains `query` after normalization.
/// KO: 정규화 기준으로 `source`가 `query`를 포함하면 true를 반환합니다.
bool normalizedContains(String source, String query) {
  final normalizedSource = normalizePlaceSearchText(source);
  final normalizedQuery = normalizePlaceSearchText(query);
  if (normalizedQuery.isEmpty) return false;
  if (normalizedSource.contains(normalizedQuery)) return true;

  final compactSource = normalizedSource.replaceAll(' ', '');
  final compactQuery = normalizedQuery.replaceAll(' ', '');
  return compactQuery.isNotEmpty && compactSource.contains(compactQuery);
}

/// EN: Expands raw place types into searchable keywords.
/// KO: 원본 장소 유형 목록을 검색 가능한 키워드 집합으로 확장합니다.
Set<String> buildPlaceTypeSearchKeywords(List<String> types) {
  final keywords = <String>{};

  for (final type in types) {
    final raw = type.trim();
    if (raw.isEmpty) continue;

    final normalized = normalizePlaceSearchText(raw);
    if (normalized.isEmpty) continue;

    keywords
      ..add(raw.toLowerCase())
      ..add(normalized)
      ..add(normalized.replaceAll(' ', ''));

    for (final token in normalized.split(' ')) {
      if (token.isNotEmpty) keywords.add(token);
    }

    final synonyms = _placeTypeSynonyms[normalized] ?? const <String>[];
    for (final synonym in synonyms) {
      final normalizedSynonym = normalizePlaceSearchText(synonym);
      if (normalizedSynonym.isEmpty) continue;
      keywords
        ..add(normalizedSynonym)
        ..add(normalizedSynonym.replaceAll(' ', ''));
    }
  }

  return keywords;
}

/// EN: Returns true when query matches any place type keyword.
/// KO: 검색어가 장소 유형 키워드와 일치하면 true를 반환합니다.
bool matchesPlaceTypeQuery({
  required String query,
  required List<String> types,
}) {
  final keywords = buildPlaceTypeSearchKeywords(types);
  if (keywords.isEmpty) return false;

  for (final keyword in keywords) {
    if (normalizedContains(keyword, query)) {
      return true;
    }
  }
  return false;
}

/// EN: Formats a raw place type to user-facing text.
/// KO: 원본 장소 유형 문자열을 사용자 표시용 텍스트로 변환합니다.
String placeTypeLabel(String rawType) {
  final normalized = normalizePlaceSearchText(rawType);
  if (normalized.isEmpty) return '';
  final aliases = _placeTypeSynonyms[normalized];
  if (aliases != null && aliases.isNotEmpty) {
    return aliases.first;
  }
  return normalized
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(_capitalize)
      .join(' ');
}

String _capitalize(String word) {
  if (word.isEmpty) return word;
  if (word.length == 1) return word.toUpperCase();
  return '${word[0].toUpperCase()}${word.substring(1)}';
}
