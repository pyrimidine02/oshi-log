/// EN: Post comment DTOs for community posts.
/// KO: 커뮤니티 게시글 댓글 DTO.
library;

class PostCommentDto {
  const PostCommentDto({
    required this.id,
    required this.postId,
    required this.projectId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorAvatarUrl,
    this.parentCommentId,
    this.depth,
    this.replyCount,
  });

  final String id;
  final String postId;
  final String projectId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? parentCommentId;
  final int? depth;
  final int? replyCount;

  factory PostCommentDto.fromJson(Map<String, dynamic> json) {
    final authorProfile = _authorProfile(json['authorProfile']);
    final resolvedAuthorName =
        json['authorName'] as String? ??
        json['authorDisplayName'] as String? ??
        authorProfile?.displayName;
    final resolvedAvatarUrl =
        json['authorAvatarUrl'] as String? ??
        json['authorProfileImageUrl'] as String? ??
        authorProfile?.avatarUrl;

    return PostCommentDto(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTimeOrNull(json['updatedAt']),
      authorName: resolvedAuthorName,
      authorAvatarUrl: resolvedAvatarUrl,
      parentCommentId: json['parentCommentId'] as String?,
      depth: _intOrNull(json['depth']),
      replyCount: _intOrNull(json['replyCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'projectId': projectId,
      'authorId': authorId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      if (authorName != null) 'authorName': authorName,
      if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      if (depth != null) 'depth': depth,
      if (replyCount != null) 'replyCount': replyCount,
    };
  }
}

class CommentThreadNodeDto {
  const CommentThreadNodeDto({
    required this.comment,
    required this.replies,
    required this.hasMoreReplies,
  });

  final PostCommentDto comment;
  final List<CommentThreadNodeDto> replies;
  final bool hasMoreReplies;

  factory CommentThreadNodeDto.fromJson(Map<String, dynamic> json) {
    final rawComment = json['comment'];
    final rawReplies = json['replies'];
    return CommentThreadNodeDto(
      comment: rawComment is Map<String, dynamic>
          ? PostCommentDto.fromJson(rawComment)
          : PostCommentDto.fromJson(const <String, dynamic>{}),
      replies: rawReplies is List
          ? rawReplies
                .whereType<Map<String, dynamic>>()
                .map(CommentThreadNodeDto.fromJson)
                .toList()
          : const <CommentThreadNodeDto>[],
      hasMoreReplies: json['hasMoreReplies'] as bool? ?? false,
    );
  }
}

class PostCreateRequestDto {
  const PostCreateRequestDto({
    required this.title,
    required this.content,
    this.imageUploadIds = const [],
    this.conversationControl = 'EVERYONE',
    this.mentionedUserIds = const [],
    this.topic,
    this.tags = const [],
  });

  final String title;
  final String content;
  // EN: Upload IDs returned by the upload API (not URLs).
  // KO: 업로드 API가 반환한 uploadId 배열 (URL이 아님).
  // EN: Server resolves thumbnailUrl automatically from imageUploadIds[0].
  // KO: 서버가 imageUploadIds[0]으로 thumbnailUrl을 자동 설정합니다.
  final List<String> imageUploadIds;
  final String conversationControl;
  final List<String> mentionedUserIds;
  final String? topic;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      if (imageUploadIds.isNotEmpty) 'imageUploadIds': imageUploadIds,
      'conversationControl': conversationControl,
      'mentionedUserIds': mentionedUserIds,
      if (topic != null && topic!.trim().isNotEmpty) 'topic': topic,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }
}

class PostCommentCreateRequestDto {
  const PostCommentCreateRequestDto({
    required this.content,
    this.parentCommentId,
  });

  final String content;
  final String? parentCommentId;

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (parentCommentId != null && parentCommentId!.isNotEmpty)
        'parentCommentId': parentCommentId,
    };
  }
}

DateTime _dateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateTimeOrNull(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

_AuthorProfileDto? _authorProfile(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _AuthorProfileDto.fromJson(value);
  }
  return null;
}

class _AuthorProfileDto {
  const _AuthorProfileDto({required this.displayName, this.avatarUrl});

  final String displayName;
  final String? avatarUrl;

  factory _AuthorProfileDto.fromJson(Map<String, dynamic> json) {
    return _AuthorProfileDto(
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
