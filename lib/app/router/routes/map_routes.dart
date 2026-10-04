/// EN: Map branch routes (shell index 1) — places map + zukan collections.
/// EN: PR9 IA: new canonical home for the places map, replacing the old
/// EN: `/explore` tab-0 destination.
/// KO: 지도 분기 라우트 (쉘 인덱스 1) — 장소 지도 + 도감 컬렉션.
/// KO: PR9 IA: 기존 `/explore` tab=0 목적지를 대체하는 새 canonical 경로.
library;

import 'package:go_router/go_router.dart';

import '../../../platform/router/app_router.dart' show AppRoutes;
import '../../compositions/map/presentation/field_map_hub_page.dart';
import '../../compositions/places/place_verification_flow.dart';
import '../route_helpers.dart';

List<RouteBase> buildMapRoutes() => [
  GoRoute(
    path: '/map',
    name: AppRoutes.map,
    pageBuilder: (context, state) {
      final section = state.uri.queryParameters['section'];
      return NoTransitionPage(
        key: state.pageKey,
        child: FieldMapHubPage(showCollections: section == 'collections'),
      );
    },
    routes: [
      GoRoute(
        path: 'places/:placeId',
        name: AppRoutes.mapPlaceDetail,
        pageBuilder: (context, state) {
          final placeId = state.pathParameters['placeId']!;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: PlaceVerificationFlow(placeId: placeId),
          );
        },
      ),
    ],
  ),
];
