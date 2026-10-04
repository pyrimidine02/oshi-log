/// EN: Live branch routes (shell index 2) — schedule + music/artist archive.
/// EN: PR9 IA: `/live` is the schedule root, `/live/music` (name
/// EN: `music-archive`) is the sibling archive segment of the same stable
/// EN: page key — segment switches use `go`, detail entry uses `push`.
/// KO: 라이브 분기 라우트 (쉘 인덱스 2) — 스케줄 + 음악/아티스트 아카이브.
/// KO: PR9 IA: `/live`는 스케줄 루트, `/live/music`(이름 `music-archive`)는
/// KO: 같은 안정적 페이지 키의 형제 아카이브 세그먼트입니다 — 세그먼트
/// KO: 전환은 `go`, 상세 진입은 `push`를 사용합니다.
library;

import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../../../platform/router/app_router.dart' show AppRoutes;
import '../../compositions/live/live_host.dart';
import 'package:oshi_log/features/oshikatsu/music/presentation/pages/music_song_detail_page.dart';
import '../../../features/oshikatsu/catalog/domain/entities/project_entities.dart'
    show Unit, UnitMember;
import '../../../features/oshikatsu/catalog/presentation/pages/member_detail_page.dart';
import '../../../features/oshikatsu/catalog/presentation/pages/unit_detail_page.dart';
import '../../../features/oshikatsu/catalog/presentation/pages/voice_actor_detail_page.dart';
import '../../compositions/live/presentation/field_live_hub_page.dart';
import '../route_helpers.dart';
import '../../session/protected_read_gate.dart';

List<RouteBase> buildLiveRoutes() => [
  GoRoute(
    path: '/live',
    name: AppRoutes.live,
    pageBuilder: (context, state) => NoTransitionPage(
      key: const ValueKey('live-hub'),
      child: const FieldLiveHubPage(showMusicArchive: false),
    ),
    routes: [
      GoRoute(
        path: 'events/:eventId',
        name: AppRoutes.liveEventDetail,
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return buildAdaptiveDetailPage(
            key: state.pageKey,
            child: buildFieldLiveEventDetailPage(eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: 'artists/:unitId',
        name: AppRoutes.liveUnitDetail,
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
            name: AppRoutes.liveMemberDetail,
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
        name: AppRoutes.liveVoiceActorDetail,
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
    ],
  ),
  GoRoute(
    path: '/live/music',
    name: AppRoutes.musicArchive,
    pageBuilder: (context, state) => NoTransitionPage(
      key: const ValueKey('live-hub'),
      child: const FieldLiveHubPage(showMusicArchive: true),
    ),
    routes: [
      GoRoute(
        path: 'songs/:songId',
        name: AppRoutes.musicSongDetail,
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
            child: ProtectedReadGate(
              child: MusicSongDetailPage(
                projectId: projectId,
                songId: songId,
                eventId: eventId?.isEmpty == true ? null : eventId,
              ),
            ),
          );
        },
      ),
    ],
  ),
];
