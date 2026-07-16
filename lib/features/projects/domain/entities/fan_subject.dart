/// EN: Domain model for selectable fandom subjects across people and media.
/// KO: 인물과 미디어를 포괄하는 선택 가능 팬 대상 도메인 모델입니다.
library;

import '../../data/dto/fan_subject_dto.dart';

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

  factory FanSubject.fromDto(FanSubjectDto dto) {
    return FanSubject(
      id: dto.id,
      kind: dto.type,
      entityId: dto.entityId,
      key: dto.key,
      name: dto.name,
      description: dto.description,
      imageUrl: dto.imageUrl,
    );
  }
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

  factory FanSubjectSubscription.fromDto(FanSubjectSubscriptionDto dto) {
    return FanSubjectSubscription(
      subject: FanSubject.fromDto(dto.subject),
      subscribed: dto.subscribed,
      subscribedAt: dto.subscribedAt,
    );
  }
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
