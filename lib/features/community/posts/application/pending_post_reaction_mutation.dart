/// EN: Offline pending mutation model for post reactions (like/bookmark).
/// KO: 게시글 반응(좋아요/북마크) 오프라인 대기 작업 모델입니다.
library;

enum PostReactionMutationType { like, bookmark, unknown }

class PendingPostReactionMutation {
  const PendingPostReactionMutation({
    required this.projectCode,
    required this.postId,
    required this.type,
    required this.enabled,
    required this.queuedAt,
  });

  final String projectCode;
  final String postId;
  final PostReactionMutationType type;
  final bool enabled;
  final DateTime queuedAt;

  factory PendingPostReactionMutation.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').toLowerCase();
    return PendingPostReactionMutation(
      projectCode: json['projectCode'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      type: _mutationTypeFromRaw(rawType),
      enabled: json['enabled'] as bool? ?? false,
      queuedAt:
          DateTime.tryParse(json['queuedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectCode': projectCode,
      'postId': postId,
      'type': type.name,
      'enabled': enabled,
      'queuedAt': queuedAt.toIso8601String(),
    };
  }
}

PostReactionMutationType _mutationTypeFromRaw(String raw) {
  return switch (raw) {
    'like' => PostReactionMutationType.like,
    'bookmark' => PostReactionMutationType.bookmark,
    _ => PostReactionMutationType.unknown,
  };
}
