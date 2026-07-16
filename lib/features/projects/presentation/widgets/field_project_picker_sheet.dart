/// EN: Shared project-context picker for the field-notes experience.
/// KO: 필드 노트 경험에서 공용으로 사용하는 프로젝트 컨텍스트 선택기입니다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/project_entities.dart';
import 'fan_subject_preference_sheet.dart';

/// EN: Opens the shared project picker and returns the tapped project.
/// KO: 공용 프로젝트 선택기를 열고 탭한 프로젝트를 반환합니다.
Future<Project?> showFieldProjectPicker({
  required BuildContext context,
  required List<Project> projects,
  required Project selectedProject,
}) {
  return showModalBottomSheet<Project>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.44),
    builder: (sheetContext) => FieldProjectPickerSheet(
      projects: projects,
      selectedId: selectedProject.id,
      onConfirm: (project) => Navigator.of(sheetContext).pop(project),
      onManageSubjects: () => showFanSubjectPreferenceSheet(
        context: sheetContext,
        projectId: selectedProject.code.isNotEmpty
            ? selectedProject.code
            : selectedProject.id,
      ),
    ),
  );
}

/// EN: A direct, single-tap project switcher with accessible destination rows.
/// KO: 접근성을 갖춘 목적지 행으로 구성한 단일 탭 프로젝트 전환기입니다.
class FieldProjectPickerSheet extends StatelessWidget {
  const FieldProjectPickerSheet({
    super.key,
    required this.projects,
    required this.selectedId,
    required this.onConfirm,
    this.onManageSubjects,
  }) : assert(projects.length > 0, 'At least one project is required.');

  final List<Project> projects;
  final String selectedId;
  final ValueChanged<Project> onConfirm;
  final VoidCallback? onManageSubjects;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1);
    final scaleAllowance = ((textScale - 1).clamp(0.0, 1.0) * 144).toDouble();
    final visibleRows = math.min(projects.length, 5);
    final contentHeight = 196.0 + (visibleRows * 72) + scaleAllowance;
    final height = math.min(mediaQuery.size.height * 0.84, contentHeight);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: height,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const _SheetHandle(),
                _PickerHeader(
                  onClose: () => Navigator.maybePop(context),
                  onManageSubjects: onManageSubjects,
                ),
                Divider(height: 1, color: colors.outlineVariant),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      GBTSpacing.lg,
                      GBTSpacing.sm,
                      GBTSpacing.lg,
                      GBTSpacing.md,
                    ),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _ProjectRow(
                        key: ValueKey('field-project-row-${project.id}'),
                        project: project,
                        selected: project.id == selectedId,
                        onTap: () => onConfirm(project),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.sm),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.onClose, this.onManageSubjects});

  final VoidCallback onClose;
  final VoidCallback? onManageSubjects;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.lg,
        GBTSpacing.sm,
        GBTSpacing.sm,
        GBTSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(ko: '여행의 기준', en: 'TRAVEL CONTEXT', ja: '旅の基準'),
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '어느 세계로 여행할까요?',
                    en: 'Where do you want to travel?',
                    ja: 'どの世界を旅しますか？',
                  ),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '성지·일정·도감이 선택한 프로젝트 기준으로 바뀝니다',
                    en: 'Places, schedules, and collections follow the selected project.',
                    ja: '聖地・予定・図鑑は選んだプロジェクトに合わせて切り替わります。',
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onManageSubjects != null)
            IconButton(
              key: const ValueKey('manage-fan-subjects'),
              tooltip: context.l10n(
                ko: '\uAD00\uC2EC \uB300\uC0C1 \uAD00\uB9AC',
                en: 'Manage interests',
                ja: '\u95A2\u5FC3\u5BFE\u8C61\u3092\u7BA1\u7406',
              ),
              onPressed: onManageSubjects,
              icon: const Icon(Icons.interests_rounded),
            ),
          IconButton(
            tooltip: context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    super.key,
    required this.project,
    required this.selected,
    required this.onTap,
  });

  final Project project;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticsLabel = selected
        ? context.l10n(
            ko: '${project.name}, 현재 여행 기준',
            en: '${project.name}, current travel context',
            ja: '${project.name}、現在の旅の基準',
          )
        : project.name;

    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: semanticsLabel,
      hint: selected
          ? context.l10n(
              ko: '현재 선택입니다. 탭하면 닫힙니다',
              en: 'Currently selected. Tap to close.',
              ja: '現在選択中です。タップして閉じます。',
            )
          : context.l10n(
              ko: '탭하면 이 프로젝트로 바뀝니다',
              en: 'Tap to switch to this project',
              ja: 'タップしてこのプロジェクトに切り替えます',
            ),
      onTap: onTap,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.48)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? colors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.md,
                  vertical: GBTSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary.withValues(alpha: 0.12)
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusSm,
                        ),
                      ),
                      child: Icon(
                        selected ? Icons.explore_rounded : Icons.route_outlined,
                        size: 19,
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.md),
                    Expanded(
                      child: Text(
                        project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    if (selected)
                      _CurrentBadge(colors: colors)
                    else
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colors.outline,
                        size: 19,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.sm,
          vertical: GBTSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: colors.primary, size: 16),
            const SizedBox(width: 3),
            Text(
              context.l10n(ko: '현재', en: 'CURRENT', ja: '現在'),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
