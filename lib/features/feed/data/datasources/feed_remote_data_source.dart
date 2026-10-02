/// EN: Remote data source for feed (news & community posts).
/// KO: 피드(뉴스/커뮤니티) 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/community_translation_dto.dart';
import '../dto/post_comment_dto.dart';
import '../dto/post_dto.dart';

class FeedRemoteDataSource {
  FeedRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _pageableQuery({required int page, required int size}) {
    return {
      // EN: Keep both legacy (`page`,`size`) and v3 (`pageable`) query styles.
      // KO: 레거시(`page`,`size`)와 v3(`pageable`) 쿼리 스타일을 함께 전송합니다.
      'page': page,
      'size': size,
      'pageable': '$page,$size',
    };
  }

  Map<String, dynamic> _cursorQuery({String? cursor, required int size}) {
    return {
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'size': size,
    };
  }

  Map<String, dynamic> _recommendedFeedQuery({
    required int page,
    required int size,
    required String sort,
  }) {
    return {'page': page, 'size': size, 'sort': sort};
  }

  /// EN: Fetch paginated community posts for a project.
  /// KO: 프로젝트의 페이지네이션된 커뮤니티 게시글을 조회합니다.
  Future<Result<List<PostSummaryDto>>> fetchPosts({
    required String projectCode,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PostSummaryDto>>(
      ApiEndpoints.posts(projectCode),
      queryParameters: _pageableQuery(page: page, size: size),
      fromJson: (json) => _decodeList(json, PostSummaryDto.fromJson),
    );
  }

  /// EN: Fetch community posts for a project by cursor.
  /// KO: 프로젝트 커뮤니티 게시글을 커서 기반으로 조회합니다.
  Future<Result<PostCursorPageDto>> fetchPostsByCursor({
    required String projectCode,
    String? cursor,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<PostCursorPageDto>(
      ApiEndpoints.postsCursor(projectCode),
      queryParameters: _cursorQuery(cursor: cursor, size: size),
      fromJson: (json) => PostCursorPageDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Fetch global recommended community feed by cursor.
  /// KO: 전역 추천 커뮤니티 피드를 커서 기반으로 조회합니다.
  Future<Result<PostCursorPageDto>> fetchCommunityRecommendedFeedByCursor({
    String? cursor,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<PostCursorPageDto>(
      ApiEndpoints.communityRecommendedFeedCursor,
      queryParameters: _cursorQuery(cursor: cursor, size: size),
      fromJson: (json) => PostCursorPageDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Fetch global recommended community feed by page.
  /// KO: 전역 추천 커뮤니티 피드를 페이지 기반으로 조회합니다.
  Future<Result<List<PostSummaryDto>>> fetchCommunityRecommendedFeed({
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
    String sort = 'createdAt,desc',
  }) {
    return _apiClient.get<List<PostSummaryDto>>(
      ApiEndpoints.communityRecommendedFeed,
      queryParameters: _recommendedFeedQuery(
        page: page,
        size: size,
        sort: sort,
      ),
      fromJson: (json) => _decodeList(json, PostSummaryDto.fromJson),
    );
  }

  /// EN: Fetch following-only community feed by cursor.
  /// KO: 팔로잉 전용 커뮤니티 피드를 커서 기반으로 조회합니다.
  Future<Result<PostCursorPageDto>> fetchCommunityFollowingFeedByCursor({
    String? cursor,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<PostCursorPageDto>(
      ApiEndpoints.communityFollowingFeedCursor,
      queryParameters: _cursorQuery(cursor: cursor, size: size),
      fromJson: (json) => PostCursorPageDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Fetch community posts by author.
  /// KO: 작성자별 커뮤니티 게시글을 조회합니다.
  Future<Result<List<PostSummaryDto>>> fetchPostsByAuthor({
    required String projectCode,
    required String userId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PostSummaryDto>>(
      ApiEndpoints.postsByAuthor(projectCode, userId),
      queryParameters: _pageableQuery(page: page, size: size),
      fromJson: (json) => _decodeList(json, PostSummaryDto.fromJson),
    );
  }

  Future<Result<PostDetailDto>> fetchPostDetail({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.get<PostDetailDto>(
      ApiEndpoints.post(projectCode, postId),
      fromJson: (json) => PostDetailDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Search posts in a project.
  /// KO: 프로젝트 게시글을 검색합니다.
  Future<Result<List<PostSummaryDto>>> searchPosts({
    required String projectCode,
    required String query,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PostSummaryDto>>(
      ApiEndpoints.postsSearch(projectCode),
      queryParameters: {
        'q': query,
        ..._pageableQuery(page: page, size: size),
      },
      fromJson: (json) => _decodeList(json, PostSummaryDto.fromJson),
    );
  }

  /// EN: Fetch trending posts in a project.
  /// KO: 프로젝트 트렌딩 게시글을 조회합니다.
  Future<Result<List<PostSummaryDto>>> fetchTrendingPosts({
    required String projectCode,
    int sinceHours = 24,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PostSummaryDto>>(
      ApiEndpoints.postsTrending(projectCode),
      queryParameters: {
        'sinceHours': sinceHours,
        ..._pageableQuery(page: page, size: size),
      },
      fromJson: (json) => _decodeList(json, PostSummaryDto.fromJson),
    );
  }

  /// EN: Fetch subscribed project list for community.
  /// KO: 커뮤니티 구독 프로젝트 목록을 조회합니다.
  Future<Result<List<ProjectSubscriptionSummaryDto>>> fetchSubscriptions({
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<ProjectSubscriptionSummaryDto>>(
      ApiEndpoints.communitySubscriptions,
      queryParameters: _pageableQuery(page: page, size: size),
      fromJson: (json) =>
          _decodeList(json, ProjectSubscriptionSummaryDto.fromJson),
    );
  }

  /// EN: Fetch compose topic/tag options for community posts.
  /// KO: 커뮤니티 게시글 작성용 토픽/태그 옵션을 조회합니다.
  Future<Result<PostComposeOptionsDto>> fetchPostComposeOptions() {
    return _apiClient.get<PostComposeOptionsDto>(
      ApiEndpoints.communityPostOptions,
      fromJson: (json) => PostComposeOptionsDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Translate community text on demand.
  /// KO: 커뮤니티 텍스트를 요청형으로 번역합니다.
  Future<Result<CommunityTranslationDto>> translateCommunityText({
    required CommunityTranslationRequestDto request,
  }) {
    return _apiClient.post<CommunityTranslationDto>(
      ApiEndpoints.communityTranslations,
      data: request.toJson(),
      fromJson: (json) => CommunityTranslationDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Create a community post.
  /// KO: 커뮤니티 게시글을 생성합니다.
  Future<Result<PostDetailDto>> createPost({
    required String projectCode,
    required PostCreateRequestDto request,
  }) {
    return _apiClient.post<PostDetailDto>(
      ApiEndpoints.posts(projectCode),
      data: request.toJson(),
      fromJson: (json) => PostDetailDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Update a community post.
  /// KO: 커뮤니티 게시글을 수정합니다.
  Future<Result<PostDetailDto>> updatePost({
    required String projectCode,
    required String postId,
    required Map<String, dynamic> request,
  }) {
    return _apiClient.put<PostDetailDto>(
      ApiEndpoints.post(projectCode, postId),
      data: request,
      fromJson: (json) => PostDetailDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Delete a community post.
  /// KO: 커뮤니티 게시글을 삭제합니다.
  Future<Result<void>> deletePost({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.post(projectCode, postId),
      fromJson: (_) {},
    );
  }

  /// EN: Fetch comments for a post.
  /// KO: 게시글 댓글을 조회합니다.
  Future<Result<List<PostCommentDto>>> fetchPostComments({
    required String projectCode,
    required String postId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PostCommentDto>>(
      ApiEndpoints.postComments(projectCode, postId),
      queryParameters: _pageableQuery(page: page, size: size),
      fromJson: (json) => _decodeList(json, PostCommentDto.fromJson),
    );
  }

  /// EN: Fetch comments by author.
  /// KO: 작성자별 댓글을 조회합니다.
  Future<Result<List<PostCommentDto>>> fetchCommentsByAuthor({
    required String projectCode,
    required String userId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PostCommentDto>>(
      ApiEndpoints.commentsByAuthor(projectCode, userId),
      queryParameters: _pageableQuery(page: page, size: size),
      fromJson: (json) => _decodeList(json, PostCommentDto.fromJson),
    );
  }

  /// EN: Create a comment for a post.
  /// KO: 게시글 댓글을 생성합니다.
  Future<Result<PostCommentDto>> createPostComment({
    required String projectCode,
    required String postId,
    required PostCommentCreateRequestDto request,
  }) {
    return _apiClient.post<PostCommentDto>(
      ApiEndpoints.postComments(projectCode, postId),
      data: request.toJson(),
      fromJson: (json) => PostCommentDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch comment thread for a post.
  /// KO: 게시글의 댓글 스레드를 조회합니다.
  Future<Result<List<CommentThreadNodeDto>>> fetchPostCommentThread({
    required String projectCode,
    required String postId,
    String? parentCommentId,
    int maxDepth = 3,
    int size = 50,
  }) {
    return _apiClient.get<List<CommentThreadNodeDto>>(
      ApiEndpoints.postCommentsThread(projectCode, postId),
      queryParameters: {
        if (parentCommentId != null && parentCommentId.isNotEmpty)
          'parentCommentId': parentCommentId,
        'maxDepth': maxDepth,
        'size': size,
      },
      fromJson: (json) => _decodeList(json, CommentThreadNodeDto.fromJson),
    );
  }

  /// EN: Update a comment for a post.
  /// KO: 게시글 댓글을 수정합니다.
  Future<Result<PostCommentDto>> updatePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
    required Map<String, dynamic> request,
  }) {
    return _apiClient.put<PostCommentDto>(
      ApiEndpoints.postComment(projectCode, postId, commentId),
      data: request,
      fromJson: (json) => PostCommentDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Delete a comment for a post.
  /// KO: 게시글 댓글을 삭제합니다.
  Future<Result<void>> deletePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.postComment(projectCode, postId, commentId),
      fromJson: (_) {},
    );
  }

  /// EN: Fetch like status for a post.
  /// KO: 게시글 좋아요 상태를 조회합니다.
  Future<Result<PostLikeStatusDto>> fetchPostLikeStatus({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.get<PostLikeStatusDto>(
      ApiEndpoints.postLike(projectCode, postId),
      fromJson: (json) =>
          PostLikeStatusDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Like a post.
  /// KO: 게시글에 좋아요를 누릅니다.
  Future<Result<PostLikeStatusDto>> likePost({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.post<PostLikeStatusDto>(
      ApiEndpoints.postLike(projectCode, postId),
      fromJson: (json) =>
          PostLikeStatusDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Unlike a post.
  /// KO: 게시글 좋아요를 취소합니다.
  Future<Result<PostLikeStatusDto>> unlikePost({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.delete<PostLikeStatusDto>(
      ApiEndpoints.postLike(projectCode, postId),
      fromJson: (json) =>
          PostLikeStatusDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch bookmark status for a post.
  /// KO: 게시글 북마크 상태를 조회합니다.
  Future<Result<PostBookmarkStatusDto>> fetchPostBookmarkStatus({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.get<PostBookmarkStatusDto>(
      ApiEndpoints.postBookmark(projectCode, postId),
      fromJson: (json) => PostBookmarkStatusDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Bookmark a post.
  /// KO: 게시글을 북마크합니다.
  Future<Result<PostBookmarkStatusDto>> bookmarkPost({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.post<PostBookmarkStatusDto>(
      ApiEndpoints.postBookmark(projectCode, postId),
      fromJson: (json) => PostBookmarkStatusDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Remove bookmark from a post.
  /// KO: 게시글 북마크를 해제합니다.
  Future<Result<PostBookmarkStatusDto>> unbookmarkPost({
    required String projectCode,
    required String postId,
  }) {
    return _apiClient.delete<PostBookmarkStatusDto>(
      ApiEndpoints.postBookmark(projectCode, postId),
      fromJson: (json) => PostBookmarkStatusDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }
}

List<T> _decodeList<T>(dynamic json, T Function(Map<String, dynamic>) mapper) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().map(mapper).toList();
  }
  if (json is Map<String, dynamic>) {
    const listKeys = ['items', 'content', 'data', 'results'];
    for (final key in listKeys) {
      final value = json[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().map(mapper).toList();
      }
    }
  }
  return <T>[];
}
