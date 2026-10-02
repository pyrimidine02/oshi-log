/// EN: Remote data source for home summary.
/// KO: 홈 요약용 원격 데이터 소스.
library;

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/utils/result.dart';
import '../dto/home_summary_dto.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<HomeSummaryDto>> fetchSummary({
    required String projectId,
    List<String> unitIds = const [],
  }) {
    return _apiClient.get<HomeSummaryDto>(
      ApiEndpoints.homeSummary,
      queryParameters: {
        'projectId': projectId,
        if (unitIds.isNotEmpty) 'unitIds': unitIds,
      },
      fromJson: (json) => HomeSummaryDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<List<HomeSummaryByProjectItemDto>>> fetchSummaryByProject({
    List<String> projectIds = const [],
    List<String> unitIds = const [],
  }) {
    return _apiClient.get<List<HomeSummaryByProjectItemDto>>(
      ApiEndpoints.homeSummaryByProject,
      queryParameters: {
        if (projectIds.isNotEmpty) 'projectIds': projectIds.join(','),
        if (unitIds.isNotEmpty) 'unitIds': unitIds.join(','),
      },
      fromJson: (json) {
        if (json is! List) {
          return const <HomeSummaryByProjectItemDto>[];
        }
        return json
            .whereType<Map<String, dynamic>>()
            .map(HomeSummaryByProjectItemDto.fromJson)
            .toList(growable: false);
      },
    );
  }

  /// EN: Fetch live-event poster URL from the live detail endpoint.
  /// KO: 라이브 상세 엔드포인트에서 포스터 URL을 조회합니다.
  Future<Result<String?>> fetchLiveEventPosterUrl({
    required String projectId,
    required String eventId,
  }) {
    return _apiClient.get<String?>(
      ApiEndpoints.liveEvent(projectId, eventId),
      fromJson: (json) {
        if (json is! Map<String, dynamic>) {
          return null;
        }
        return _extractLivePosterUrl(json);
      },
    );
  }
}

String? _extractLivePosterUrl(Map<String, dynamic> json) {
  return _firstNonEmptyString([
    json['bannerUrl'],
    json['banner_url'],
    json['posterUrl'],
    json['poster_url'],
    json['posterImageUrl'],
    json['poster_image_url'],
    json['coverImageUrl'],
    json['cover_image_url'],
    json['imageUrl'],
    json['image_url'],
    json['thumbnailUrl'],
    json['thumbnail_url'],
    _nestedString(json['banner'], 'url'),
    _nestedString(json['banner'], 'publicUrl'),
    _nestedString(json['banner'], 'fileUrl'),
    _nestedString(json['poster'], 'url'),
    _nestedString(json['poster'], 'publicUrl'),
    _nestedString(json['poster'], 'fileUrl'),
    _nestedString(json['thumbnail'], 'url'),
    _nestedString(json['image'], 'url'),
    _nestedPathString(json, ['banner', 'file', 'url']),
    _nestedPathString(json, ['banner', 'file', 'publicUrl']),
    _nestedPathString(json, ['poster', 'file', 'url']),
    _nestedPathString(json, ['poster', 'file', 'publicUrl']),
    _nestedPathString(json, ['media', 'banner', 'url']),
    _nestedPathString(json, ['media', 'poster', 'url']),
    _nestedPathString(json, ['images', 'banner', 'url']),
    _nestedPathString(json, ['images', 'poster', 'url']),
  ]);
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final value = _string(candidate);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _string(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

String? _nestedString(dynamic raw, String key) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }
  return _string(raw[key]);
}

String? _nestedPathString(Map<String, dynamic> root, List<String> path) {
  dynamic cursor = root;
  for (final segment in path) {
    if (cursor is! Map<String, dynamic>) {
      return null;
    }
    cursor = cursor[segment];
  }
  return _string(cursor);
}
