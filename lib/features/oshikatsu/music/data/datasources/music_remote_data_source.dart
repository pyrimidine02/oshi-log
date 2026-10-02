/// EN: Remote data source for music information endpoints.
/// KO: 악곡 정보 엔드포인트용 원격 데이터 소스입니다.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/music/data/dto/music_dto.dart';

class MusicRemoteDataSource {
  MusicRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<MusicCursorPageDto<MusicAlbumSummaryDto>>> fetchAlbums({
    required String projectId,
    String? cursor,
    int size = 20,
  }) {
    return _apiClient.get<MusicCursorPageDto<MusicAlbumSummaryDto>>(
      ApiEndpoints.musicAlbums(projectId),
      queryParameters: {
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
        'size': size.clamp(1, 100),
      },
      fromJson: (json) =>
          MusicCursorPageDto.fromJson(json, MusicAlbumSummaryDto.fromJson),
    );
  }

  Future<Result<MusicAlbumDetailDto>> fetchAlbumDetail({
    required String projectId,
    required String albumId,
  }) {
    return _apiClient.get<MusicAlbumDetailDto>(
      ApiEndpoints.musicAlbum(projectId, albumId),
      fromJson: (json) =>
          MusicAlbumDetailDto.fromJson(_asMap(json) ?? const {}),
    );
  }

  Future<Result<MusicCursorPageDto<MusicSongSummaryDto>>> fetchSongs({
    required String projectId,
    String? cursor,
    int size = 20,
  }) {
    return _apiClient.get<MusicCursorPageDto<MusicSongSummaryDto>>(
      ApiEndpoints.musicSongs(projectId),
      queryParameters: {
        if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor.trim(),
        'size': size.clamp(1, 100),
      },
      fromJson: (json) =>
          MusicCursorPageDto.fromJson(json, MusicSongSummaryDto.fromJson),
    );
  }

  Future<Result<MusicSongDetailDto>> fetchSongDetail({
    required String projectId,
    required String songId,
  }) {
    return _apiClient.get<MusicSongDetailDto>(
      ApiEndpoints.musicSong(projectId, songId),
      fromJson: (json) => MusicSongDetailDto.fromJson(_asMap(json) ?? const {}),
    );
  }

  Future<Result<MusicLyricsPayloadDto>> fetchSongLyrics({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  }) {
    return _apiClient.get<MusicLyricsPayloadDto>(
      ApiEndpoints.musicSongLyrics(projectId, songId),
      queryParameters: {
        if (_nonBlank(lang) != null) 'lang': _nonBlank(lang),
        if (_nonBlank(version) != null) 'version': _nonBlank(version),
        'includeRomanized': includeRomanized,
        'includeTranslated': includeTranslated,
      },
      fromJson: MusicLyricsPayloadDto.fromJson,
    );
  }

  Future<Result<MusicPartsPayloadDto>> fetchSongParts({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  }) {
    return _apiClient.get<MusicPartsPayloadDto>(
      ApiEndpoints.musicSongParts(projectId, songId),
      queryParameters: {
        if (_nonBlank(lang) != null) 'lang': _nonBlank(lang),
        if (_nonBlank(version) != null) 'version': _nonBlank(version),
      },
      fromJson: MusicPartsPayloadDto.fromJson,
    );
  }

  Future<Result<MusicCallGuidePayloadDto>> fetchSongCallGuide({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  }) {
    return _apiClient.get<MusicCallGuidePayloadDto>(
      ApiEndpoints.musicSongCallGuide(projectId, songId),
      queryParameters: {
        if (_nonBlank(lang) != null) 'lang': _nonBlank(lang),
        if (_nonBlank(version) != null) 'version': _nonBlank(version),
      },
      fromJson: MusicCallGuidePayloadDto.fromJson,
    );
  }

  Future<Result<List<MusicSongVersionInfoDto>>> fetchSongVersions({
    required String projectId,
    required String songId,
  }) {
    return _apiClient.get<List<MusicSongVersionInfoDto>>(
      ApiEndpoints.musicSongVersions(projectId, songId),
      fromJson: (json) => _decodeList(
        json,
        MusicSongVersionInfoDto.fromJson,
        listKey: 'versions',
      ),
    );
  }

  Future<Result<MusicSongVersionInfoDto>> fetchSongVersionDetail({
    required String projectId,
    required String songId,
    required String versionCode,
  }) {
    return _apiClient.get<MusicSongVersionInfoDto>(
      ApiEndpoints.musicSongVersion(projectId, songId, versionCode),
      fromJson: (json) =>
          MusicSongVersionInfoDto.fromJson(_asMap(json) ?? const {}),
    );
  }

  Future<Result<List<MusicCreditGroupDto>>> fetchSongCredits({
    required String projectId,
    required String songId,
  }) {
    return _apiClient.get<List<MusicCreditGroupDto>>(
      ApiEndpoints.musicSongCredits(projectId, songId),
      fromJson: (json) =>
          _decodeList(json, MusicCreditGroupDto.fromJson, listKey: 'credits'),
    );
  }

  Future<Result<MusicDifficultyDto>> fetchSongDifficulty({
    required String projectId,
    required String songId,
  }) {
    return _apiClient.get<MusicDifficultyDto>(
      ApiEndpoints.musicSongDifficulty(projectId, songId),
      fromJson: MusicDifficultyDto.fromJson,
    );
  }

  Future<Result<MusicMediaLinksDto>> fetchSongMediaLinks({
    required String projectId,
    required String songId,
  }) {
    return _apiClient.get<MusicMediaLinksDto>(
      ApiEndpoints.musicSongMediaLinks(projectId, songId),
      fromJson: MusicMediaLinksDto.fromJson,
    );
  }

  Future<Result<MusicAvailabilityDto>> fetchSongAvailability({
    required String projectId,
    required String songId,
    String? country,
  }) {
    return _apiClient.get<MusicAvailabilityDto>(
      ApiEndpoints.musicSongAvailability(projectId, songId),
      queryParameters: {
        if (_nonBlank(country) != null) 'country': _nonBlank(country),
      },
      fromJson: MusicAvailabilityDto.fromJson,
    );
  }

  Future<Result<MusicSongLiveContextDto>> fetchSongLiveContext({
    required String projectId,
    required String songId,
    required String eventId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  }) {
    return _apiClient.get<MusicSongLiveContextDto>(
      ApiEndpoints.musicSongLiveContext(projectId, songId),
      queryParameters: {
        'eventId': eventId,
        if (_nonBlank(lang) != null) 'lang': _nonBlank(lang),
        if (_nonBlank(version) != null) 'version': _nonBlank(version),
        'includeRomanized': includeRomanized,
        'includeTranslated': includeTranslated,
      },
      fromJson: MusicSongLiveContextDto.fromJson,
    );
  }

  Future<Result<List<MusicSongPerformanceDto>>> fetchSongPerformances({
    required String projectId,
    required String songId,
    String? lang,
  }) {
    return _apiClient.get<List<MusicSongPerformanceDto>>(
      ApiEndpoints.musicSongPerformances(projectId, songId),
      queryParameters: {if (_nonBlank(lang) != null) 'lang': _nonBlank(lang)},
      fromJson: (json) => _decodeList(json, MusicSongPerformanceDto.fromJson),
    );
  }

  Future<Result<MusicLiveSetlistDto>> fetchLiveSetlist({
    required String projectId,
    required String liveEventId,
  }) {
    return _apiClient.get<MusicLiveSetlistDto>(
      ApiEndpoints.liveEventSetlist(projectId, liveEventId),
      fromJson: MusicLiveSetlistDto.fromJson,
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return null;
}

List<T> _decodeList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson, {
  String listKey = 'items',
}) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
  if (json is Map<String, dynamic>) {
    final direct = json[listKey];
    if (direct is List) {
      return direct.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }
    for (final key in const [
      'items',
      'content',
      'results',
      'data',
      'versions',
      'groups',
      'lines',
      'segments',
      'cues',
    ]) {
      final value = json[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().map(fromJson).toList();
      }
    }
  }
  return const [];
}

String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
