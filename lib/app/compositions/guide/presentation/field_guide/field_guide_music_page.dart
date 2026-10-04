/// EN: Routed music archive with URL-backed discovery choices.
/// KO: 탐색 선택을 URL로 복원하는 음악 아카이브입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/pages/unit_detail_page.dart';
import 'package:oshi_log/features/oshikatsu/music/presentation/widgets/music_catalog_tab.dart';

class FieldGuideMusicPage extends StatefulWidget {
  const FieldGuideMusicPage({
    super.key,
    this.embedded = false,
    this.initialSection = 'songs',
    this.initialUnitKey,
    this.initialQuery = '',
    this.initialSort = 'title',
    this.initialAlbumType,
    this.onSelectionChanged,
  });

  final bool embedded;
  final String initialSection;
  final String? initialUnitKey;
  final String initialQuery;
  final String initialSort;
  final String? initialAlbumType;
  final ValueChanged<Map<String, String>>? onSelectionChanged;

  @override
  State<FieldGuideMusicPage> createState() => _FieldGuideMusicPageState();
}

class _FieldGuideMusicPageState extends State<FieldGuideMusicPage> {
  late Map<String, String> _selection;

  @override
  void initState() {
    super.initState();
    _readSelection();
  }

  void _readSelection() {
    _selection = {
      'archiveSection':
          ['songs', 'albums', 'members'].contains(widget.initialSection)
          ? widget.initialSection
          : 'songs',
      if (widget.initialUnitKey != null) 'unit': widget.initialUnitKey!,
      if (widget.initialQuery.isNotEmpty) 'q': widget.initialQuery,
      'sort': widget.initialSort,
      if (widget.initialAlbumType != null)
        'albumType': widget.initialAlbumType!,
    };
  }

  @override
  void didUpdateWidget(covariant FieldGuideMusicPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection ||
        oldWidget.initialUnitKey != widget.initialUnitKey ||
        oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialSort != widget.initialSort ||
        oldWidget.initialAlbumType != widget.initialAlbumType) {
      _readSelection();
    }
  }

  void _select(Map<String, String> selection) {
    setState(() => _selection = selection);
    widget.onSelectionChanged?.call(Map.unmodifiable(selection));
  }

  @override
  Widget build(BuildContext context) {
    final section = _selection['archiveSection']!;
    final body = Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          child: Row(
            children: [
              for (final entry in {
                'songs': context.l10n(ko: '곡', en: 'Songs', ja: '曲'),
                'albums': context.l10n(ko: '앨범', en: 'Albums', ja: 'アルバム'),
                'members': context.l10n(ko: '멤버', en: 'Members', ja: 'メンバー'),
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: GBTSpacing.xs),
                  child: ChoiceChip(
                    key: ValueKey('music-archive-${entry.key}'),
                    label: Text(entry.value),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    selected: section == entry.key,
                    onSelected: (_) =>
                        _select({..._selection, 'archiveSection': entry.key}),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: section == 'members'
              ? _ArchiveMembers(
                  unitKey: _selection['unit'],
                  onUnitSelected: (unit) =>
                      _select({..._selection, 'unit': unit}),
                )
              : MusicCatalogTab(
                  showPageHeader: !widget.embedded,
                  showViewSwitcher: false,
                  initialSection: section,
                  initialUnitKey: _selection['unit'],
                  initialQuery: _selection['q'] ?? '',
                  initialSort: _selection['sort'] ?? 'title',
                  initialAlbumType: _selection['albumType'],
                  onSelectionChanged: _select,
                ),
        ),
      ],
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '음악·아티스트',
          en: 'Music & artists',
          ja: '楽曲・アーティスト',
        ),
      ),
      body: body,
    );
  }
}

/// EN: Fetch members only for the selected band, preserving identity boundaries.
/// KO: 선택한 밴드의 멤버만 조회하고 캐릭터와 실제 인물을 구분합니다.
class _ArchiveMembers extends ConsumerWidget {
  const _ArchiveMembers({required this.unitKey, required this.onUnitSelected});

  final String? unitKey;
  final ValueChanged<String> onUnitSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(selectedProjectKeyProvider);
    if (projectId == null || projectId.isEmpty) {
      return Center(
        child: Text(
          context.l10n(
            ko: '프로젝트를 선택해주세요',
            en: 'Choose a project',
            ja: 'プロジェクトを選択してください',
          ),
        ),
      );
    }
    final units = ref.watch(projectUnitsControllerProvider(projectId));
    return units.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () =>
              ref.invalidate(projectUnitsControllerProvider(projectId)),
          child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
        ),
      ),
      data: (items) {
        Unit? selected;
        for (final unit in items) {
          if (unitKey == 'id:${unit.id}' ||
              unitKey == 'name:${unit.displayName}') {
            selected = unit;
            break;
          }
        }
        final unit = selected;
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
              child: Row(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(right: GBTSpacing.xs),
                      child: ChoiceChip(
                        label: Text(item.displayName),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        selected: item.id == unit?.id,
                        onSelected: (_) => onUnitSelected('id:${item.id}'),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: unit == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(GBTSpacing.md),
                        child: Text(
                          context.l10n(
                            ko: items.isEmpty
                                ? '등록된 밴드가 없습니다.'
                                : '밴드를 선택해 캐릭터와 연결된 성우·연주자를 확인하세요.',
                            en: items.isEmpty
                                ? 'No bands registered.'
                                : 'Choose a band to explore characters and linked voice actors or performers.',
                            ja: items.isEmpty
                                ? '登録されたバンドはありません。'
                                : 'バンドを選び、キャラクターと関連する声優・演奏者を確認できます。',
                          ),
                        ),
                      ),
                    )
                  : UnitDossierView(
                      unit: unit,
                      membersState: ref.watch(
                        unitMembersControllerProvider((
                          projectId,
                          unit.code.isEmpty ? unit.id : unit.code,
                        )),
                      ),
                      onMemberTap: (member) => context.goToMemberDetail(
                        unitIdentifier: unit.code.isEmpty ? unit.id : unit.code,
                        memberId: member.id,
                        projectId: projectId,
                        extra: {'member': member, 'unit': unit},
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
