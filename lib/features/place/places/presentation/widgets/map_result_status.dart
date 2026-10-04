/// EN: Honest filter scope and recovery actions for map results.
/// KO: 지도 결과의 필터 범위와 복구 동작을 정직하게 표시합니다.
library;

import 'package:flutter/material.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';

class MapFilterSummary extends StatelessWidget {
  const MapFilterSummary({super.key, required this.labels, this.onReset});
  final List<String> labels;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: GBTSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        '${context.l10n(ko: '현재 범위', en: 'Showing', ja: '表示範囲')}: '
        '${labels.join(' · ')}',
        key: const ValueKey('map-filter-summary'),
      ),
      if (onReset != null)
        TextButton(
          key: const ValueKey('map-reset-filters'),
          onPressed: onReset,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            context.l10n(ko: '필터 해제', en: 'Clear filters', ja: '絞り込みを解除'),
          ),
        ),
    ],
  );
}

class MapResultStatus extends StatelessWidget {
  const MapResultStatus({
    super.key,
    required this.locationUnavailable,
    required this.mapUnavailable,
    required this.onChooseRegion,
  });
  final bool locationUnavailable;
  final bool mapUnavailable;
  final VoidCallback onChooseRegion;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (mapUnavailable)
        Text(
          context.l10n(
            ko: '지도를 사용할 수 없어 목록을 표시합니다.',
            en: 'Map unavailable. Showing the place list.',
            ja: '地図を利用できないため一覧を表示しています。',
          ),
        ),
      if (locationUnavailable) ...[
        Text(
          context.l10n(
            ko: '현재 위치를 확인할 수 없습니다. 지역을 선택해 탐색할 수 있습니다.',
            en: 'Current location unavailable. You can browse by region.',
            ja: '現在地を確認できません。地域を選んで探せます。',
          ),
        ),
        TextButton.icon(
          key: const ValueKey('map-choose-region'),
          onPressed: onChooseRegion,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.public),
          label: Text(
            context.l10n(ko: '지역 선택', en: 'Choose region', ja: '地域を選択'),
          ),
        ),
      ],
    ],
  );
}
