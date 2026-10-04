/// EN: Band filter sheet for selecting project units.
/// KO: 프로젝트 유닛을 밴드로 선택하는 필터 시트.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import '../../application/projects_controller.dart';
import '../../domain/entities/project_entities.dart';

/// EN: Open the band filter sheet for a project.
/// KO: 프로젝트 밴드 필터 시트를 엽니다.
Future<void> showBandFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String projectKey,
  required List<String> selectedBandIds,
  required ValueChanged<List<String>> onApply,
}) async {
  final controller = projectUnitsControllerProvider(projectKey);
  final state = ref.read(controller);
  if (state is! AsyncData<List<Unit>>) {
    await ref.read(controller.notifier).load(forceRefresh: true);
  }

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BandFilterSheet(
      projectKey: projectKey,
      initialSelection: selectedBandIds,
      onApply: onApply,
    ),
  );
}

class _BandFilterSheet extends ConsumerStatefulWidget {
  const _BandFilterSheet({
    required this.projectKey,
    required this.initialSelection,
    required this.onApply,
  });

  final String projectKey;
  final List<String> initialSelection;
  final ValueChanged<List<String>> onApply;

  @override
  ConsumerState<_BandFilterSheet> createState() => _BandFilterSheetState();
}

class _BandFilterSheetState extends ConsumerState<_BandFilterSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectUnitsControllerProvider(widget.projectKey));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: state.when(
          loading: () => GBTLoading(
            message: context.l10n(
              ko: '밴드를 불러오는 중...',
              en: 'Loading bands...',
              ja: 'バンドを読み込み中...',
            ),
          ),
          error: (error, _) {
            final message = error is Failure
                ? error.userMessage
                : context.l10n(
                    ko: '밴드를 불러오지 못했어요',
                    en: 'Failed to load bands',
                    ja: 'バンドを読み込めませんでした',
                  );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GBTTypography.bodySmall.copyWith(
                    color: GBTColors.textSecondary,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                TextButton(
                  onPressed: () => ref
                      .read(
                        projectUnitsControllerProvider(
                          widget.projectKey,
                        ).notifier,
                      )
                      .load(forceRefresh: true),
                  child: Text(
                    context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                  ),
                ),
              ],
            );
          },
          data: (units) {
            if (units.isEmpty) {
              return Center(
                child: Text(
                  context.l10n(
                    ko: '밴드 정보가 없습니다',
                    en: 'No band information',
                    ja: 'バンド情報がありません',
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n(ko: '밴드 선택', en: 'Select bands', ja: 'バンド選択'),
                  style: GBTTypography.titleMedium,
                ),
                const SizedBox(height: GBTSpacing.md),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      final isSelected = _selected.contains(unit.id);
                      final name = unit.code.isNotEmpty
                          ? unit.code
                          : unit.displayName;
                      final description = unit.displayName != name
                          ? unit.displayName
                          : '';
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selected.add(unit.id);
                            } else {
                              _selected.remove(unit.id);
                            }
                          });
                        },
                        isThreeLine: description.isNotEmpty,
                        title: Text(name),
                        subtitle: description.isNotEmpty
                            ? Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _selected.clear());
                        },
                        child: Text(
                          context.l10n(ko: '초기화', en: 'Reset', ja: 'リセット'),
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          widget.onApply(_selected.toList());
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          context.l10n(ko: '적용', en: 'Apply', ja: '適用'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
