/// EN: Compatibility links keep names, decoded IDs, all query values and fragments.
/// KO: 호환 링크는 이름, 디코딩된 ID, 모든 쿼리 값과 fragment를 보존합니다.
library;

import 'package:go_router/go_router.dart';
import '../../../platform/router/app_router.dart' show AppRoutes;

/// EN: Resolves only known old URLs, without guessing project context.
/// KO: 프로젝트 문맥을 추측하지 않고 알려진 옛 URL만 변환합니다.
String? legacyRouteDestination(Uri uri) {
  final parts = uri.pathSegments;
  final query = Map<String, dynamic>.from(uri.queryParametersAll);
  List<String>? target;
  if (parts.length == 1 && parts.first == 'explore') {
    final tab = (int.tryParse(uri.queryParameters['tab'] ?? '') ?? 0).clamp(
      0,
      3,
    );
    query.remove('tab');
    target = switch (tab) {
      1 => ['live'],
      2 => ['mypage', 'records'],
      _ => ['map'],
    };
    if (tab == 3) query['section'] = 'collections';
  } else if (parts.length == 3 && parts.first == 'explore') {
    target = switch (parts[1]) {
      'places' => ['map', 'places', parts[2]],
      'events' => ['live', 'events', parts[2]],
      _ => null,
    };
  } else if (parts.length == 1 && parts.first == 'information') {
    target = ['live', 'music'];
  } else if (parts.length == 3 && parts.first == 'information') {
    target = switch (parts[1]) {
      'news' => ['home', 'news', parts[2]],
      'units' => ['live', 'artists', parts[2]],
      'voice-actors' => ['live', 'voice-actors', parts[2]],
      'songs' => ['live', 'music', 'songs', parts[2]],
      _ => null,
    };
  } else if (parts.length == 5 &&
      parts[0] == 'information' &&
      parts[1] == 'units' &&
      parts[3] == 'members') {
    target = ['live', 'artists', parts[2], 'members', parts[4]];
  }
  if (target == null) return null;
  return Uri(
    pathSegments: ['', ...target],
    queryParameters: query.isEmpty ? null : query,
    fragment: uri.hasFragment ? uri.fragment : null,
  ).toString();
}

List<RouteBase> buildLegacyAliasRoutes() => [
  for (final entry in <String, String>{
    '/explore': AppRoutes.explore,
    '/explore/places/:placeId': AppRoutes.placeDetail,
    '/explore/events/:eventId': AppRoutes.eventDetail,
    '/information': AppRoutes.information,
    '/information/news/:newsId': AppRoutes.newsDetail,
    '/information/units/:unitId': AppRoutes.unitDetail,
    '/information/units/:unitId/members/:memberId': AppRoutes.memberDetail,
    '/information/voice-actors/:voiceActorId': AppRoutes.voiceActorDetail,
    '/information/songs/:songId': AppRoutes.songDetail,
  }.entries)
    GoRoute(
      path: entry.key,
      name: entry.value,
      redirect: (_, state) => legacyRouteDestination(state.uri),
    ),
];
