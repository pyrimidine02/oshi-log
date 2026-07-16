/// EN: Project context selector for the Urban Travel Field Notes surfaces.
/// KO: Urban Travel Field Notes 화면을 위한 프로젝트 컨텍스트 선택기입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../application/projects_controller.dart';
import '../../domain/entities/project_entities.dart';
import 'field_project_picker_sheet.dart';

/// EN: A quiet, borderless control that keeps the travel context visible.
/// KO: 여행 기준을 자연스럽게 보여주는 차분한 무테 컨트롤입니다.
class FieldProjectLens extends ConsumerWidget {
  const FieldProjectLens({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    return projectsState.when(
      loading: () => const _ProjectLensSkeleton(),
      error: (_, __) => _ProjectLensMessage(
        message: context.l10n(
          ko: '프로젝트를 불러오지 못했어요',
          en: 'Could not load projects',
          ja: 'プロジェクトを読み込めませんでした',
        ),
        actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
        onAction: () => ref
            .read(projectsControllerProvider.notifier)
            .load(forceRefresh: true),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return _ProjectLensMessage(
            message: context.l10n(
              ko: '선택할 프로젝트가 없어요',
              en: 'No projects available',
              ja: '選択できるプロジェクトがありません',
            ),
          );
        }
        // EN: Initialization belongs only to ProjectSelectionController. The
        // lens renders a temporary fallback without writing provider state.
        // KO: 초기화는 ProjectSelectionController만 담당합니다. 렌즈는
        // 프로바이더 상태를 쓰지 않고 임시 기본값만 표시합니다.
        final selected = _resolveProject(projects, selection.projectKey);
        return _ProjectLensButton(
          project: selected,
          onTap: () => _showProjectPicker(context, ref, projects, selected),
        );
      },
    );
  }

  Future<void> _showProjectPicker(
    BuildContext context,
    WidgetRef ref,
    List<Project> projects,
    Project selected,
  ) async {
    final picked = await showFieldProjectPicker(
      context: context,
      projects: projects,
      selectedProject: selected,
    );
    if (picked == null ||
        !context.mounted ||
        _projectKey(picked) == _projectKey(selected)) {
      return;
    }
    await ref
        .read(projectSelectionControllerProvider.notifier)
        .selectProject(_projectKey(picked), projectId: picked.id);
  }
}

class _ProjectLensButton extends StatelessWidget {
  const _ProjectLensButton({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showSwitchIcon = MediaQuery.textScalerOf(context).scale(1) < 1.6;
    return Semantics(
      button: true,
      enabled: true,
      excludeSemantics: true,
      label: context.l10n(
        ko: '현재 프로젝트 ${project.name}',
        en: 'Current project ${project.name}',
        ja: '現在のプロジェクト ${project.name}',
      ),
      hint: context.l10n(
        ko: '탭하면 여행 기준을 바꿀 수 있어요',
        en: 'Tap to switch travel context',
        ja: 'タップして旅の基準を切り替えます',
      ),
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
          child: ConstrainedBox(
            key: const ValueKey('field-project-lens-control'),
            constraints: const BoxConstraints(
              minHeight: GBTSpacing.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.xs,
                vertical: GBTSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n(
                            ko: '여행 기준',
                            en: 'TRAVEL CONTEXT',
                            ja: '旅の基準',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Text(
                    context.l10n(ko: '전환', en: 'SWITCH', ja: '切替'),
                    maxLines: 1,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  if (showSwitchIcon) ...[
                    const SizedBox(width: GBTSpacing.xs),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 19,
                      color: colors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectLensMessage extends StatelessWidget {
  const _ProjectLensMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      child: Row(
        children: [
          Expanded(
            child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _ProjectLensSkeleton extends StatelessWidget {
  const _ProjectLensSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      child: Row(
        children: [
          Container(width: 3, height: 32, color: colors.primary),
          const SizedBox(width: GBTSpacing.md),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 128,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Project _resolveProject(List<Project> projects, String? key) {
  return projects.firstWhere(
    (project) => project.id == key || project.code == key,
    orElse: () => projects.first,
  );
}

String _projectKey(Project project) {
  return project.code.isNotEmpty ? project.code : project.id;
}
