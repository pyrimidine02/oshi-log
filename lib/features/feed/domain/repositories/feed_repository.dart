/// EN: Feed repository interface for news and community posts.
/// KO: 뉴스 및 커뮤니티 게시글 리포지토리 인터페이스.
library;

import '../../../../core/utils/result.dart';
import '../entities/feed_entities.dart';

abstract class FeedRepository {
  /// EN: Get paginated community posts.
  /// KO: 페이지네이션된 커뮤니티 게시글을 가져옵니다.
  Future<Result<List<PostSummary>>> getPosts({
    required String projectCode,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Get project posts with cursor pagination.
  /// KO: 프로젝트 게시글을 커서 기반으로 가져옵니다.
  Future<Result<PostCursorPage>> getPostsByCursor({
    required String projectCode,
    String? cursor,
    int size = 20,
  });

  /// EN: Get global recommended community feed by cursor.
  /// KO: 전역 추천 커뮤니티 피드를 커서 기반으로 가져옵니다.
  Future<Result<PostCursorPage>> getCommunityRecommendedFeedByCursor({
    String? cursor,
    int size = 20,
  });

  /// EN: Get global recommended community feed by page.
  /// KO: 전역 추천 커뮤니티 피드를 페이지 기반으로 가져옵니다.
  Future<Result<List<PostSummary>>> getCommunityRecommendedFeed({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  });

  /// EN: Get following-only community feed by cursor.
  /// KO: 팔로잉 전용 커뮤니티 피드를 커서 기반으로 가져옵니다.
  Future<Result<PostCursorPage>> getCommunityFollowingFeedByCursor({
    String? cursor,
    int size = 20,
  });

  /// EN: Search posts in the selected project.
  /// KO: 선택된 프로젝트의 게시글을 검색합니다.
  Future<Result<List<PostSummary>>> searchPosts({
    required String projectCode,
    required String query,
    int page = 0,
    int size = 20,
  });

  /// EN: Get trending posts in the selected project.
  /// KO: 선택된 프로젝트의 트렌딩 게시글을 가져옵니다.
  Future<Result<List<PostSummary>>> getTrendingPosts({
    required String projectCode,
    int sinceHours = 24,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Get subscribed community projects.
  /// KO: 커뮤니티 구독 프로젝트를 조회합니다.
  Future<Result<List<ProjectSubscriptionSummary>>> getCommunitySubscriptions({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  Future<Result<PostDetail>> getPostDetail({
    required String projectCode,
    required String postId,
    bool forceRefresh = false,
  });

  /// EN: Translate community content on demand.
  /// KO: 커뮤니티 콘텐츠를 요청 시점에 번역합니다.
  Future<Result<CommunityTranslation>> translateCommunityText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  });

  /// EN: Create a community post.
  /// KO: 커뮤니티 게시글을 생성합니다.
  Future<Result<PostDetail>> createPost({
    required String projectCode,
    required String title,
    required String content,
    List<String> imageUploadIds = const [],
    String? topic,
    List<String> tags = const [],
  });

  /// EN: Get compose metadata options (topics/tags).
  /// KO: 작성 메타데이터 옵션(토픽/태그)을 조회합니다.
  Future<Result<PostComposeOptions>> getPostComposeOptions({
    bool forceRefresh = false,
  });

  /// EN: Update a community post.
  /// KO: 커뮤니티 게시글을 수정합니다.
  Future<Result<PostDetail>> updatePost({
    required String projectCode,
    required String postId,
    required String title,
    required String content,
    String? topic,
    List<String> tags = const [],
  });

  /// EN: Delete a community post.
  /// KO: 커뮤니티 게시글을 삭제합니다.
  Future<Result<void>> deletePost({
    required String projectCode,
    required String postId,
  });

  /// EN: Get comments for a post.
  /// KO: 게시글 댓글을 가져옵니다.
  Future<Result<List<PostComment>>> getPostComments({
    required String projectCode,
    required String postId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Create a comment for a post.
  /// KO: 게시글 댓글을 생성합니다.
  Future<Result<PostComment>> createPostComment({
    required String projectCode,
    required String postId,
    required String content,
    String? parentCommentId,
  });

  /// EN: Update a comment for a post.
  /// KO: 게시글 댓글을 수정합니다.
  Future<Result<PostComment>> updatePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
    required String content,
  });

  /// EN: Delete a comment for a post.
  /// KO: 게시글 댓글을 삭제합니다.
  Future<Result<void>> deletePostComment({
    required String projectCode,
    required String postId,
    required String commentId,
  });

  /// EN: Get posts authored by a specific user.
  /// KO: 특정 사용자가 작성한 게시글을 가져옵니다.
  Future<Result<List<PostSummary>>> getPostsByAuthor({
    required String projectCode,
    required String userId,
    int page,
    int size,
    bool forceRefresh,
  });

  /// EN: Get comments authored by a specific user.
  /// KO: 특정 사용자가 작성한 댓글을 가져옵니다.
  Future<Result<List<PostComment>>> getCommentsByAuthor({
    required String projectCode,
    required String userId,
    int page,
    int size,
    bool forceRefresh,
  });

  /// EN: Get post like status.
  /// KO: 게시글 좋아요 상태를 가져옵니다.
  Future<Result<PostLikeStatus>> getPostLikeStatus({
    required String projectCode,
    required String postId,
  });

  /// EN: Like a post.
  /// KO: 게시글에 좋아요를 누릅니다.
  Future<Result<PostLikeStatus>> likePost({
    required String projectCode,
    required String postId,
  });

  /// EN: Unlike a post.
  /// KO: 게시글 좋아요를 취소합니다.
  Future<Result<PostLikeStatus>> unlikePost({
    required String projectCode,
    required String postId,
  });

  /// EN: Get bookmark status for a post.
  /// KO: 게시글 북마크 상태를 가져옵니다.
  Future<Result<PostBookmarkStatus>> getPostBookmarkStatus({
    required String projectCode,
    required String postId,
  });

  /// EN: Bookmark a post.
  /// KO: 게시글을 북마크합니다.
  Future<Result<PostBookmarkStatus>> bookmarkPost({
    required String projectCode,
    required String postId,
  });

  /// EN: Remove bookmark from a post.
  /// KO: 게시글 북마크를 해제합니다.
  Future<Result<PostBookmarkStatus>> unbookmarkPost({
    required String projectCode,
    required String postId,
  });

  /// EN: Get threaded comments for a post.
  /// KO: 게시글의 스레드 댓글을 조회합니다.
  Future<Result<List<CommentThreadNode>>> getPostCommentThread({
    required String projectCode,
    required String postId,
    String? parentCommentId,
    int maxDepth = 3,
    int size = 50,
  });
}
