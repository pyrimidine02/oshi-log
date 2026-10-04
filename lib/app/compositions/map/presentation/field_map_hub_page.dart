/// EN: Map branch hub (PR9 IA, shell index 1): switches between the places
/// EN: map (スポット) and zukan collections (スポット集). The URL owns the
/// EN: selected segment (`?section=collections`) so deep links and back
/// EN: navigation restore the same view; segment switches use `go` so the
/// EN: stable page key is never pushed twice.
/// KO: 지도 분기 허브(PR9 IA, 쉘 인덱스 1): 장소 지도(スポット)와 도감
/// KO: 컬렉션(スポット集)을 전환합니다. URL이 선택 세그먼트를
/// KO: (`?section=collections`) 소유하여 딥링크·뒤로가기가 같은 화면을
/// KO: 복원합니다. 세그먼트 전환은 안정적인 페이지 키가 두 번 push되지
/// KO: 않도록 `go`를 사용합니다.
library;

import 'package:flutter/material.dart';
import '../../../session/protected_read_gate.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/app/compositions/collections/collections_host.dart';
import 'package:oshi_log/app/compositions/places/places_map_host.dart';

enum _MapHubSegment { spots, collections }

/// EN: Hosts the places map and zukan collections under one stable route.
/// KO: 장소 지도와 도감 컬렉션을 하나의 안정적인 라우트 아래 호스팅합니다.
class FieldMapHubPage extends StatelessWidget {
  const FieldMapHubPage({super.key, required this.showCollections});

  /// EN: True when `?section=collections` selects the スポット集 segment.
  /// KO: `?section=collections`가 スポット集 세그먼트를 선택하면 true입니다.
  final bool showCollections;

  void _selectSegment(BuildContext context, _MapHubSegment segment) {
    if (segment == _MapHubSegment.collections) {
      context.go('/map?section=collections');
    } else {
      context.go('/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = showCollections
        ? _MapHubSegment.collections
        : _MapHubSegment.spots;
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.pageHorizontal,
                vertical: GBTSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SegmentedButton<_MapHubSegment>(
                  key: const Key('field-map-hub-segment'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _MapHubSegment.spots,
                      label: Text(
                        context.l10n(ko: '스폿', en: 'Spots', ja: 'スポット'),
                      ),
                    ),
                    ButtonSegment(
                      value: _MapHubSegment.collections,
                      label: Text(
                        context.l10n(ko: '스폿집', en: 'Collections', ja: 'スポット集'),
                      ),
                    ),
                  ],
                  selected: {selected},
                  onSelectionChanged: (selection) =>
                      _selectSegment(context, selection.single),
                ),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: IndexedStack(
                index: selected.index,
                children: [
                  PlacesMapHost(
                    embedded: true,
                    isActive: !showCollections,
                    bottomInset: MediaQuery.paddingOf(context).bottom,
                  ),
                  const ProtectedReadGate(
                    child: CollectionsHost(embedded: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
