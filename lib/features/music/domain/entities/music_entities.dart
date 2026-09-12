/// EN: Domain entities for music information and live setlist features.
/// KO: 악곡 정보 및 라이브 세트리스트 기능의 도메인 엔티티입니다.
library;

class MusicCursorPage<T> {
  const MusicCursorPage({
    required this.items,
    required this.hasNext,
    this.nextCursor,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasNext;
}

class MusicAlbumSummary {
  const MusicAlbumSummary({
    required this.id,
    required this.projectId,
    required this.title,
    required this.type,
    this.coverUrl,
    this.releaseDate,
    this.releaseDateText,
    this.trackCount,
    this.label,
    this.catalogNo,
    this.unitId,
    this.unitName,
    this.discNo,
    this.trackNo,
  });

  final String id;
  final String projectId;
  final String title;
  final String type;
  final String? coverUrl;
  final String? releaseDate;
  final String? releaseDateText;
  final int? trackCount;
  final String? label;
  final String? catalogNo;
  final String? unitId;
  final String? unitName;
  final int? discNo;
  final int? trackNo;
}

class MusicAlbumTrack {
  const MusicAlbumTrack({
    required this.songId,
    required this.trackNo,
    required this.title,
    this.discNo,
    this.versionCode,
    this.durationMs,
  });

  final String songId;
  final int? trackNo;
  final int? discNo;
  final String title;
  final String? versionCode;
  final int? durationMs;
}

class MusicAlbumDetail extends MusicAlbumSummary {
  const MusicAlbumDetail({
    required super.id,
    required super.projectId,
    required super.title,
    required super.type,
    super.coverUrl,
    super.releaseDate,
    super.releaseDateText,
    super.trackCount,
    super.label,
    super.catalogNo,
    super.unitId,
    super.unitName,
    super.discNo,
    super.trackNo,
    this.tracks = const [],
  });

  final List<MusicAlbumTrack> tracks;
}

class MusicSongSummary {
  const MusicSongSummary({
    required this.id,
    required this.projectId,
    required this.title,
    this.titleJa,
    this.titleEn,
    this.durationMs,
    this.bpm,
    this.primaryUnitId,
    this.primaryUnitName,
    this.albumId,
    this.trackNo,
    this.isTitleTrack,
    this.defaultVersionCode,
  });

  final String id;
  final String projectId;
  final String title;
  final String? titleJa;
  final String? titleEn;
  final int? durationMs;
  final int? bpm;
  final String? primaryUnitId;
  final String? primaryUnitName;
  final String? albumId;
  final int? trackNo;
  final bool? isTitleTrack;
  final String? defaultVersionCode;
}

class MusicSongVersionInfo {
  const MusicSongVersionInfo({
    required this.versionCode,
    this.durationMs,
    this.bpm,
    this.key,
    this.timeSignature,
    this.isDefault = false,
    this.arrangementNote,
  });

  final String versionCode;
  final int? durationMs;
  final int? bpm;
  final String? key;
  final String? timeSignature;
  final bool isDefault;
  final String? arrangementNote;
}

class MusicSongDetail extends MusicSongSummary {
  const MusicSongDetail({
    required super.id,
    required super.projectId,
    required super.title,
    super.titleJa,
    super.titleEn,
    super.durationMs,
    super.bpm,
    super.primaryUnitId,
    super.primaryUnitName,
    super.albumId,
    super.trackNo,
    super.isTitleTrack,
    super.defaultVersionCode,
    this.versions = const [],
    this.previewUrl,
    this.albums = const [],
  });

  final List<MusicSongVersionInfo> versions;
  final String? previewUrl;
  final List<MusicAlbumSummary> albums;
}

class MusicLyricLine {
  const MusicLyricLine({
    required this.lineId,
    required this.order,
    required this.startMs,
    required this.endMs,
    required this.section,
    required this.textOriginal,
    this.textRomanized,
    this.textTranslated,
  });

  final String lineId;
  final int order;
  final int startMs;
  final int endMs;
  final String section;
  final String textOriginal;
  final String? textRomanized;
  final String? textTranslated;
}

class MusicLyricsPayload {
  const MusicLyricsPayload({
    required this.songId,
    required this.version,
    required this.lines,
  });

  final String songId;
  final String version;
  final List<MusicLyricLine> lines;
}

class MusicPartSegment {
  const MusicPartSegment({
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    this.memberId,
    this.memberName,
    this.unitId,
    this.unitName,
    this.partType,
    this.lyricLineId,
  });

  final String segmentId;
  final int startMs;
  final int endMs;
  final String? memberId;
  final String? memberName;
  final String? unitId;
  final String? unitName;
  final String? partType;
  final String? lyricLineId;
}

class MusicPartsPayload {
  const MusicPartsPayload({
    required this.songId,
    required this.version,
    required this.segments,
  });

  final String songId;
  final String version;
  final List<MusicPartSegment> segments;
}

class MusicCallCue {
  const MusicCallCue({
    required this.cueId,
    required this.startMs,
    required this.endMs,
    required this.cueType,
    required this.cueText,
    this.intensity,
    this.target,
    this.note,
  });

  final String cueId;
  final int startMs;
  final int endMs;
  final String cueType;
  final String cueText;
  final int? intensity;
  final String? target;
  final String? note;
}

class MusicCallGuidePayload {
  const MusicCallGuidePayload({
    required this.songId,
    required this.version,
    required this.cues,
  });

  final String songId;
  final String version;
  final List<MusicCallCue> cues;
}

class MusicCreditContributor {
  const MusicCreditContributor({required this.name, this.id, this.type});

  final String? id;
  final String name;
  final String? type;
}

class MusicCreditGroup {
  const MusicCreditGroup({required this.role, required this.contributors});

  final String role;
  final List<MusicCreditContributor> contributors;
}

class MusicDifficulty {
  const MusicDifficulty({
    required this.difficultyLevel,
    required this.callIntensity,
    required this.cueDensityPerMin,
    required this.vocalRangeScore,
    required this.tempoScore,
  });

  final String difficultyLevel;
  final int callIntensity;
  final int cueDensityPerMin;
  final int vocalRangeScore;
  final int tempoScore;
}

class MusicPreview {
  const MusicPreview({this.url, this.durationSec, this.waveformUrl});

  final String? url;
  final int? durationSec;
  final String? waveformUrl;
}

class MusicStreamingLink {
  const MusicStreamingLink({
    required this.provider,
    required this.url,
    this.regionAvailability,
  });

  final String provider;
  final String url;
  final String? regionAvailability;
}

class MusicMediaLinks {
  const MusicMediaLinks({required this.preview, required this.streamingLinks});

  final MusicPreview preview;
  final List<MusicStreamingLink> streamingLinks;
}

class MusicAvailability {
  const MusicAvailability({
    required this.isAvailableNow,
    this.availableFrom,
    this.availableUntil,
    required this.allowedCountries,
    required this.blockedCountries,
    required this.rightsPolicy,
  });

  final bool isAvailableNow;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<String> allowedCountries;
  final List<String> blockedCountries;
  final String rightsPolicy;
}

class MusicSetlistItem {
  const MusicSetlistItem({
    required this.order,
    required this.eventId,
    this.unitId,
    this.unitName,
    this.songId,
    this.songTitle,
    this.versionCode,
    required this.segmentType,
    this.startAt,
    this.endAt,
    required this.isEncore,
    this.source,
  });

  final int order;
  final String eventId;
  final String? unitId;
  final String? unitName;
  final String? songId;
  final String? songTitle;
  final String? versionCode;
  final String segmentType;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isEncore;
  final String? source;

  bool get hasSongLink => (songId ?? '').trim().isNotEmpty;
}

class MusicUnitSetlist {
  const MusicUnitSetlist({
    required this.unitId,
    this.unitName,
    this.performanceOrder,
    this.rawSetlist,
    required this.parsedSongs,
  });

  final String unitId;
  final String? unitName;
  final int? performanceOrder;
  final String? rawSetlist;
  final List<String> parsedSongs;
}

class MusicLiveSetlist {
  const MusicLiveSetlist({
    required this.liveEventId,
    required this.eventStatus,
    required this.items,
    required this.unitSetlists,
  });

  final String liveEventId;
  final String eventStatus;
  final List<MusicSetlistItem> items;
  final List<MusicUnitSetlist> unitSetlists;

  bool get isCompleted => eventStatus.toUpperCase() == 'COMPLETED';
}

class MusicSongLiveContext {
  const MusicSongLiveContext({
    this.song,
    this.lyrics,
    this.parts,
    this.callGuide,
    this.setlistContext,
  });

  final MusicSongDetail? song;
  final MusicLyricsPayload? lyrics;
  final MusicPartsPayload? parts;
  final MusicCallGuidePayload? callGuide;
  final MusicLiveSetlist? setlistContext;
}
