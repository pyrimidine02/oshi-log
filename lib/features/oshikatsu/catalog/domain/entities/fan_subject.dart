/// EN: Domain model for selectable fandom subjects across people and media.
/// KO: 인물과 미디어를 포괄하는 선택 가능 팬 대상 도메인 모델입니다.
library;

enum FanSubjectKind {
  project,
  unit,
  voiceActor,
  artist,
  anime,
  unknown;

  static FanSubjectKind fromWire(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'PROJECT' => FanSubjectKind.project,
      'UNIT' => FanSubjectKind.unit,
      'VOICE_ACTOR' => FanSubjectKind.voiceActor,
      'ARTIST' => FanSubjectKind.artist,
      'ANIME' => FanSubjectKind.anime,
      _ => FanSubjectKind.unknown,
    };
  }

  String get wireName => switch (this) {
    FanSubjectKind.project => 'PROJECT',
    FanSubjectKind.unit => 'UNIT',
    FanSubjectKind.voiceActor => 'VOICE_ACTOR',
    FanSubjectKind.artist => 'ARTIST',
    FanSubjectKind.anime => 'ANIME',
    FanSubjectKind.unknown => 'UNKNOWN',
  };
}

class FanSubject {
  const FanSubject({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.key,
    required this.name,
    this.description,
    this.imageUrl,
  });

  final String id;
  final FanSubjectKind kind;
  final String entityId;
  final String key;
  final String name;
  final String? description;
  final String? imageUrl;
}

class FanSubjectSubscription {
  const FanSubjectSubscription({
    required this.subject,
    required this.subscribed,
    this.subscribedAt,
  });

  final FanSubject subject;
  final bool subscribed;
  final DateTime? subscribedAt;
}

class FanSubjectQuery {
  const FanSubjectQuery({
    this.kind,
    this.scopeSubjectId,
    this.parentSubjectId,
    this.projectId,
    this.query,
    this.page = 0,
    this.size = 50,
  });

  final FanSubjectKind? kind;
  final String? scopeSubjectId;
  final String? parentSubjectId;
  final String? projectId;
  final String? query;
  final int page;
  final int size;

  @override
  bool operator ==(Object other) {
    return other is FanSubjectQuery &&
        other.kind == kind &&
        other.scopeSubjectId == scopeSubjectId &&
        other.parentSubjectId == parentSubjectId &&
        other.projectId == projectId &&
        other.query == query &&
        other.page == page &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    scopeSubjectId,
    parentSubjectId,
    projectId,
    query,
    page,
    size,
  );
}
