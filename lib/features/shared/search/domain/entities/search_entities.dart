/// EN: Search domain entities for unified search.
/// KO: 통합 검색 도메인 엔티티.
library;

import 'package:intl/intl.dart';

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
}

class SearchPopularKeyword {
  const SearchPopularKeyword({required this.keyword, required this.score});

  final String keyword;
  final num score;
}

class SearchPopularDiscovery {
  const SearchPopularDiscovery({
    required this.updatedAt,
    required this.popularKeywords,
  });

  final DateTime? updatedAt;
  final List<SearchPopularKeyword> popularKeywords;
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
}

class SearchCategoryDiscovery {
  const SearchCategoryDiscovery({
    required this.updatedAt,
    required this.categories,
  });

  final DateTime? updatedAt;
  final List<SearchDiscoveryCategory> categories;
}
