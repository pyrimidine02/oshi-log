/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/news_dto.dart';
import '../dto/community_translation_dto.dart';
import '../dto/post_comment_dto.dart';
import '../dto/post_dto.dart';
import '../../domain/entities/community_moderation.dart';
import '../../domain/entities/feed_entities.dart';

extension NewsSummaryDtoDomainMapper on NewsSummaryDto {
  NewsSummary toDomain() {
    final dto = this;

    return NewsSummary(
      id: dto.id,
      title: dto.title,
      publishedAt: dto.publishedAt,
      thumbnailUrl: dto.thumbnailUrl,
    );
  }
}

extension NewsDetailDtoDomainMapper on NewsDetailDto {
  NewsDetail toDomain() {
    final dto = this;

    final images = dto.images.map((image) => image.url).toList();
    final cover =
        dto.coverImage?.url ?? (images.isNotEmpty ? images.first : null);

    return NewsDetail(
      id: dto.id,
      title: dto.title,
      body: dto.body,
      status: dto.status,
      publishedAt: dto.publishedAt,
      coverImageUrl: cover,
      imageUrls: List.unmodifiable(images),
    );
  }
}

extension PostSummaryDtoDomainMapper on PostSummaryDto {
  PostSummary toDomain() {
    final dto = this;

    return PostSummary(
      id: dto.id,
      projectId: dto.projectId,
      authorId: dto.authorId,
      title: dto.title,
      createdAt: dto.createdAt,
      imageUrls: List.unmodifiable(dto.imageUrls),
      tags: List.unmodifiable(dto.tags),
      content: dto.content,
      topic: dto.topic,
      thumbnailUrl: dto.thumbnailUrl,
      authorName: dto.authorName,
      authorAvatarUrl: dto.authorAvatarUrl,
      commentCount: dto.commentCount,
      likeCount: dto.likeCount,
      moderationStatus: ContentModerationStatusX.fromApiValue(
        dto.moderationStatus,
      ),
    );
  }
}

extension PostDetailDtoDomainMapper on PostDetailDto {
  PostDetail toDomain() {
    final dto = this;

    return PostDetail(
      id: dto.id,
      projectId: dto.projectId,
      authorId: dto.authorId,
      title: dto.title,
      createdAt: dto.createdAt,
      imageUrls: List.unmodifiable(dto.imageUrls),
      tags: List.unmodifiable(dto.tags),
      content: dto.content,
      topic: dto.topic,
      updatedAt: dto.updatedAt,
      authorName: dto.authorName,
      authorAvatarUrl: dto.authorAvatarUrl,
      commentCount: dto.commentCount,
      likeCount: dto.likeCount,
      moderationStatus: ContentModerationStatusX.fromApiValue(
        dto.moderationStatus,
      ),
    );
  }
}

extension PostCommentDtoDomainMapper on PostCommentDto {
  PostComment toDomain() {
    final dto = this;

    return PostComment(
      id: dto.id,
      postId: dto.postId,
      projectId: dto.projectId,
      authorId: dto.authorId,
      content: dto.content,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      authorName: dto.authorName,
      authorAvatarUrl: dto.authorAvatarUrl,
      parentCommentId: dto.parentCommentId,
      depth: dto.depth,
      replyCount: dto.replyCount,
    );
  }
}

extension CommunityTranslationDtoDomainMapper on CommunityTranslationDto {
  CommunityTranslation toDomain() {
    final dto = this;

    return CommunityTranslation(
      originalText: dto.originalText,
      translatedText: dto.translatedText,
      sourceLanguage: dto.sourceLanguage,
      targetLanguage: dto.targetLanguage,
      translated: dto.translated,
    );
  }
}

extension PostLikeStatusDtoDomainMapper on PostLikeStatusDto {
  PostLikeStatus toDomain() {
    final dto = this;

    return PostLikeStatus(
      postId: dto.postId,
      isLiked: dto.isLiked,
      likeCount: dto.likeCount,
    );
  }
}

extension PostBookmarkStatusDtoDomainMapper on PostBookmarkStatusDto {
  PostBookmarkStatus toDomain() {
    final dto = this;

    return PostBookmarkStatus(
      postId: dto.postId,
      isBookmarked: dto.isBookmarked,
      bookmarkedAt: dto.bookmarkedAt,
    );
  }
}

extension PostTaxonomyOptionDtoDomainMapper on PostTaxonomyOptionDto {
  PostTaxonomyOption toDomain() {
    final dto = this;

    return PostTaxonomyOption(
      id: dto.id,
      name: dto.name,
      sortOrder: dto.sortOrder,
    );
  }
}

extension PostComposeOptionsDtoDomainMapper on PostComposeOptionsDto {
  PostComposeOptions toDomain() {
    final dto = this;

    return PostComposeOptions(
      topics: List.unmodifiable(
        dto.topics.map((value) => value.toDomain()).toList(growable: false),
      ),
      tags: List.unmodifiable(
        dto.tags.map((value) => value.toDomain()).toList(growable: false),
      ),
    );
  }
}

extension PostCursorPageDtoDomainMapper on PostCursorPageDto {
  PostCursorPage toDomain() {
    final dto = this;

    return PostCursorPage(
      items: List.unmodifiable(
        dto.items.map((value) => value.toDomain()).toList(),
      ),
      nextCursor: dto.nextCursor,
      hasNext: dto.hasNext,
    );
  }
}

extension CommentThreadNodeDtoDomainMapper on CommentThreadNodeDto {
  CommentThreadNode toDomain() {
    final dto = this;

    return CommentThreadNode(
      comment: dto.comment.toDomain(),
      replies: List.unmodifiable(
        dto.replies.map((value) => value.toDomain()).toList(),
      ),
      hasMoreReplies: dto.hasMoreReplies,
    );
  }
}

extension ProjectSubscriptionSummaryDtoDomainMapper
    on ProjectSubscriptionSummaryDto {
  ProjectSubscriptionSummary toDomain() {
    final dto = this;

    return ProjectSubscriptionSummary(
      projectId: dto.projectId,
      projectCode: dto.projectCode,
      projectName: dto.projectName,
      subscribedAt: dto.subscribedAt,
    );
  }
}
