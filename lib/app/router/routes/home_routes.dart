/// EN: Home branch routes (shell index 0).
/// EN: PR9 IA: hosts the news detail route, canonical home for the old
/// EN: `/information/news/:newsId` destination.
/// KO: 홈 분기 라우트 (쉘 인덱스 0).
/// KO: PR9 IA: 기존 `/information/news/:newsId` 목적지의 canonical 홈인
/// KO: 뉴스 상세 라우트를 포함합니다.
library;

import 'package:go_router/go_router.dart';

import '../../../platform/router/app_router.dart' show AppRoutes;
import '../../../features/community/news/presentation/pages/news_detail_page.dart';
import '../../compositions/home/presentation/field_home/field_home_page.dart';
import '../route_helpers.dart';

List<RouteBase> buildHomeRoutes() => [
  GoRoute(
    path: '/home',
    name: AppRoutes.home,
    builder: (context, state) => const FieldHomePage(),
    routes: [
      GoRoute(
        path: 'news/:newsId',
        name: AppRoutes.homeNewsDetail,
        pageBuilder: (context, state) {
          final newsId = state.pathParameters['newsId']!;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: NewsDetailPage(newsId: newsId),
          );
        },
      ),
    ],
  ),
];
