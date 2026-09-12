import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/music/data/dto/music_dto.dart';
import 'package:oshi_log/features/music/data/mappers/music_entities_mappers.dart';

void main() {
  test('album summary keeps nullable release and track metadata', () {
    final dto = MusicAlbumSummaryDto.fromJson({
      'id': 'album-1',
      'projectId': 'bandori',
      'title': 'Unannounced release',
      'type': 'SINGLE',
      'unitId': 'unit-1',
      'unitName': 'Roselia',
      'releaseDate': null,
      'releaseDateText': '2027년 봄',
      'trackCount': null,
      'discNo': 2,
      'trackNo': 4,
    });

    expect(dto.releaseDate, isNull);
    expect(dto.releaseDateText, '2027년 봄');
    expect(dto.trackCount, isNull);
    expect(dto.unitId, 'unit-1');
    expect(dto.unitName, 'Roselia');
    expect(dto.discNo, 2);
    expect(dto.trackNo, 4);
    expect(dto.toDomain().releaseDateText, '2027년 봄');
    expect(dto.toDomain().trackCount, isNull);
  });

  test('album detail preserves unknown track positions', () {
    final dto = MusicAlbumDetailDto.fromJson({
      'id': 'album-1',
      'projectId': 'bandori',
      'title': 'Digital single',
      'type': 'SINGLE',
      'trackCount': null,
      'releaseDateText': '발매일 추후 공개',
      'tracks': [
        {
          'songId': 'song-1',
          'title': 'Unknown position',
          'trackNo': null,
          'discNo': null,
        },
      ],
    });

    expect(dto.trackCount, isNull);
    expect(dto.tracks.single.trackNo, isNull);
    expect(dto.tracks.single.discNo, isNull);
    expect(dto.toDomain().tracks.single.trackNo, isNull);
  });

  test('song detail exposes every album appearance with position metadata', () {
    final dto = MusicSongDetailDto.fromJson({
      'id': 'song-1',
      'projectId': 'bandori',
      'title': 'A song',
      'albumId': 'album-primary',
      'trackNo': null,
      'albums': [
        {
          'id': 'album-primary',
          'projectId': 'bandori',
          'title': 'Primary release',
          'type': 'SINGLE',
          'releaseDate': '2026-09-12',
          'trackCount': 1,
          'discNo': 1,
          'trackNo': 1,
        },
        {
          'id': 'album-compilation',
          'projectId': 'bandori',
          'title': 'Compilation',
          'type': 'ALBUM',
          'releaseDateText': '2027년 봄',
          'trackCount': null,
          'discNo': 2,
          'trackNo': null,
        },
      ],
    });

    final song = dto.toDomain();
    expect(song.albums, hasLength(2));
    expect(song.albums.first.trackNo, 1);
    expect(song.albums.last.releaseDate, isNull);
    expect(song.albums.last.releaseDateText, '2027년 봄');
    expect(song.albums.last.trackCount, isNull);
    expect(song.albums.last.discNo, 2);
    expect(song.albums.last.trackNo, isNull);
  });
}
