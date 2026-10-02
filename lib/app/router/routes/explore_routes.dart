/// EN: Explore branch routes (shell index 1) — places map, live events.
/// KO: 탐방 분기 라우트 (쉘 인덱스 1) — 장소 지도, 라이브.
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import '../../../features/explore/presentation/field_explore/field_explore_page.dart';
import '../../../features/live_events/presentation/field_events/field_live_event_detail_page.dart';
import '../../../features/places/presentation/pages/place_detail_page.dart';
import '../route_helpers.dart';

List<RouteBase> buildExploreRoutes() => [
  GoRoute(
    path: '/explore',
    name: AppRoutes.explore,
    pageBuilder: (context, state) {
      final tabParam = state.uri.queryParameters['tab'];
      final tabIndex = tabParam != null ? (int.tryParse(tabParam) ?? 0) : 0;
      return NoTransitionPage(
        key: state.pageKey,
        child: FieldExplorePage(initialTabIndex: tabIndex),
      );
    },
    routes: [
      GoRoute(
        path: 'places/:placeId',
        name: AppRoutes.placeDetail,
        pageBuilder: (context, state) {
          final placeId = state.pathParameters['placeId']!;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: PlaceDetailPage(placeId: placeId),
          );
        },
      ),
      GoRoute(
        path: 'events/:eventId',
        name: AppRoutes.eventDetail,
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: FieldLiveEventDetailPage(eventId: eventId),
          );
        },
      ),
    ],
  ),
];
