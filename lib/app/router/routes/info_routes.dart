/// EN: Information branch routes (shell index 2) — guide, news, units,
/// EN: members, voice actors, songs.
/// KO: 정보 분기 라우트 (쉘 인덱스 2) — 가이드, 뉴스, 유닛, 멤버, 성우, 악곡.
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import '../../../features/feed/presentation/field_guide/field_guide_page.dart';
import '../../../features/feed/presentation/pages/member_detail_page.dart';
import '../../../features/feed/presentation/pages/news_detail_page.dart';
import '../../../features/feed/presentation/pages/unit_detail_page.dart';
import '../../../features/feed/presentation/pages/voice_actor_detail_page.dart';
import '../../../features/music/presentation/pages/music_song_detail_page.dart';
import '../../../features/projects/domain/entities/project_entities.dart'
    show Unit, UnitMember;
import '../route_helpers.dart';

List<RouteBase> buildInfoRoutes() => [
  GoRoute(
    path: '/information',
    name: AppRoutes.information,
    builder: (context, state) => const FieldGuidePage(),
    routes: [
      GoRoute(
        path: 'news/:newsId',
        name: AppRoutes.newsDetail,
        pageBuilder: (context, state) {
          final newsId = state.pathParameters['newsId']!;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: NewsDetailPage(newsId: newsId),
          );
        },
      ),
      GoRoute(
        path: 'units/:unitId',
        name: AppRoutes.unitDetail,
        pageBuilder: (context, state) {
          final unitIdentifier = state.pathParameters['unitId']!;
          final projectId = state.uri.queryParameters['projectId'] ?? '';
          if (projectId.trim().isEmpty) {
            return buildAdaptiveDetailPage(
              key: state.pageKey,
              child: const InvalidNavigationPage(
                message: '유닛 상세 경로 인자가 올바르지 않습니다. (projectId)',
              ),
            );
          }
          final unit = state.extra is Unit ? state.extra! as Unit : null;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: UnitDetailPage(
              projectId: projectId,
              unitIdentifier: unitIdentifier,
              initialUnit: unit,
            ),
          );
        },
        routes: [
          GoRoute(
            path: 'members/:memberId',
            name: AppRoutes.memberDetail,
            pageBuilder: (context, state) {
              final projectId = state.uri.queryParameters['projectId'] ?? '';
              if (projectId.trim().isEmpty) {
                return buildAdaptiveDetailPage(
                  key: state.pageKey,
                  child: const InvalidNavigationPage(
                    message: '멤버 상세 경로 인자가 올바르지 않습니다. (projectId)',
                  ),
                );
              }
              final unitIdentifier = state.pathParameters['unitId']!;
              final memberId = state.pathParameters['memberId']!;
              UnitMember? member;
              Unit? unit;
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                final maybeMember = extra['member'];
                final maybeUnit = extra['unit'];
                if (maybeMember is UnitMember) {
                  member = maybeMember;
                }
                if (maybeUnit is Unit) {
                  unit = maybeUnit;
                }
              }
              return buildAdaptiveDetailPage(
                key: state.pageKey,
                child: MemberDetailPage(
                  projectId: projectId,
                  unitIdentifier: unitIdentifier,
                  memberId: memberId,
                  initialMember: member,
                  unit: unit,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: 'voice-actors/:voiceActorId',
        name: AppRoutes.voiceActorDetail,
        pageBuilder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'] ?? '';
          if (projectId.trim().isEmpty) {
            return buildAdaptiveDetailPage(
              key: state.pageKey,
              child: const InvalidNavigationPage(
                message: '성우 상세 경로 인자가 올바르지 않습니다. (projectId)',
              ),
            );
          }
          final voiceActorId = state.pathParameters['voiceActorId']!;
          final fallbackName = state.uri.queryParameters['name'];
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: VoiceActorDetailPage(
              projectId: projectId,
              voiceActorId: voiceActorId,
              fallbackName: fallbackName,
            ),
          );
        },
      ),
      GoRoute(
        path: 'songs/:songId',
        name: AppRoutes.songDetail,
        pageBuilder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'] ?? '';
          if (projectId.trim().isEmpty) {
            return buildAdaptiveDetailPage(
              key: state.pageKey,
              child: const InvalidNavigationPage(
                message: '악곡 상세 경로 인자가 올바르지 않습니다. (projectId)',
              ),
            );
          }
          final songId = state.pathParameters['songId']!;
          final rawEventId = state.uri.queryParameters['eventId'];
          final eventId = rawEventId?.trim();
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: MusicSongDetailPage(
              projectId: projectId,
              songId: songId,
              eventId: eventId?.isEmpty == true ? null : eventId,
            ),
          );
        },
      ),
    ],
  ),
];
