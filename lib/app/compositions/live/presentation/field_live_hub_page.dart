/// EN: Live branch hub (PR9 IA, shell index 2): switches between the
/// EN: schedule (スケジュール) segment and the music/artist archive
/// EN: (楽曲・アーティスト) segment. `/live` and `/live/music` are two
/// EN: canonical roots of the same stable hub — segment switches use `go`,
/// EN: detail entry uses `push`; the hub is never stacked twice.
/// KO: 라이브 분기 허브(PR9 IA, 쉘 인덱스 2): スケジュール 세그먼트와
/// KO: 楽曲・アーティスト 아카이브 세그먼트를 전환합니다. `/live`와
/// KO: `/live/music`는 같은 안정적 허브의 두 canonical 루트입니다 — 세그먼트
/// KO: 전환은 `go`, 상세 진입은 `push`를 사용하며 허브를 두 겹 쌓지 않습니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/app/compositions/live/live_host.dart';
import '../../guide/presentation/field_guide/field_guide_music_page.dart';
import '../../../session/protected_read_gate.dart';

enum _LiveHubSegment { schedule, archive }

/// EN: Hosts the live schedule and the music/artist archive under one
/// EN: stable branch.
/// KO: 라이브 스케줄과 음악/아티스트 아카이브를 하나의 안정적인 분기
/// KO: 아래 호스팅합니다.
class FieldLiveHubPage extends ConsumerStatefulWidget {
  const FieldLiveHubPage({super.key, required this.showMusicArchive});

  /// EN: True on `/live/music` (name `music-archive`); false on `/live`.
  /// KO: `/live/music`(이름 `music-archive`)이면 true, `/live`이면 false.
  final bool showMusicArchive;

  @override
  ConsumerState<FieldLiveHubPage> createState() => _FieldLiveHubPageState();
}

class _FieldLiveHubPageState extends ConsumerState<FieldLiveHubPage> {
  bool _scheduleVisited = false;
  bool _archiveVisited = false;

  void _selectSegment(_LiveHubSegment segment) {
    final current = GoRouterState.of(context).uri;
    context.go(
      current
          .replace(
            path: segment == _LiveHubSegment.archive ? '/live/music' : '/live',
          )
          .toString(),
    );
  }

  Widget _archive(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final query = uri.queryParameters;
    return ProtectedReadGate(
      child: FieldGuideMusicPage(
        embedded: true,
        initialSection: query['archiveSection'] ?? 'songs',
        initialUnitKey: query['unit'],
        initialQuery: query['q'] ?? '',
        initialSort: query['sort'] ?? 'title',
        initialAlbumType: query['albumType'],
        onSelectionChanged: (selection) {
          final next = Map<String, dynamic>.from(uri.queryParametersAll);
          for (final key in [
            'archiveSection',
            'unit',
            'q',
            'sort',
            'albumType',
          ]) {
            next.remove(key);
          }
          next.addAll(selection);
          context.go(
            uri.replace(path: '/live/music', queryParameters: next).toString(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.showMusicArchive
        ? _LiveHubSegment.archive
        : _LiveHubSegment.schedule;
    _scheduleVisited |= selected == _LiveHubSegment.schedule;
    _archiveVisited |= selected == _LiveHubSegment.archive;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.pageHorizontal,
                vertical: GBTSpacing.sm,
              ),
              child: SegmentedButton<_LiveHubSegment>(
                key: const Key('field-live-hub-segment'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _LiveHubSegment.schedule,
                    label: Text(
                      context.l10n(ko: '스케줄', en: 'Schedule', ja: 'スケジュール'),
                    ),
                  ),
                  ButtonSegment(
                    value: _LiveHubSegment.archive,
                    label: Text(
                      context.l10n(
                        ko: '악곡·아티스트',
                        en: 'Music & Artists',
                        ja: '楽曲・アーティスト',
                      ),
                    ),
                  ),
                ],
                selected: {selected},
                onSelectionChanged: (selection) =>
                    _selectSegment(selection.single),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: selected.index,
                children: [
                  TickerMode(
                    enabled: selected == _LiveHubSegment.schedule,
                    child: _scheduleVisited
                        ? buildFieldLiveEventsPage(embedded: true)
                        : const SizedBox.shrink(),
                  ),
                  TickerMode(
                    enabled: selected == _LiveHubSegment.archive,
                    child: _archiveVisited
                        ? _archive(context)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
