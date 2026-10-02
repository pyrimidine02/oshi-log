/// EN: Discovery DTOs for unified search home sections.
/// KO: 통합검색 홈 섹션용 Discovery DTO입니다.
library;

class SearchPopularKeywordDto {
  const SearchPopularKeywordDto({required this.keyword, required this.score});

  final String keyword;
  final num score;

  factory SearchPopularKeywordDto.fromJson(Map<String, dynamic> json) {
    final keyword = _asString(json['keyword']) ?? '';
    return SearchPopularKeywordDto(
      keyword: keyword,
      score: _asNum(json['score']) ?? 0,
    );
  }
}

class SearchPopularDiscoveryDto {
  const SearchPopularDiscoveryDto({
    required this.updatedAt,
    required this.popularKeywords,
  });

  final DateTime? updatedAt;
  final List<SearchPopularKeywordDto> popularKeywords;

  factory SearchPopularDiscoveryDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['popularKeywords'];
    final popularKeywords = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SearchPopularKeywordDto.fromJson)
              .toList()
        : const <SearchPopularKeywordDto>[];
    return SearchPopularDiscoveryDto(
      updatedAt: _asDateTime(json['updatedAt']),
      popularKeywords: popularKeywords,
    );
  }
}

class SearchDiscoveryCategoryDto {
  const SearchDiscoveryCategoryDto({
    required this.code,
    required this.label,
    required this.contentCount,
  });

  final String code;
  final String label;
  final int contentCount;

  factory SearchDiscoveryCategoryDto.fromJson(Map<String, dynamic> json) {
    return SearchDiscoveryCategoryDto(
      code: _asString(json['code']) ?? '',
      label: _asString(json['label']) ?? '',
      contentCount: (_asNum(json['contentCount']) ?? 0).toInt(),
    );
  }
}

class SearchCategoryDiscoveryDto {
  const SearchCategoryDiscoveryDto({
    required this.updatedAt,
    required this.categories,
  });

  final DateTime? updatedAt;
  final List<SearchDiscoveryCategoryDto> categories;

  factory SearchCategoryDiscoveryDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['categories'];
    final categories = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SearchDiscoveryCategoryDto.fromJson)
              .toList()
        : const <SearchDiscoveryCategoryDto>[];
    return SearchCategoryDiscoveryDto(
      updatedAt: _asDateTime(json['updatedAt']),
      categories: categories,
    );
  }
}

String? _asString(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

num? _asNum(dynamic value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
