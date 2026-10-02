/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/search_discovery_dto.dart';
import '../dto/search_item_dto.dart';
import '../../domain/entities/search_entities.dart';

extension SearchItemDtoDomainMapper on SearchItemDto {
  SearchItem toDomain({String? projectId}) {
    final dto = this;

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

extension SearchPopularKeywordDtoDomainMapper on SearchPopularKeywordDto {
  SearchPopularKeyword toDomain() {
    final dto = this;

    return SearchPopularKeyword(keyword: dto.keyword, score: dto.score);
  }
}

extension SearchPopularDiscoveryDtoDomainMapper on SearchPopularDiscoveryDto {
  SearchPopularDiscovery toDomain() {
    final dto = this;

    return SearchPopularDiscovery(
      updatedAt: dto.updatedAt,
      popularKeywords: List.unmodifiable(
        dto.popularKeywords
            .map((value) => value.toDomain())
            .toList(growable: false),
      ),
    );
  }
}

extension SearchDiscoveryCategoryDtoDomainMapper on SearchDiscoveryCategoryDto {
  SearchDiscoveryCategory toDomain() {
    final dto = this;

    return SearchDiscoveryCategory(
      code: dto.code,
      label: dto.label,
      contentCount: dto.contentCount,
    );
  }
}

extension SearchCategoryDiscoveryDtoDomainMapper on SearchCategoryDiscoveryDto {
  SearchCategoryDiscovery toDomain() {
    final dto = this;

    return SearchCategoryDiscovery(
      updatedAt: dto.updatedAt,
      categories: List.unmodifiable(
        dto.categories.map((value) => value.toDomain()).toList(),
      ),
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
