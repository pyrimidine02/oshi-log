/// EN: Post DTOs aligned with Swagger schema.
/// KO: Swagger 스키마에 맞춘 게시글 DTO.
library;

class AuthorProfileDto {
  const AuthorProfileDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory AuthorProfileDto.fromJson(Map<String, dynamic> json) {
    return AuthorProfileDto(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class PostLikeStatusDto {
  const PostLikeStatusDto({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
  });

  final String postId;
  final bool isLiked;
  final int likeCount;

  factory PostLikeStatusDto.fromJson(Map<String, dynamic> json) {
    return PostLikeStatusDto(
      postId: json['postId'] as String? ?? '',
      isLiked: json['isLiked'] as bool? ?? false,
      likeCount: _intOrNull(json['likeCount']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'postId': postId, 'isLiked': isLiked, 'likeCount': likeCount};
  }
}

class PostBookmarkStatusDto {
  const PostBookmarkStatusDto({
    required this.postId,
    required this.isBookmarked,
    this.bookmarkedAt,
  });

  final String postId;
  final bool isBookmarked;
  final DateTime? bookmarkedAt;

  factory PostBookmarkStatusDto.fromJson(Map<String, dynamic> json) {
    return PostBookmarkStatusDto(
      postId: json['postId'] as String? ?? '',
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      bookmarkedAt: _dateTimeOrNull(json['bookmarkedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'isBookmarked': isBookmarked,
      if (bookmarkedAt != null) 'bookmarkedAt': bookmarkedAt!.toIso8601String(),
    };
  }
}

class PostCursorPageDto {
  const PostCursorPageDto({
    required this.items,
    required this.hasNext,
    this.nextCursor,
  });

  final List<PostSummaryDto> items;
  final String? nextCursor;
  final bool hasNext;

  factory PostCursorPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(PostSummaryDto.fromJson)
              .toList()
        : <PostSummaryDto>[];

    return PostCursorPageDto(
      items: items,
      nextCursor: json['nextCursor'] as String?,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

class ProjectSubscriptionSummaryDto {
  const ProjectSubscriptionSummaryDto({
    required this.projectId,
    required this.projectCode,
    required this.projectName,
    required this.subscribedAt,
  });

  final String projectId;
  final String projectCode;
  final String projectName;
  final DateTime subscribedAt;

  factory ProjectSubscriptionSummaryDto.fromJson(Map<String, dynamic> json) {
    return ProjectSubscriptionSummaryDto(
      projectId: json['projectId'] as String? ?? '',
      projectCode: json['projectCode'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      subscribedAt: _dateTime(json['subscribedAt']),
    );
  }
}

/// EN: Taxonomy option item DTO for post compose.
/// KO: 게시글 작성용 분류 옵션 항목 DTO입니다.
class PostTaxonomyOptionDto {
  const PostTaxonomyOptionDto({
    required this.id,
    required this.name,
    this.sortOrder,
  });

  final String id;
  final String name;
  final int? sortOrder;

  factory PostTaxonomyOptionDto.fromJson(Map<String, dynamic> json) {
    return PostTaxonomyOptionDto(
      id: json['id'] as String? ?? '',
      name: (json['name'] as String? ?? '').trim(),
      sortOrder: _intOrNull(json['sortOrder'] ?? json['sort_order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }
}

/// EN: Taxonomy options DTO used by compose/edit screens.
/// KO: 작성/수정 화면에서 사용하는 분류 옵션 DTO입니다.
class PostComposeOptionsDto {
  const PostComposeOptionsDto({this.topics = const [], this.tags = const []});

  final List<PostTaxonomyOptionDto> topics;
  final List<PostTaxonomyOptionDto> tags;

  factory PostComposeOptionsDto.fromJson(Map<String, dynamic> json) {
    List<PostTaxonomyOptionDto> decodeOptions(dynamic raw) {
      if (raw is! List) {
        return const <PostTaxonomyOptionDto>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PostTaxonomyOptionDto.fromJson)
          .toList(growable: false);
    }

    return PostComposeOptionsDto(
      topics: decodeOptions(json['topics']),
      tags: decodeOptions(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topics': topics.map((option) => option.toJson()).toList(growable: false),
      'tags': tags.map((option) => option.toJson()).toList(growable: false),
    };
  }
}

class PostSummaryDto {
  const PostSummaryDto({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.title,
    required this.createdAt,
    this.imageUrls = const [],
    this.tags = const [],
    this.content,
    this.topic,
    this.thumbnailUrl,
    this.authorName,
    this.authorAvatarUrl,
    this.commentCount,
    this.likeCount,
    this.moderationStatus,
  });

  final String id;
  final String projectId;
  final String authorId;
  final String title;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<String> tags;
  final String? content;
  final String? topic;
  final String? thumbnailUrl;
  final String? authorName;
  final String? authorAvatarUrl;
  final int? commentCount;
  final int? likeCount;
  final String? moderationStatus;

  factory PostSummaryDto.fromJson(Map<String, dynamic> json) {
    final authorProfile = _authorProfile(json['authorProfile']);
    final resolvedAuthorName =
        json['authorName'] as String? ??
        json['authorDisplayName'] as String? ??
        authorProfile?.displayName;
    final resolvedAvatarUrl =
        json['authorAvatarUrl'] as String? ??
        json['authorProfileImageUrl'] as String? ??
        authorProfile?.avatarUrl;

    // EN: Resolve thumbnail URL from various possible field names/shapes.
    // KO: 다양한 필드명/형태에서 썸네일 URL을 해석합니다.
    final resolvedThumbnail = _firstNonEmptyString([
      json['thumbnailUrl'],
      json['thumbnail_url'],
      json['coverImageUrl'],
      json['cover_image_url'],
      json['firstImageUrl'],
      json['first_image_url'],
      json['thumbnailImageUrl'],
      json['thumbnail_image_url'],
      _extractUrlFromDynamic(json['thumbnail']),
      _extractUrlFromDynamic(json['coverImage']),
      _extractUrlFromDynamic(json['cover_image']),
      _extractUrlFromDynamic(json['thumbnailImage']),
      _extractUrlFromDynamic(json['thumbnail_image']),
    ]);

    // EN: Try multiple keys for image arrays.
    // KO: 이미지 배열을 여러 키에서 시도합니다.
    var imageUrls = _imageUrls(
      json['images'] ??
          json['imageUrls'] ??
          json['image_urls'] ??
          json['attachments'] ??
          json['files'] ??
          json['photoUrls'] ??
          json['photo_urls'] ??
          json['media'],
    );

    // EN: If no image URLs from array fields, fall back to thumbnail.
    // KO: 배열 필드에 이미지가 없으면 썸네일을 폴백으로 사용합니다.
    if (imageUrls.isEmpty &&
        resolvedThumbnail != null &&
        resolvedThumbnail.isNotEmpty) {
      imageUrls = [resolvedThumbnail];
    }

    final resolvedContent = _firstNonEmptyString([
      json['content'],
      json['body'],
      json['text'],
      json['excerpt'],
      json['summary'],
      json['description'],
    ]);

    return PostSummaryDto(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: _dateTime(json['createdAt']),
      imageUrls: imageUrls,
      tags: _stringList(
        json['tags'] ??
            json['tagNames'] ??
            json['tag_names'] ??
            json['hashtags'] ??
            json['hashTags'],
      ),
      content: resolvedContent,
      topic: _firstNonEmptyString([
        json['topic'],
        json['topicName'],
        json['topic_name'],
        json['category'],
      ]),
      thumbnailUrl: resolvedThumbnail,
      authorName: resolvedAuthorName,
      authorAvatarUrl: resolvedAvatarUrl,
      commentCount:
          _intOrNull(
            json['commentCount'] ??
                json['commentsCount'] ??
                json['comment_count'],
          ) ??
          0,
      likeCount:
          _intOrNull(
            json['likeCount'] ??
                json['likesCount'] ??
                json['favoriteCount'] ??
                json['favorite_count'],
          ) ??
          0,
      moderationStatus: json['moderationStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'authorId': authorId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (tags.isNotEmpty) 'tags': tags,
      if (content != null) 'content': content,
      if (topic != null) 'topic': topic,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (authorName != null) 'authorName': authorName,
      if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
      if (commentCount != null) 'commentCount': commentCount,
      if (likeCount != null) 'likeCount': likeCount,
      if (moderationStatus != null) 'moderationStatus': moderationStatus,
    };
  }
}

class PostDetailDto {
  const PostDetailDto({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.title,
    required this.createdAt,
    required this.imageUrls,
    this.tags = const [],
    this.content,
    this.topic,
    this.updatedAt,
    this.authorName,
    this.authorAvatarUrl,
    this.commentCount,
    this.likeCount,
    this.moderationStatus,
  });

  final String id;
  final String projectId;
  final String authorId;
  final String title;
  final List<String> imageUrls;
  final List<String> tags;
  final String? content;
  final String? topic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final int? commentCount;
  final int? likeCount;
  final String? moderationStatus;

  factory PostDetailDto.fromJson(Map<String, dynamic> json) {
    final authorProfile = _authorProfile(json['authorProfile']);
    final resolvedAuthorName =
        json['authorName'] as String? ??
        json['authorDisplayName'] as String? ??
        authorProfile?.displayName;
    final resolvedAvatarUrl =
        json['authorAvatarUrl'] as String? ??
        json['authorProfileImageUrl'] as String? ??
        authorProfile?.avatarUrl;

    final resolvedContent = _firstNonEmptyString([
      json['content'],
      json['body'],
      json['text'],
      json['excerpt'],
      json['summary'],
      json['description'],
    ]);

    return PostDetailDto(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: resolvedContent,
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTimeOrNull(json['updatedAt']),
      imageUrls: _imageUrls(json['images'] ?? json['imageUrls']),
      tags: _stringList(
        json['tags'] ??
            json['tagNames'] ??
            json['tag_names'] ??
            json['hashtags'] ??
            json['hashTags'],
      ),
      topic: _firstNonEmptyString([
        json['topic'],
        json['topicName'],
        json['topic_name'],
        json['category'],
      ]),
      authorName: resolvedAuthorName,
      authorAvatarUrl: resolvedAvatarUrl,
      commentCount:
          _intOrNull(
            json['commentCount'] ??
                json['commentsCount'] ??
                json['comment_count'],
          ) ??
          0,
      likeCount:
          _intOrNull(
            json['likeCount'] ??
                json['likesCount'] ??
                json['favoriteCount'] ??
                json['favorite_count'],
          ) ??
          0,
      moderationStatus: json['moderationStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'authorId': authorId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (tags.isNotEmpty) 'tags': tags,
      if (topic != null) 'topic': topic,
      if (authorName != null) 'authorName': authorName,
      if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
      if (commentCount != null) 'commentCount': commentCount,
      if (likeCount != null) 'likeCount': likeCount,
      if (moderationStatus != null) 'moderationStatus': moderationStatus,
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

List<String> _imageUrls(dynamic raw) {
  final urls = <String>{};
  if (raw is String) {
    final normalized = _normalizeUrlString(raw);
    if (normalized != null) {
      urls.add(normalized);
    }
    return urls.toList(growable: false);
  }
  if (raw is List) {
    for (final item in raw) {
      if (item is String) {
        final normalized = _normalizeUrlString(item);
        if (normalized != null) {
          urls.add(normalized);
        }
      } else if (item is Map) {
        // EN: Try multiple keys for the image URL inside an object.
        // KO: 객체 내부에서 이미지 URL을 여러 키로 시도합니다.
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final url =
            map['url'] as String? ??
            map['imageUrl'] as String? ??
            map['image_url'] as String? ??
            map['src'] as String? ??
            map['thumbnailUrl'] as String? ??
            map['thumbnail_url'] as String? ??
            map['fileUrl'] as String? ??
            map['file_url'] as String? ??
            map['publicUrl'] as String? ??
            map['public_url'] as String? ??
            map['cdnUrl'] as String? ??
            map['cdn_url'] as String? ??
            map['path'] as String?;
        final normalized = _normalizeUrlString(url);
        if (normalized != null) {
          urls.add(normalized);
        }
      }
    }
  }
  return urls.toList(growable: false);
}

String? _extractUrlFromDynamic(dynamic raw) {
  if (raw is String) {
    return _normalizeUrlString(raw);
  }
  if (raw is Map) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    return _normalizeUrlString(
      _firstNonEmptyString([
        map['url'],
        map['imageUrl'],
        map['image_url'],
        map['src'],
        map['thumbnailUrl'],
        map['thumbnail_url'],
        map['fileUrl'],
        map['file_url'],
        map['publicUrl'],
        map['public_url'],
        map['cdnUrl'],
        map['cdn_url'],
        map['path'],
      ]),
    );
  }
  return null;
}

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
        return trimmed;
      }
    }
  }
  return null;
}

String? _normalizeUrlString(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.toLowerCase() == 'null') return null;
  return trimmed;
}

AuthorProfileDto? _authorProfile(dynamic value) {
  if (value is Map<String, dynamic>) {
    return AuthorProfileDto.fromJson(value);
  }
  return null;
}
