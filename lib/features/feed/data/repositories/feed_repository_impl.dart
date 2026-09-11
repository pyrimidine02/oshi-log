/// EN: Feed repository implementation with caching.
/// KO: 캐시를 포함한 피드 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/feed_entities.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';
import '../dto/community_translation_dto.dart';
import '../dto/news_dto.dart';
import '../dto/post_comment_dto.dart';
import '../dto/post_dto.dart';
import '../mappers/feed_entities_mappers.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl({
    required FeedRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final FeedRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<NewsSummary>>> getNews({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _newsListCacheKey(projectId, page, size);
    final profile = CacheProfiles.feedNews;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<NewsSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchNews(projectId, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(NewsSummaryDto.fromJson)
                .toList();
          }
          return <NewsSummaryDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<NewsDetail>> getNewsDetail({
    required String projectId,
    required String newsId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _newsDetailCacheKey(projectId, newsId);
    final profile = CacheProfiles.feedNews;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<NewsDetailDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchNewsDetail(projectId, newsId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => NewsDetailDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostSummary>>> getPosts({
    required String projectCode,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _postListCacheKey(projectCode, page, size);
    // EN: Use staleWhileRevalidate — show cached posts instantly.
    // KO: staleWhileRevalidate 사용 — 캐시된 게시글 즉시 표시.
    final profile = CacheProfiles.feedPostList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PostSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPosts(projectCode, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PostSummaryDto.fromJson)
                .toList();
          }
          return <PostSummaryDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostCursorPage>> getPostsByCursor({
    required String projectCode,
    String? cursor,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.fetchPostsByCursor(
        projectCode: projectCode,
        cursor: cursor,
        size: size,
      );

      if (result is Success<PostCursorPageDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostCursorPageDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown cursor posts result',
          code: 'unknown_cursor_posts',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostCursorPage>> getCommunityRecommendedFeedByCursor({
    String? cursor,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource
          .fetchCommunityRecommendedFeedByCursor(cursor: cursor, size: size);

      if (result is Success<PostCursorPageDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostCursorPageDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown community recommended feed cursor result',
          code: 'unknown_community_recommended_feed_cursor',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostSummary>>> getCommunityRecommendedFeed({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final result = await _remoteDataSource.fetchCommunityRecommendedFeed(
        page: page,
        size: size,
        sort: sort,
      );

      if (result is Success<List<PostSummaryDto>>) {
        final entities = result.data.map((value) => value.toDomain()).toList();
        return Result.success(entities);
      }
      if (result is Err<List<PostSummaryDto>>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown community recommended feed result',
          code: 'unknown_community_recommended_feed',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostCursorPage>> getCommunityFollowingFeedByCursor({
    String? cursor,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource
          .fetchCommunityFollowingFeedByCursor(cursor: cursor, size: size);

      if (result is Success<PostCursorPageDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostCursorPageDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown following community feed cursor result',
          code: 'unknown_following_community_feed_cursor',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostSummary>>> searchPosts({
    required String projectCode,
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.searchPosts(
        projectCode: projectCode,
        query: query,
        page: page,
        size: size,
      );

      if (result is Success<List<PostSummaryDto>>) {
        final entities = result.data.map((value) => value.toDomain()).toList();
        return Result.success(entities);
      }
      if (result is Err<List<PostSummaryDto>>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown post search result',
          code: 'unknown_post_search',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostSummary>>> getTrendingPosts({
    required String projectCode,
    int sinceHours = 24,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _trendingPostsCacheKey(
      projectCode,
      sinceHours,
      page,
      size,
    );
    final profile = CacheProfiles.feedTrendingPosts;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PostSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchTrendingPosts(projectCode, sinceHours, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PostSummaryDto.fromJson)
                .toList();
          }
          return <PostSummaryDto>[];
        },
      );

      final entities = cacheResult.data
          .map((value) => value.toDomain())
          .toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<ProjectSubscriptionSummary>>> getCommunitySubscriptions({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _communitySubscriptionsCacheKey(page, size);
    final profile = CacheProfiles.feedCommunitySubscriptions;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<ProjectSubscriptionSummaryDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchCommunitySubscriptions(page, size),
            toJson: (dtos) => {
              'items': dtos
                  .map(
                    (dto) => {
                      'projectId': dto.projectId,
                      'projectCode': dto.projectCode,
                      'projectName': dto.projectName,
                      'subscribedAt': dto.subscribedAt.toIso8601String(),
                    },
                  )
                  .toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(ProjectSubscriptionSummaryDto.fromJson)
                    .toList();
              }
              return <ProjectSubscriptionSummaryDto>[];
            },
          );

      final entities = cacheResult.data
          .map((value) => value.toDomain())
          .toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostDetail>> getPostDetail({
    required String projectCode,
    required String postId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _postDetailCacheKey(projectCode, postId);
    // EN: Use staleWhileRevalidate for post detail — show cached content first.
    // KO: 게시글 상세에 staleWhileRevalidate 사용 — 캐시 콘텐츠 먼저 표시.
    final profile = CacheProfiles.feedPostDetail;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<PostDetailDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPostDetail(projectCode, postId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => PostDetailDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostDetail>> createPost({
    required String projectCode,
    required String title,
    required String content,
    List<String> imageUploadIds = const [],
    String? topic,
    List<String> tags = const [],
  }) async {
    try {
      final request = PostCreateRequestDto(
        title: title,
        content: content,
        imageUploadIds: imageUploadIds,
        topic: topic,
        tags: tags,
      );
      final result = await _remoteDataSource.createPost(
        projectCode: projectCode,
        request: request,
      );

      if (result is Success<PostDetailDto>) {
        await _invalidateAfterPostMutation(projectCode);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostDetailDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown create post result',
          code: 'unknown_create_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<CommunityTranslation>> translateCommunityText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final normalizedText = text.trim();
    final normalizedTarget = targetLanguage.trim().toLowerCase();
    final normalizedSource = sourceLanguage?.trim().toLowerCase();
    const allowedLanguages = <String>{'ko', 'en', 'ja'};

    if (normalizedText.isEmpty) {
      return const Result.failure(
        ValidationFailure('Translation text is empty', code: 'text_required'),
      );
    }
    if (normalizedText.length > 5000) {
      return const Result.failure(
        ValidationFailure(
          'Translation text must be 5000 characters or fewer',
          code: 'text_too_long',
        ),
      );
    }
    if (normalizedTarget.isEmpty) {
      return const Result.failure(
        ValidationFailure(
          'Translation target language is empty',
          code: 'target_language_required',
        ),
      );
    }
    if (!allowedLanguages.contains(normalizedTarget)) {
      return const Result.failure(
        ValidationFailure(
          'Unsupported target language',
          code: 'target_language_unsupported',
        ),
      );
    }
    if (normalizedSource != null &&
        normalizedSource.isNotEmpty &&
        !allowedLanguages.contains(normalizedSource)) {
      return const Result.failure(
        ValidationFailure(
          'Unsupported source language',
          code: 'source_language_unsupported',
        ),
      );
    }

    try {
      final result = await _remoteDataSource.translateCommunityText(
        request: CommunityTranslationRequestDto(
          text: normalizedText,
          targetLanguage: normalizedTarget,
          sourceLanguage: normalizedSource,
        ),
      );

      if (result is Success<CommunityTranslationDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<CommunityTranslationDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown community translation result',
          code: 'unknown_community_translation',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostComposeOptions>> getPostComposeOptions({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.feedPostComposeOptions;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<PostComposeOptionsDto>(
        key: _postComposeOptionsCacheKey(),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchPostComposeOptions,
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => PostComposeOptionsDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostDetail>> updatePost({
    required String projectCode,
    required String postId,
    required String title,
    required String content,
    String? topic,
    List<String> tags = const [],
  }) async {
    try {
      final trimmedTopic = topic?.trim();
      final result = await _remoteDataSource.updatePost(
        projectCode: projectCode,
        postId: postId,
        request: {
          'title': title,
          'content': content,
          if (trimmedTopic != null && trimmedTopic.isNotEmpty)
            'topic': trimmedTopic,
          if (tags.isNotEmpty) 'tags': tags,
        },
      );

      if (result is Success<PostDetailDto>) {
        await _invalidateAfterPostMutation(projectCode, postId: postId);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostDetailDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown update post result',
          code: 'unknown_update_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> deletePost({
    required String projectCode,
    required String postId,
  }) async {
    try {
      final result = await _remoteDataSource.deletePost(
        projectCode: projectCode,
        postId: postId,
      );

      if (result is Success<void>) {
        await _invalidateAfterPostMutation(projectCode, postId: postId);
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown delete post result',
          code: 'unknown_delete_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostComment>>> getPostComments({
    required String projectCode,
    required String postId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _postCommentsCacheKey(projectCode, postId, page, size);
    // EN: Use staleWhileRevalidate for comments — show cached comments first.
    // KO: 댓글에 staleWhileRevalidate 사용 — 캐시 댓글 먼저 표시.
    final profile = CacheProfiles.feedPostComments;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PostCommentDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPostComments(projectCode, postId, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PostCommentDto.fromJson)
                .toList();
          }
          return <PostCommentDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostComment>> createPostComment({
    required String projectCode,
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final request = PostCommentCreateRequestDto(
        content: content,
        parentCommentId: parentCommentId,
      );
      final result = await _remoteDataSource.createPostComment(
        projectCode: projectCode,
        postId: postId,
        request: request,
      );

      if (result is Success<PostCommentDto>) {
        await _invalidateAfterCommentMutation(projectCode, postId: postId);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostCommentDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown create post comment result',
          code: 'unknown_create_post_comment',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostComment>> updatePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
    required String content,
  }) async {
    try {
      final result = await _remoteDataSource.updatePostComment(
        projectCode: projectCode,
        postId: postId,
        commentId: commentId,
        request: {'content': content},
      );

      if (result is Success<PostCommentDto>) {
        await _invalidateAfterCommentMutation(projectCode, postId: postId);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostCommentDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown update post comment result',
          code: 'unknown_update_post_comment',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> deletePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
  }) async {
    try {
      final result = await _remoteDataSource.deletePostComment(
        projectCode: projectCode,
        postId: postId,
        commentId: commentId,
      );

      if (result is Success<void>) {
        await _invalidateAfterCommentMutation(projectCode, postId: postId);
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown delete post comment result',
          code: 'unknown_delete_post_comment',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostSummary>>> getPostsByAuthor({
    required String projectCode,
    required String userId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _postsByAuthorCacheKey(projectCode, userId, page, size);
    // EN: Use staleWhileRevalidate for author posts — show cached data first.
    // KO: 작성자별 게시글에 staleWhileRevalidate 사용 — 캐시 먼저 표시.
    final profile = CacheProfiles.feedPostsByAuthor;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PostSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPostsByAuthor(projectCode, userId, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PostSummaryDto.fromJson)
                .toList();
          }
          return <PostSummaryDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PostComment>>> getCommentsByAuthor({
    required String projectCode,
    required String userId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _commentsByAuthorCacheKey(projectCode, userId, page, size);
    // EN: Use staleWhileRevalidate for author comments — show cached data first.
    // KO: 작성자별 댓글에 staleWhileRevalidate 사용 — 캐시 먼저 표시.
    final profile = CacheProfiles.feedCommentsByAuthor;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PostCommentDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchCommentsByAuthor(projectCode, userId, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PostCommentDto.fromJson)
                .toList();
          }
          return <PostCommentDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostLikeStatus>> getPostLikeStatus({
    required String projectCode,
    required String postId,
  }) async {
    final profile = CacheProfiles.feedReactionStatus;
    final cacheKey = _postLikeStatusCacheKey(projectCode, postId);
    try {
      final cacheResult = await _cacheManager.resolve<PostLikeStatusDto>(
        key: cacheKey,
        policy: profile.readPolicy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPostLikeStatusWithFallback(projectCode, postId),
        toJson: (dto) => dto.toJson(),
        fromJson: PostLikeStatusDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostLikeStatus>> likePost({
    required String projectCode,
    required String postId,
  }) async {
    try {
      final result = await _remoteDataSource.likePost(
        projectCode: projectCode,
        postId: postId,
      );

      if (result is Success<PostLikeStatusDto>) {
        await _cacheLikeStatus(projectCode, result.data);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostLikeStatusDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown like post result',
          code: 'unknown_like_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostLikeStatus>> unlikePost({
    required String projectCode,
    required String postId,
  }) async {
    try {
      final result = await _remoteDataSource.unlikePost(
        projectCode: projectCode,
        postId: postId,
      );

      if (result is Success<PostLikeStatusDto>) {
        await _cacheLikeStatus(projectCode, result.data);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostLikeStatusDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown unlike post result',
          code: 'unknown_unlike_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostBookmarkStatus>> getPostBookmarkStatus({
    required String projectCode,
    required String postId,
  }) async {
    final profile = CacheProfiles.feedReactionStatus;
    final cacheKey = _postBookmarkStatusCacheKey(projectCode, postId);
    try {
      final cacheResult = await _cacheManager.resolve<PostBookmarkStatusDto>(
        key: cacheKey,
        policy: profile.readPolicy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () =>
            _fetchPostBookmarkStatusWithFallback(projectCode, postId),
        toJson: (dto) => dto.toJson(),
        fromJson: PostBookmarkStatusDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostBookmarkStatus>> bookmarkPost({
    required String projectCode,
    required String postId,
  }) async {
    try {
      final result = await _remoteDataSource.bookmarkPost(
        projectCode: projectCode,
        postId: postId,
      );

      if (result is Success<PostBookmarkStatusDto>) {
        await _cacheBookmarkStatus(projectCode, result.data);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostBookmarkStatusDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown bookmark post result',
          code: 'unknown_bookmark_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<PostBookmarkStatus>> unbookmarkPost({
    required String projectCode,
    required String postId,
  }) async {
    try {
      final result = await _remoteDataSource.unbookmarkPost(
        projectCode: projectCode,
        postId: postId,
      );

      if (result is Success<PostBookmarkStatusDto>) {
        await _cacheBookmarkStatus(projectCode, result.data);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PostBookmarkStatusDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown unbookmark post result',
          code: 'unknown_unbookmark_post',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<CommentThreadNode>>> getPostCommentThread({
    required String projectCode,
    required String postId,
    String? parentCommentId,
    int maxDepth = 3,
    int size = 50,
  }) async {
    try {
      final result = await _remoteDataSource.fetchPostCommentThread(
        projectCode: projectCode,
        postId: postId,
        parentCommentId: parentCommentId,
        maxDepth: maxDepth,
        size: size,
      );

      if (result is Success<List<CommentThreadNodeDto>>) {
        final entities = result.data.map((value) => value.toDomain()).toList();
        return Result.success(entities);
      }
      if (result is Err<List<CommentThreadNodeDto>>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown post comment thread result',
          code: 'unknown_post_comment_thread',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<NewsSummaryDto>> _fetchNews(
    String projectId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchNews(
      projectId: projectId,
      page: page,
      size: size,
    );

    if (result is Success<List<NewsSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<NewsSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown news list result',
      code: 'unknown_news_list',
    );
  }

  Future<NewsDetailDto> _fetchNewsDetail(
    String projectId,
    String newsId,
  ) async {
    final result = await _remoteDataSource.fetchNewsDetail(
      projectId: projectId,
      newsId: newsId,
    );

    if (result is Success<NewsDetailDto>) {
      return result.data;
    }
    if (result is Err<NewsDetailDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown news detail result',
      code: 'unknown_news_detail',
    );
  }

  Future<List<PostSummaryDto>> _fetchPosts(
    String projectCode,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchPosts(
      projectCode: projectCode,
      page: page,
      size: size,
    );

    if (result is Success<List<PostSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PostSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown posts list result',
      code: 'unknown_posts_list',
    );
  }

  Future<List<PostSummaryDto>> _fetchTrendingPosts(
    String projectCode,
    int sinceHours,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchTrendingPosts(
      projectCode: projectCode,
      sinceHours: sinceHours,
      page: page,
      size: size,
    );

    if (result is Success<List<PostSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PostSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown trending posts result',
      code: 'unknown_trending_posts',
    );
  }

  Future<List<ProjectSubscriptionSummaryDto>> _fetchCommunitySubscriptions(
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchSubscriptions(
      page: page,
      size: size,
    );

    if (result is Success<List<ProjectSubscriptionSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<ProjectSubscriptionSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown community subscriptions result',
      code: 'unknown_community_subscriptions',
    );
  }

  Future<PostComposeOptionsDto> _fetchPostComposeOptions() async {
    final result = await _remoteDataSource.fetchPostComposeOptions();

    if (result is Success<PostComposeOptionsDto>) {
      return result.data;
    }
    if (result is Err<PostComposeOptionsDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown post compose options result',
      code: 'unknown_post_compose_options',
    );
  }

  Future<List<PostSummaryDto>> _fetchPostsByAuthor(
    String projectCode,
    String userId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchPostsByAuthor(
      projectCode: projectCode,
      userId: userId,
      page: page,
      size: size,
    );

    if (result is Success<List<PostSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PostSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown posts by author result',
      code: 'unknown_posts_by_author',
    );
  }

  Future<PostDetailDto> _fetchPostDetail(
    String projectCode,
    String postId,
  ) async {
    final result = await _remoteDataSource.fetchPostDetail(
      projectCode: projectCode,
      postId: postId,
    );

    if (result is Success<PostDetailDto>) {
      return result.data;
    }
    if (result is Err<PostDetailDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown post detail result',
      code: 'unknown_post_detail',
    );
  }

  Future<List<PostCommentDto>> _fetchPostComments(
    String projectCode,
    String postId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchPostComments(
      projectCode: projectCode,
      postId: postId,
      page: page,
      size: size,
    );

    if (result is Success<List<PostCommentDto>>) {
      return result.data;
    }
    if (result is Err<List<PostCommentDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown post comments result',
      code: 'unknown_post_comments',
    );
  }

  Future<List<PostCommentDto>> _fetchCommentsByAuthor(
    String projectCode,
    String userId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchCommentsByAuthor(
      projectCode: projectCode,
      userId: userId,
      page: page,
      size: size,
    );

    if (result is Success<List<PostCommentDto>>) {
      return result.data;
    }
    if (result is Err<List<PostCommentDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown comments by author result',
      code: 'unknown_comments_by_author',
    );
  }

  Future<PostLikeStatusDto> _fetchPostLikeStatusWithFallback(
    String projectCode,
    String postId,
  ) async {
    final result = await _remoteDataSource.fetchPostLikeStatus(
      projectCode: projectCode,
      postId: postId,
    );

    if (result is Success<PostLikeStatusDto>) {
      return result.data;
    }
    if (result is Err<PostLikeStatusDto>) {
      if (_isNotFoundLikeFailure(result.failure)) {
        return PostLikeStatusDto(postId: postId, isLiked: false, likeCount: 0);
      }
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown post like status result',
      code: 'unknown_post_like_status',
    );
  }

  Future<PostBookmarkStatusDto> _fetchPostBookmarkStatusWithFallback(
    String projectCode,
    String postId,
  ) async {
    final result = await _remoteDataSource.fetchPostBookmarkStatus(
      projectCode: projectCode,
      postId: postId,
    );

    if (result is Success<PostBookmarkStatusDto>) {
      return result.data;
    }
    if (result is Err<PostBookmarkStatusDto>) {
      if (_isNotFoundLikeFailure(result.failure)) {
        return PostBookmarkStatusDto(postId: postId, isBookmarked: false);
      }
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown post bookmark status result',
      code: 'unknown_post_bookmark_status',
    );
  }

  bool _isNotFoundLikeFailure(Failure failure) {
    if (failure is NotFoundFailure) {
      return true;
    }
    return failure.code?.trim() == '404';
  }

  Future<void> _cacheLikeStatus(
    String projectCode,
    PostLikeStatusDto dto,
  ) async {
    await _cacheManager.setJson(
      _postLikeStatusCacheKey(projectCode, dto.postId),
      dto.toJson(),
      ttl: CacheProfiles.feedReactionStatus.ttl,
    );
  }

  Future<void> _cacheBookmarkStatus(
    String projectCode,
    PostBookmarkStatusDto dto,
  ) async {
    await _cacheManager.setJson(
      _postBookmarkStatusCacheKey(projectCode, dto.postId),
      dto.toJson(),
      ttl: CacheProfiles.feedReactionStatus.ttl,
    );
  }

  Future<void> _invalidateAfterPostMutation(
    String projectCode, {
    String? postId,
  }) async {
    await _invalidatePostListCaches(projectCode);
    await _invalidateAuthorActivityCaches(projectCode);
    if (postId != null && postId.isNotEmpty) {
      await _invalidatePostDetailAndCommentsCaches(projectCode, postId);
    }
  }

  Future<void> _invalidateAfterCommentMutation(
    String projectCode, {
    required String postId,
  }) async {
    await _invalidatePostDetailAndCommentsCaches(projectCode, postId);
    await _invalidatePostListCaches(projectCode);
    await _invalidateAuthorActivityCaches(projectCode);
  }

  Future<void> _invalidatePostListCaches(String projectCode) async {
    await _cacheManager.removeByPrefix('post_list:$projectCode:');
    await _cacheManager.removeByPrefix('post_trending:$projectCode:');
  }

  Future<void> _invalidatePostDetailAndCommentsCaches(
    String projectCode,
    String postId,
  ) async {
    await _cacheManager.remove(_postDetailCacheKey(projectCode, postId));
    await _cacheManager.removeByPrefix('post_comments:$projectCode:$postId:');
    await _cacheManager.remove(_postLikeStatusCacheKey(projectCode, postId));
    await _cacheManager.remove(
      _postBookmarkStatusCacheKey(projectCode, postId),
    );
  }

  Future<void> _invalidateAuthorActivityCaches(String projectCode) async {
    await _cacheManager.removeByPrefix('post_list:$projectCode:author:');
    await _cacheManager.removeByPrefix('post_comments:$projectCode:author:');
  }

  String _newsListCacheKey(String projectId, int page, int size) {
    return 'news_list:$projectId:p$page:s$size';
  }

  String _newsDetailCacheKey(String projectId, String newsId) {
    return 'news_detail:$projectId:$newsId';
  }

  String _postListCacheKey(String projectCode, int page, int size) {
    return 'post_list:$projectCode:p$page:s$size';
  }

  String _postDetailCacheKey(String projectCode, String postId) {
    return 'post_detail:$projectCode:$postId';
  }

  String _postCommentsCacheKey(
    String projectCode,
    String postId,
    int page,
    int size,
  ) {
    return 'post_comments:$projectCode:$postId:p$page:s$size';
  }

  String _postsByAuthorCacheKey(
    String projectCode,
    String userId,
    int page,
    int size,
  ) {
    return 'post_list:$projectCode:author:$userId:p$page:s$size';
  }

  String _commentsByAuthorCacheKey(
    String projectCode,
    String userId,
    int page,
    int size,
  ) {
    return 'post_comments:$projectCode:author:$userId:p$page:s$size';
  }

  String _trendingPostsCacheKey(
    String projectCode,
    int sinceHours,
    int page,
    int size,
  ) {
    return 'post_trending:$projectCode:h$sinceHours:p$page:s$size';
  }

  String _communitySubscriptionsCacheKey(int page, int size) {
    return 'community_subscriptions:p$page:s$size';
  }

  String _postComposeOptionsCacheKey() {
    return 'post_compose_options';
  }

  String _postLikeStatusCacheKey(String projectCode, String postId) {
    return 'post_like_status:$projectCode:$postId';
  }

  String _postBookmarkStatusCacheKey(String projectCode, String postId) {
    return 'post_bookmark_status:$projectCode:$postId';
  }
}
