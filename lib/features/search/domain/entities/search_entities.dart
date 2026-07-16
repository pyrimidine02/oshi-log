/// EN: Search domain entities for unified search.
/// KO: 통합 검색 도메인 엔티티.
library;

import 'package:intl/intl.dart';

import '../../data/dto/search_discovery_dto.dart';
import '../../data/dto/search_item_dto.dart';

enum SearchItemType {
  place,
  liveEvent,
  news,
  post,
  unit,
  project,
  voiceActor,
  artist,
  anime,
  user,
  unknown,
}

class SearchItem {
  const SearchItem({
    required this.id,
    required this.title,
    required this.type,
    required this.sourceId,
    this.subtitle,
    this.imageUrl,
    this.category,
    this.publishedAt,
    this.projectId,
    this.canonicalKey,
    this.navigationTargetType,
    this.navigationRoute,
  });

  final String id;
  final String title;
  final SearchItemType type;
  final String sourceId;
  final String? subtitle;
  final String? imageUrl;
  final String? category;
  final DateTime? publishedAt;
  final String? projectId;
  final String? canonicalKey;
  final String? navigationTargetType;
  final String? navigationRoute;

  String get dateLabel {
    if (publishedAt == null) return '';
    return DateFormat('yyyy.MM.dd').format(publishedAt!.toLocal());
  }

  String? get projectKey {
    if (type != SearchItemType.project) {
      return null;
    }
    const prefix = 'project:';
    final key = canonicalKey?.trim();
    if (key == null || !key.startsWith(prefix)) {
      return null;
    }
    final value = key.substring(prefix.length).trim();
    return value.isEmpty ? null : value;
  }

  factory SearchItem.fromDto(SearchItemDto dto, {String? projectId}) {
    final item = dto.item;
    final id = _string(item, ['id', 'itemId', 'targetId']) ?? '';
    final navigation = _stringMap(item['navigation']);
    final sourceId =
        _string(item, ['sourceId']) ?? _string(navigation, ['targetId']) ?? id;
    final title = _string(item, ['title', 'name', 'headline']) ?? '검색 결과';
    final subtitle = _string(item, ['subtitle', 'summary', 'description']);
    final imageUrl = _string(item, [
      'imageUrl',
      'thumbnailUrl',
      'bannerUrl',
      'image',
    ]);
    final category = _string(item, ['category', 'tag', 'group']) ?? dto.type;
    final publishedAt = _dateTime(item, ['publishedAt', 'createdAt', 'date']);

    return SearchItem(
      id: id,
      title: title,
      type: _mapType(dto.type, item),
      sourceId: sourceId,
      subtitle: subtitle,
      imageUrl: imageUrl,
      category: category,
      publishedAt: publishedAt,
      projectId: _string(item, ['projectId']) ?? projectId,
      canonicalKey: _string(item, ['canonicalKey']),
      navigationTargetType: _string(navigation, ['targetType']),
      navigationRoute: _string(navigation, ['route']),
    );
  }
}

SearchItemType _mapType(String? raw, Map<String, dynamic> item) {
  final value = raw?.toLowerCase() ?? '';
  if (value == 'fan_subject' || value == 'fan-subject') {
    return switch (_string(item, ['subjectType'])?.toUpperCase()) {
      'PROJECT' => SearchItemType.project,
      'UNIT' => SearchItemType.unit,
      'VOICE_ACTOR' => SearchItemType.voiceActor,
      'ARTIST' => SearchItemType.artist,
      'ANIME' => SearchItemType.anime,
      _ => SearchItemType.unknown,
    };
  }
  if (value == 'user' || value == 'users') {
    return SearchItemType.user;
  }
  if (value == 'places' ||
      value.contains('place') ||
      value.contains('location')) {
    return SearchItemType.place;
  }
  if (value.contains('live') || value.contains('event')) {
    return SearchItemType.liveEvent;
  }
  if (value.contains('news') || value.contains('article')) {
    return SearchItemType.news;
  }
  if (value.contains('post') || value.contains('community')) {
    return SearchItemType.post;
  }
  if (value.contains('unit') || value.contains('band')) {
    return SearchItemType.unit;
  }
  if (value.contains('voice_actor') || value.contains('voice-actor')) {
    return SearchItemType.voiceActor;
  }
  if (value.contains('artist') || value.contains('musician')) {
    return SearchItemType.artist;
  }
  if (value.contains('anime') || value.contains('animation')) {
    return SearchItemType.anime;
  }
  if (value.contains('project')) {
    return SearchItemType.project;
  }
  return SearchItemType.unknown;
}

Map<String, dynamic> _stringMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

class SearchPopularKeyword {
  const SearchPopularKeyword({required this.keyword, required this.score});

  final String keyword;
  final num score;

  factory SearchPopularKeyword.fromDto(SearchPopularKeywordDto dto) {
    return SearchPopularKeyword(keyword: dto.keyword, score: dto.score);
  }
}

class SearchPopularDiscovery {
  const SearchPopularDiscovery({
    required this.updatedAt,
    required this.popularKeywords,
  });

  final DateTime? updatedAt;
  final List<SearchPopularKeyword> popularKeywords;

  factory SearchPopularDiscovery.fromDto(SearchPopularDiscoveryDto dto) {
    return SearchPopularDiscovery(
      updatedAt: dto.updatedAt,
      popularKeywords: dto.popularKeywords
          .map(SearchPopularKeyword.fromDto)
          .toList(),
    );
  }
}

class SearchDiscoveryCategory {
  const SearchDiscoveryCategory({
    required this.code,
    required this.label,
    required this.contentCount,
  });

  final String code;
  final String label;
  final int contentCount;

  factory SearchDiscoveryCategory.fromDto(SearchDiscoveryCategoryDto dto) {
    return SearchDiscoveryCategory(
      code: dto.code,
      label: dto.label,
      contentCount: dto.contentCount,
    );
  }
}

class SearchCategoryDiscovery {
  const SearchCategoryDiscovery({
    required this.updatedAt,
    required this.categories,
  });

  final DateTime? updatedAt;
  final List<SearchDiscoveryCategory> categories;

  factory SearchCategoryDiscovery.fromDto(SearchCategoryDiscoveryDto dto) {
    return SearchCategoryDiscovery(
      updatedAt: dto.updatedAt,
      categories: dto.categories.map(SearchDiscoveryCategory.fromDto).toList(),
    );
  }
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

DateTime? _dateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
