/// EN: Music repository interface for albums, songs, and live setlist context.
/// KO: 앨범/곡/라이브 세트리스트 컨텍스트용 악곡 리포지토리 인터페이스입니다.
library;

import '../../../../core/utils/result.dart';
import '../entities/music_entities.dart';

abstract class MusicRepository {
  Future<Result<MusicCursorPage<MusicAlbumSummary>>> getAlbums({
    required String projectId,
    String? cursor,
    int size = 20,
  });

  Future<Result<MusicAlbumDetail>> getAlbumDetail({
    required String projectId,
    required String albumId,
  });

  Future<Result<MusicCursorPage<MusicSongSummary>>> getSongs({
    required String projectId,
    String? cursor,
    int size = 20,
  });

  Future<Result<MusicSongDetail>> getSongDetail({
    required String projectId,
    required String songId,
  });

  Future<Result<MusicLyricsPayload>> getSongLyrics({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  });

  Future<Result<MusicPartsPayload>> getSongParts({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  });

  Future<Result<MusicCallGuidePayload>> getSongCallGuide({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  });

  Future<Result<List<MusicSongVersionInfo>>> getSongVersions({
    required String projectId,
    required String songId,
  });

  Future<Result<MusicSongVersionInfo>> getSongVersionDetail({
    required String projectId,
    required String songId,
    required String versionCode,
  });

  Future<Result<List<MusicCreditGroup>>> getSongCredits({
    required String projectId,
    required String songId,
  });

  Future<Result<MusicDifficulty>> getSongDifficulty({
    required String projectId,
    required String songId,
  });

  Future<Result<MusicMediaLinks>> getSongMediaLinks({
    required String projectId,
    required String songId,
  });

  Future<Result<MusicAvailability>> getSongAvailability({
    required String projectId,
    required String songId,
    String? country,
  });

  Future<Result<MusicSongLiveContext>> getSongLiveContext({
    required String projectId,
    required String songId,
    required String eventId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  });

  /// EN: Live events where the song was performed, newest first.
  /// KO: 곡이 공연된 라이브 이벤트 목록이며 최신순입니다.
  Future<Result<List<MusicSongPerformance>>> getSongPerformances({
    required String projectId,
    required String songId,
    String? lang,
  });

  Future<Result<MusicLiveSetlist>> getLiveSetlist({
    required String projectId,
    required String liveEventId,
  });
}
