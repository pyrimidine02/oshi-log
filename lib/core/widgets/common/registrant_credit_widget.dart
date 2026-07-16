/// EN: Compact credit widget displaying registrant and contributors for an entity.
/// KO: 엔티티의 최초 등록자 및 기여자를 표시하는 소형 크레딧 위젯.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/locale_text.dart';
import '../../models/registrant_dto.dart';
import '../../providers/registrant_provider.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_typography.dart';

/// EN: Shows registrant + contributor credits for a given entity.
/// KO: 특정 엔티티의 최초 등록자와 기여자 크레딧을 표시합니다.
///
/// - Renders nothing on empty list, all-null, or network error.
/// - Row 1 (person_add icon): original creator with registration date.
/// - Row 2 (edit icon): recent editors — "X님 외 N명이 기여" style.
///
/// - 빈 목록, 전부 null, 네트워크 오류 시 아무것도 렌더하지 않습니다.
/// - 1행 (person_add 아이콘): 날짜가 포함된 최초 등록자.
/// - 2행 (edit 아이콘): 최근 편집자 — "X님 외 N명이 기여" 형식.
class ContributorsCreditWidget extends ConsumerWidget {
  const ContributorsCreditWidget({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  /// EN: Entity type URL segment (e.g. `places`, `lives`).
  /// KO: URL 경로 세그먼트 (예: `places`, `lives`).
  final String entityType;

  /// EN: Entity UUID.
  /// KO: 엔티티 UUID.
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      contributorsProvider((entityType: entityType, entityId: entityId)),
    );

    return state.when(
      // EN: Show nothing during load — avoids layout shift.
      // KO: 로딩 중 아무것도 표시하지 않아 레이아웃 이동을 방지합니다.
      loading: () => const SizedBox.shrink(),
      // EN: Silently swallow errors — credits are supplemental info.
      // KO: 오류를 조용히 무시합니다 — 크레딧은 보조 정보입니다.
      error: (_, __) => const SizedBox.shrink(),
      data: (contributors) {
        if (contributors.isEmpty) return const SizedBox.shrink();

        final registrant = contributors
            .where((c) => c.isRegistrant)
            .firstOrNull;
        final editors = contributors.where((c) => !c.isRegistrant).toList();

        if (registrant == null && editors.isEmpty) {
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final color = isDark
            ? GBTColors.darkTextTertiary
            : GBTColors.textTertiary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (registrant != null)
              _CreditRow(
                icon: Icons.person_add_alt_1_outlined,
                label: _registrantLabel(context, registrant),
                color: color,
              ),
            if (registrant != null && editors.isNotEmpty)
              const SizedBox(height: 4),
            if (editors.isNotEmpty)
              _CreditRow(
                icon: Icons.edit_outlined,
                label: _editorsLabel(context, editors),
                color: color,
              ),
          ],
        );
      },
    );
  }

  // EN: Builds the registrant credit line.
  // KO: 최초 등록자 크레딧 문자열을 생성합니다.
  String _registrantLabel(BuildContext context, ContributorDto r) {
    final name =
        r.nickname ?? context.l10n(ko: '알 수 없음', en: 'Unknown', ja: '不明');
    final at = r.lastModifiedAt != null
        ? _formatDate(context, r.lastModifiedAt!)
        : null;

    if (at != null) {
      return context.l10n(
        ko: '$name님이 $at에 등록',
        en: 'Added by $name on $at',
        ja: '$name さんが $at に登録',
      );
    }
    return context.l10n(
      ko: '$name님이 등록',
      en: 'Added by $name',
      ja: '$name さんが登録',
    );
  }

  // EN: Builds the editors credit line ("X님 외 N명이 기여" style).
  // KO: 편집자 크레딧 문자열("X님 외 N명이 기여" 형식)을 생성합니다.
  String _editorsLabel(BuildContext context, List<ContributorDto> editors) {
    final first =
        editors.first.nickname ??
        context.l10n(ko: '알 수 없음', en: 'Unknown', ja: '不明');
    final rest = editors.length - 1;

    if (rest == 0) {
      return context.l10n(
        ko: '$first님이 기여',
        en: '$first contributed',
        ja: '$first さんが貢献',
      );
    }
    return context.l10n(
      ko: '$first님 외 $rest명이 기여',
      en: '$first and $rest others contributed',
      ja: '$first さんほか$rest名が貢献',
    );
  }

  // EN: Formats UTC DateTime to a locale-aware date string.
  // KO: UTC DateTime을 로케일 날짜 문자열로 포맷합니다.
  String _formatDate(BuildContext context, DateTime utcDate) {
    final d = utcDate.toLocal();
    final lang = Localizations.localeOf(context).languageCode;

    if (lang == 'en') {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
    if (lang == 'ja') return '${d.year}年${d.month}月${d.day}日';
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }
}

// EN: A single icon + text row for a credit entry.
// KO: 크레딧 항목 하나를 표시하는 아이콘 + 텍스트 행.
class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: GBTTypography.bodySmall.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
