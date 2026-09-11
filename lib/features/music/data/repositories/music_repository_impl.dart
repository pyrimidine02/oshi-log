/// EN: Music repository implementation.
/// KO: 악곡 리포지토리 구현체입니다.
library;

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/music_entities.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/music_remote_data_source.dart';
import '../dto/music_dto.dart';
import '../mappers/music_entities_mappers.dart';

class MusicRepositoryImpl implements MusicRepository {
  MusicRepositoryImpl({required MusicRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final MusicRemoteDataSource _remoteDataSource;

  @override
  Future<Result<MusicCursorPage<MusicAlbumSummary>>> getAlbums({
    required String projectId,
    String? cursor,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.fetchAlbums(
        projectId: projectId,
        cursor: cursor,
        size: size,
      );
      if (result case Success<MusicCursorPageDto<MusicAlbumSummaryDto>>(
        :final data,
      )) {
        return Result.success(
          MusicCursorPage(
            items: data.items
                .map((value) => value.toDomain())
                .toList(growable: false),
            nextCursor: data.nextCursor,
            hasNext: data.hasNext,
          ),
        );
      }
      if (result case Err<MusicCursorPageDto<MusicAlbumSummaryDto>>(
        :final failure,
      )) {
        return Result.failure(failure);
      }
      return _unknownFailure('albums');
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<MusicAlbumDetail>> getAlbumDetail({
    required String projectId,
    required String albumId,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchAlbumDetail(
        projectId: projectId,
        albumId: albumId,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'album_detail',
    );
  }

  @override
  Future<Result<MusicCursorPage<MusicSongSummary>>> getSongs({
    required String projectId,
    String? cursor,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.fetchSongs(
        projectId: projectId,
        cursor: cursor,
        size: size,
      );
      if (result case Success<MusicCursorPageDto<MusicSongSummaryDto>>(
        :final data,
      )) {
        return Result.success(
          MusicCursorPage(
            items: data.items
                .map((value) => value.toDomain())
                .toList(growable: false),
            nextCursor: data.nextCursor,
            hasNext: data.hasNext,
          ),
        );
      }
      if (result case Err<MusicCursorPageDto<MusicSongSummaryDto>>(
        :final failure,
      )) {
        return Result.failure(failure);
      }
      return _unknownFailure('songs');
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<MusicSongDetail>> getSongDetail({
    required String projectId,
    required String songId,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongDetail(projectId: projectId, songId: songId),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_detail',
    );
  }

  @override
  Future<Result<MusicLyricsPayload>> getSongLyrics({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongLyrics(
        projectId: projectId,
        songId: songId,
        lang: lang,
        version: version,
        includeRomanized: includeRomanized,
        includeTranslated: includeTranslated,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_lyrics',
    );
  }

  @override
  Future<Result<MusicPartsPayload>> getSongParts({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongParts(
        projectId: projectId,
        songId: songId,
        lang: lang,
        version: version,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_parts',
    );
  }

  @override
  Future<Result<MusicCallGuidePayload>> getSongCallGuide({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongCallGuide(
        projectId: projectId,
        songId: songId,
        lang: lang,
        version: version,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_call_guide',
    );
  }

  @override
  Future<Result<List<MusicSongVersionInfo>>> getSongVersions({
    required String projectId,
    required String songId,
  }) async {
    try {
      final result = await _remoteDataSource.fetchSongVersions(
        projectId: projectId,
        songId: songId,
      );
      if (result case Success<List<MusicSongVersionInfoDto>>(:final data)) {
        return Result.success(
          data.map((value) => value.toDomain()).toList(growable: false),
        );
      }
      if (result case Err<List<MusicSongVersionInfoDto>>(:final failure)) {
        return Result.failure(failure);
      }
      return _unknownFailure('song_versions');
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<MusicSongVersionInfo>> getSongVersionDetail({
    required String projectId,
    required String songId,
    required String versionCode,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongVersionDetail(
        projectId: projectId,
        songId: songId,
        versionCode: versionCode,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_version_detail',
    );
  }

  @override
  Future<Result<List<MusicCreditGroup>>> getSongCredits({
    required String projectId,
    required String songId,
  }) async {
    try {
      final result = await _remoteDataSource.fetchSongCredits(
        projectId: projectId,
        songId: songId,
      );
      if (result case Success<List<MusicCreditGroupDto>>(:final data)) {
        return Result.success(
          data.map((value) => value.toDomain()).toList(growable: false),
        );
      }
      if (result case Err<List<MusicCreditGroupDto>>(:final failure)) {
        return Result.failure(failure);
      }
      return _unknownFailure('song_credits');
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<MusicDifficulty>> getSongDifficulty({
    required String projectId,
    required String songId,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongDifficulty(
        projectId: projectId,
        songId: songId,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_difficulty',
    );
  }

  @override
  Future<Result<MusicMediaLinks>> getSongMediaLinks({
    required String projectId,
    required String songId,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongMediaLinks(
        projectId: projectId,
        songId: songId,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_media_links',
    );
  }

  @override
  Future<Result<MusicAvailability>> getSongAvailability({
    required String projectId,
    required String songId,
    String? country,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongAvailability(
        projectId: projectId,
        songId: songId,
        country: country,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_availability',
    );
  }

  @override
  Future<Result<MusicSongLiveContext>> getSongLiveContext({
    required String projectId,
    required String songId,
    required String eventId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchSongLiveContext(
        projectId: projectId,
        songId: songId,
        eventId: eventId,
        lang: lang,
        version: version,
        includeRomanized: includeRomanized,
        includeTranslated: includeTranslated,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'song_live_context',
    );
  }

  @override
  Future<Result<MusicLiveSetlist>> getLiveSetlist({
    required String projectId,
    required String liveEventId,
  }) async {
    return _mapSingle(
      _remoteDataSource.fetchLiveSetlist(
        projectId: projectId,
        liveEventId: liveEventId,
      ),
      (dto) => dto.toDomain(),
      fallbackCode: 'live_setlist',
    );
  }
}

Future<Result<R>> _mapSingle<T, R>(
  Future<Result<T>> future,
  R Function(T dto) mapper, {
  required String fallbackCode,
}) async {
  try {
    final result = await future;
    if (result case Success<T>(:final data)) {
      return Result.success(mapper(data));
    }
    if (result case Err<T>(:final failure)) {
      return Result.failure(failure);
    }
    return Result.failure(
      UnknownFailure(
        'Unknown $fallbackCode result',
        code: 'unknown_$fallbackCode',
      ),
    );
  } catch (e, stackTrace) {
    return Result.failure(ErrorHandler.mapException(e, stackTrace));
  }
}

Result<T> _unknownFailure<T>(String code) {
  return Result.failure(
    UnknownFailure('Unknown $code result', code: 'unknown_$code'),
  );
}
