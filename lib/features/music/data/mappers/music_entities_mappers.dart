/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/music_dto.dart';
import '../../domain/entities/music_entities.dart';

extension MusicAlbumSummaryDtoDomainMapper on MusicAlbumSummaryDto {
  MusicAlbumSummary toDomain() {
    final dto = this;

    return MusicAlbumSummary(
      id: dto.id,
      projectId: dto.projectId,
      title: dto.title,
      type: dto.type,
      coverUrl: dto.coverUrl,
      releaseDate: dto.releaseDate,
      trackCount: dto.trackCount,
      label: dto.label,
      catalogNo: dto.catalogNo,
    );
  }
}

extension MusicAlbumTrackDtoDomainMapper on MusicAlbumTrackDto {
  MusicAlbumTrack toDomain() {
    final dto = this;

    return MusicAlbumTrack(
      songId: dto.songId,
      trackNo: dto.trackNo,
      title: dto.title,
      versionCode: dto.versionCode,
      durationMs: dto.durationMs,
    );
  }
}

extension MusicAlbumDetailDtoDomainMapper on MusicAlbumDetailDto {
  MusicAlbumDetail toDomain() {
    final dto = this;

    return MusicAlbumDetail(
      id: dto.id,
      projectId: dto.projectId,
      title: dto.title,
      type: dto.type,
      coverUrl: dto.coverUrl,
      releaseDate: dto.releaseDate,
      trackCount: dto.trackCount,
      label: dto.label,
      catalogNo: dto.catalogNo,
      tracks: List.unmodifiable(
        dto.tracks.map((value) => value.toDomain()).toList(growable: false),
      ),
    );
  }
}

extension MusicSongSummaryDtoDomainMapper on MusicSongSummaryDto {
  MusicSongSummary toDomain() {
    final dto = this;

    return MusicSongSummary(
      id: dto.id,
      projectId: dto.projectId,
      title: dto.title,
      titleJa: dto.titleJa,
      titleEn: dto.titleEn,
      durationMs: dto.durationMs,
      bpm: dto.bpm,
      primaryUnitId: dto.primaryUnitId,
      primaryUnitName: dto.primaryUnitName,
      albumId: dto.albumId,
      trackNo: dto.trackNo,
      isTitleTrack: dto.isTitleTrack,
      defaultVersionCode: dto.defaultVersionCode,
    );
  }
}

extension MusicSongVersionInfoDtoDomainMapper on MusicSongVersionInfoDto {
  MusicSongVersionInfo toDomain() {
    final dto = this;

    return MusicSongVersionInfo(
      versionCode: dto.versionCode,
      durationMs: dto.durationMs,
      bpm: dto.bpm,
      key: dto.key,
      timeSignature: dto.timeSignature,
      isDefault: dto.isDefault,
      arrangementNote: dto.arrangementNote,
    );
  }
}

extension MusicSongDetailDtoDomainMapper on MusicSongDetailDto {
  MusicSongDetail toDomain() {
    final dto = this;

    return MusicSongDetail(
      id: dto.id,
      projectId: dto.projectId,
      title: dto.title,
      titleJa: dto.titleJa,
      titleEn: dto.titleEn,
      durationMs: dto.durationMs,
      bpm: dto.bpm,
      primaryUnitId: dto.primaryUnitId,
      primaryUnitName: dto.primaryUnitName,
      albumId: dto.albumId,
      trackNo: dto.trackNo,
      isTitleTrack: dto.isTitleTrack,
      defaultVersionCode: dto.defaultVersionCode,
      versions: List.unmodifiable(
        dto.versions.map((value) => value.toDomain()).toList(growable: false),
      ),
      previewUrl: dto.previewUrl,
    );
  }
}

extension MusicLyricLineDtoDomainMapper on MusicLyricLineDto {
  MusicLyricLine toDomain() {
    final dto = this;

    return MusicLyricLine(
      lineId: dto.lineId,
      order: dto.order,
      startMs: dto.startMs,
      endMs: dto.endMs,
      section: dto.section,
      textOriginal: dto.textOriginal,
      textRomanized: dto.textRomanized,
      textTranslated: dto.textTranslated,
    );
  }
}

extension MusicLyricsPayloadDtoDomainMapper on MusicLyricsPayloadDto {
  MusicLyricsPayload toDomain() {
    final dto = this;

    return MusicLyricsPayload(
      songId: dto.songId,
      version: dto.version,
      lines: List.unmodifiable(
        dto.lines.map((value) => value.toDomain()).toList(growable: false),
      ),
    );
  }
}

extension MusicPartSegmentDtoDomainMapper on MusicPartSegmentDto {
  MusicPartSegment toDomain() {
    final dto = this;

    return MusicPartSegment(
      segmentId: dto.segmentId,
      startMs: dto.startMs,
      endMs: dto.endMs,
      memberId: dto.memberId,
      memberName: dto.memberName,
      unitId: dto.unitId,
      unitName: dto.unitName,
      partType: dto.partType,
      lyricLineId: dto.lyricLineId,
    );
  }
}

extension MusicPartsPayloadDtoDomainMapper on MusicPartsPayloadDto {
  MusicPartsPayload toDomain() {
    final dto = this;

    return MusicPartsPayload(
      songId: dto.songId,
      version: dto.version,
      segments: List.unmodifiable(
        dto.segments.map((value) => value.toDomain()).toList(growable: false),
      ),
    );
  }
}

extension MusicCallCueDtoDomainMapper on MusicCallCueDto {
  MusicCallCue toDomain() {
    final dto = this;

    return MusicCallCue(
      cueId: dto.cueId,
      startMs: dto.startMs,
      endMs: dto.endMs,
      cueType: dto.cueType,
      cueText: dto.cueText,
      intensity: dto.intensity,
      target: dto.target,
      note: dto.note,
    );
  }
}

extension MusicCallGuidePayloadDtoDomainMapper on MusicCallGuidePayloadDto {
  MusicCallGuidePayload toDomain() {
    final dto = this;

    return MusicCallGuidePayload(
      songId: dto.songId,
      version: dto.version,
      cues: List.unmodifiable(
        dto.cues.map((value) => value.toDomain()).toList(growable: false),
      ),
    );
  }
}

extension MusicCreditContributorDtoDomainMapper on MusicCreditContributorDto {
  MusicCreditContributor toDomain() {
    final dto = this;

    return MusicCreditContributor(id: dto.id, name: dto.name, type: dto.type);
  }
}

extension MusicCreditGroupDtoDomainMapper on MusicCreditGroupDto {
  MusicCreditGroup toDomain() {
    final dto = this;

    return MusicCreditGroup(
      role: dto.role,
      contributors: List.unmodifiable(
        dto.contributors
            .map((value) => value.toDomain())
            .toList(growable: false),
      ),
    );
  }
}

extension MusicDifficultyDtoDomainMapper on MusicDifficultyDto {
  MusicDifficulty toDomain() {
    final dto = this;

    return MusicDifficulty(
      difficultyLevel: dto.difficultyLevel,
      callIntensity: dto.callIntensity,
      cueDensityPerMin: dto.cueDensityPerMin,
      vocalRangeScore: dto.vocalRangeScore,
      tempoScore: dto.tempoScore,
    );
  }
}

extension MusicPreviewDtoDomainMapper on MusicPreviewDto {
  MusicPreview toDomain() {
    final dto = this;

    return MusicPreview(
      url: dto.url,
      durationSec: dto.durationSec,
      waveformUrl: dto.waveformUrl,
    );
  }
}

extension MusicStreamingLinkDtoDomainMapper on MusicStreamingLinkDto {
  MusicStreamingLink toDomain() {
    final dto = this;

    return MusicStreamingLink(
      provider: dto.provider,
      url: dto.url,
      regionAvailability: dto.regionAvailability,
    );
  }
}

extension MusicMediaLinksDtoDomainMapper on MusicMediaLinksDto {
  MusicMediaLinks toDomain() {
    final dto = this;

    return MusicMediaLinks(
      preview: dto.preview.toDomain(),
      streamingLinks: List.unmodifiable(
        dto.streamingLinks
            .map((value) => value.toDomain())
            .toList(growable: false),
      ),
    );
  }
}

extension MusicAvailabilityDtoDomainMapper on MusicAvailabilityDto {
  MusicAvailability toDomain() {
    final dto = this;

    return MusicAvailability(
      isAvailableNow: dto.isAvailableNow,
      availableFrom: dto.availableFrom,
      availableUntil: dto.availableUntil,
      allowedCountries: List.unmodifiable(dto.allowedCountries),
      blockedCountries: List.unmodifiable(dto.blockedCountries),
      rightsPolicy: dto.rightsPolicy,
    );
  }
}

extension MusicSetlistItemDtoDomainMapper on MusicSetlistItemDto {
  MusicSetlistItem toDomain() {
    final dto = this;

    return MusicSetlistItem(
      order: dto.order,
      eventId: dto.eventId,
      unitId: dto.unitId,
      unitName: dto.unitName,
      songId: dto.songId,
      songTitle: dto.songTitle,
      versionCode: dto.versionCode,
      segmentType: dto.segmentType,
      startAt: dto.startAt,
      endAt: dto.endAt,
      isEncore: dto.isEncore,
      source: dto.source,
    );
  }
}

extension MusicUnitSetlistDtoDomainMapper on MusicUnitSetlistDto {
  MusicUnitSetlist toDomain() {
    final dto = this;

    return MusicUnitSetlist(
      unitId: dto.unitId,
      unitName: dto.unitName,
      performanceOrder: dto.performanceOrder,
      rawSetlist: dto.rawSetlist,
      parsedSongs: List.unmodifiable(dto.parsedSongs),
    );
  }
}

extension MusicLiveSetlistDtoDomainMapper on MusicLiveSetlistDto {
  MusicLiveSetlist toDomain() {
    final dto = this;

    return MusicLiveSetlist(
      liveEventId: dto.liveEventId,
      eventStatus: dto.eventStatus,
      items: List.unmodifiable(
        dto.items.map((value) => value.toDomain()).toList(growable: false),
      ),
      unitSetlists: List.unmodifiable(
        dto.unitSetlists
            .map((value) => value.toDomain())
            .toList(growable: false),
      ),
    );
  }
}

extension MusicSongLiveContextDtoDomainMapper on MusicSongLiveContextDto {
  MusicSongLiveContext toDomain() {
    final dto = this;

    return MusicSongLiveContext(
      song: dto.song?.toDomain(),
      lyrics: dto.lyrics?.toDomain(),
      parts: dto.parts?.toDomain(),
      callGuide: dto.callGuide?.toDomain(),
      setlistContext: dto.setlistContext?.toDomain(),
    );
  }
}
