/// EN: Community branch routes (shell index 4) — board/feed, posts, travel
/// EN: reviews.
/// KO: 커뮤니티 분기 라우트 (쉘 인덱스 4) — 게시판, 게시글, 여행 후기.
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import 'package:oshi_log/features/community/posts/domain/entities/feed_entities.dart';
import '../../compositions/community/presentation/field_community/field_community_page.dart';
import '../../compositions/posts/post_create_route.dart';
import '../../compositions/posts/post_detail_route.dart';
import '../../compositions/posts/post_edit_route.dart';
import '../../../features/community/reviews/presentation/pages/travel_review_create_page.dart';
import '../../../features/community/reviews/presentation/pages/travel_review_detail_page.dart';
import '../route_helpers.dart';

List<RouteBase> buildCommunityRoutes() => [
  GoRoute(
    path: '/community',
    name: AppRoutes.community,
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: const FieldCommunityPage(initialSectionIndex: 0),
    ),
    routes: [
      GoRoute(
        path: 'discover',
        name: AppRoutes.discover,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const FieldCommunityPage(initialSectionIndex: 1),
        ),
      ),
      GoRoute(
        path: 'travel-reviews-tab',
        name: AppRoutes.travelReviewTab,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const FieldCommunityPage(initialSectionIndex: 2),
        ),
      ),
      GoRoute(
        path: 'posts/new',
        name: AppRoutes.postCreate,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const PostCreateRoute(),
        ),
      ),
      GoRoute(
        path: 'travel-review-create',
        name: AppRoutes.travelReviewCreate,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const TravelReviewCreatePage(),
        ),
      ),
      GoRoute(
        path: ':projectCode/travel-reviews/:reviewId',
        name: AppRoutes.travelReviewDetail,
        builder: (context, state) {
          final projectCode = state.pathParameters['projectCode']!;
          final reviewId = state.pathParameters['reviewId']!;
          return TravelReviewDetailPage(
            projectCode: projectCode,
            reviewId: reviewId,
          );
        },
      ),
      // EN: Preserve query-qualified legacy links while refusing
      //     to guess project scope from mutable global state.
      // KO: 쿼리에 프로젝트가 있는 기존 링크는 보존하되 변경 가능한
      //     전역 상태에서 프로젝트 범위를 추측하지 않습니다.
      GoRoute(
        path: 'travel-reviews/:reviewId',
        redirect: (context, state) {
          final projectCode = state.uri.queryParameters['projectCode']?.trim();
          if (projectCode == null || projectCode.isEmpty) {
            return null;
          }
          return state.namedLocation(
            AppRoutes.travelReviewDetail,
            pathParameters: {
              'projectCode': projectCode,
              'reviewId': state.pathParameters['reviewId']!,
            },
          );
        },
        builder: (context, state) {
          return const InvalidNavigationPage(
            message: '여행 후기 링크에 프로젝트 정보가 없습니다.',
          );
        },
      ),
      GoRoute(
        path: 'posts/:postId',
        name: AppRoutes.postDetail,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final projectCodeHint = state.uri.queryParameters['projectCode'];
          return PostDetailRoute(
            postId: postId,
            projectCodeHint: projectCodeHint,
          );
        },
      ),
      GoRoute(
        path: 'posts/:postId/edit',
        name: AppRoutes.postEdit,
        builder: (context, state) {
          final post = state.extra;
          if (post is! PostDetail) {
            return const InvalidNavigationPage(
              message: '게시글 수정 경로 인자가 올바르지 않습니다.',
            );
          }
          return PostEditRoute(post: post);
        },
      ),
    ],
  ),
];
