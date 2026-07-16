/// EN: Project selector widget — compact horizontal pill list (Blip-style).
/// KO: 프로젝트 선택 위젯 — 컴팩트 가로 필 리스트 (블립 스타일).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_pressable.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../application/projects_controller.dart';
import '../../domain/entities/project_entities.dart';
import 'field_project_picker_sheet.dart';

/// EN: Full project selector — compact pill row.
/// KO: 전체 프로젝트 선택기 — 컴팩트 필 행.
class ProjectSelector extends ConsumerWidget {
  const ProjectSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    return projectsState.when(
      loading: () => const _ShimmerPillRow(),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '프로젝트를 불러오지 못했어요',
                en: 'Failed to load projects',
                ja: 'プロジェクトを読み込めませんでした',
              );
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  message,
                  style: GBTTypography.bodySmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              TextButton(
                onPressed: () => ref
                    .read(projectsControllerProvider.notifier)
                    .load(forceRefresh: true),
                child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
              ),
            ],
          ),
        );
      },
      data: (projects) {
        if (projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.pageHorizontal,
            ),
            child: Text(
              context.l10n(
                ko: '등록된 프로젝트가 없습니다',
                en: 'No projects available',
                ja: '登録されたプロジェクトがありません',
              ),
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
            ),
          );
        }

        _ensureProjectSelection(ref, selection, projects);
        final selectedProject = _resolveSelectedProject(selection, projects);
        return _ProjectPillRow(
          projects: projects,
          selectedProject: selectedProject,
        );
      },
    );
  }
}

/// EN: Compact project selector — same pill row, no extra spacing.
/// KO: 컴팩트 프로젝트 선택기 — 동일한 필 행, 추가 간격 없음.
class ProjectSelectorCompact extends ConsumerWidget {
  const ProjectSelectorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    return projectsState.when(
      loading: () => const _ShimmerPillRow(),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '프로젝트를 불러오지 못했어요',
                en: 'Failed to load projects',
                ja: 'プロジェクトを読み込めませんでした',
              );
        return Text(
          message,
          style: GBTTypography.bodySmall.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
        );
      },
      data: (projects) {
        if (projects.isEmpty) {
          return Text(
            context.l10n(
              ko: '등록된 프로젝트가 없습니다',
              en: 'No projects available',
              ja: '登録されたプロジェクトがありません',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          );
        }

        _ensureProjectSelection(ref, selection, projects);
        final selectedProject = _resolveSelectedProject(selection, projects);
        return _ProjectPillRow(
          projects: projects,
          selectedProject: selectedProject,
        );
      },
    );
  }
}

/// EN: Compact project selector for editors — single dropdown-style control.
/// KO: 에디터 전용 컴팩트 프로젝트 선택기 — 단일 드롭다운 스타일 컨트롤.
class ProjectDropdownSelectorCompact extends ConsumerWidget {
  const ProjectDropdownSelectorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    return projectsState.when(
      loading: () => const _ShimmerDropdownField(),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '프로젝트를 불러오지 못했어요',
                en: 'Failed to load projects',
                ja: 'プロジェクトを読み込めませんでした',
              );
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            message,
            style: GBTTypography.bodySmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          ),
        );
      },
      data: (projects) {
        if (projects.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n(
                ko: '등록된 프로젝트가 없습니다',
                en: 'No projects available',
                ja: '登録されたプロジェクトがありません',
              ),
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
            ),
          );
        }

        _ensureProjectSelection(ref, selection, projects);
        final selectedProject = _resolveSelectedProject(selection, projects);
        return _ProjectDropdownField(
          projects: projects,
          selectedProject: selectedProject,
        );
      },
    );
  }
}

/// EN: Audience-like compact selector for compose screens.
/// KO: 작성 화면용 오디언스 스타일 컴팩트 선택기입니다.
class ProjectAudienceSelectorCompact extends ConsumerWidget {
  const ProjectAudienceSelectorCompact({
    super.key,
    this.onProjectSelected,
    this.dense = false,
  });

  final ValueChanged<Project>? onProjectSelected;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    return projectsState.when(
      loading: () => const _ShimmerAudienceChip(),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '프로젝트를 불러오지 못했어요',
                en: 'Failed to load projects',
                ja: 'プロジェクトを読み込めませんでした',
              );
        return Text(
          message,
          style: GBTTypography.bodySmall.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
        );
      },
      data: (projects) {
        if (projects.isEmpty) {
          return Text(
            context.l10n(
              ko: '등록된 프로젝트가 없습니다',
              en: 'No projects available',
              ja: '登録されたプロジェクトがありません',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          );
        }

        _ensureProjectSelection(ref, selection, projects);
        final selectedProject = _resolveSelectedProject(selection, projects);
        return _ProjectAudienceChip(
          projects: projects,
          selectedProject: selectedProject,
          onProjectSelected: onProjectSelected,
          dense: dense,
        );
      },
    );
  }
}

// ========================================
// EN: Horizontal compact pill row
// KO: 가로 컴팩트 필 행
// ========================================

class _ProjectPillRow extends ConsumerWidget {
  const _ProjectPillRow({
    required this.projects,
    required this.selectedProject,
  });

  final List<Project> projects;
  final Project selectedProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
      ),
      child: Row(
        children: [
          for (int i = 0; i < projects.length; i++) ...[
            if (i > 0) const SizedBox(width: GBTSpacing.sm),
            _ProjectPill(
              project: projects[i],
              isSelected: projects[i].id == selectedProject.id,
              onTap: () => _selectProject(ref, projects[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectDropdownField extends ConsumerWidget {
  const _ProjectDropdownField({
    required this.projects,
    required this.selectedProject,
  });

  final List<Project> projects;
  final Project selectedProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final subtitleColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final borderColor = isDark
        ? GBTColors.darkBorder.withValues(alpha: 0.7)
        : GBTColors.border.withValues(alpha: 0.9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        onTap: () => _openProjectSheet(context, ref),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            border: Border.all(color: borderColor, width: 0.7),
          ),
          child: Row(
            children: [
              Icon(Icons.layers_outlined, size: 16, color: subtitleColor),
              const SizedBox(width: GBTSpacing.xs),
              Text(
                context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト'),
                style: GBTTypography.labelMedium.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Expanded(
                child: Text(
                  selectedProject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.bodyMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProjectSheet(BuildContext context, WidgetRef ref) async {
    final selectedId = await _openProjectPickerSheet(
      context: context,
      projects: projects,
      selectedProjectId: selectedProject.id,
      sheetTitle: '프로젝트 선택',
    );
    if (selectedId == null) {
      return;
    }
    final next = projects.firstWhere(
      (project) => project.id == selectedId,
      orElse: () => selectedProject,
    );
    if (next.id == selectedProject.id) {
      return;
    }
    _selectProject(ref, next);
  }
}

class _ProjectAudienceChip extends ConsumerWidget {
  const _ProjectAudienceChip({
    required this.projects,
    required this.selectedProject,
    this.onProjectSelected,
    this.dense = false,
  });

  final List<Project> projects;
  final Project selectedProject;
  final ValueChanged<Project>? onProjectSelected;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? GBTColors.darkPrimary.withValues(alpha: 0.85)
        : GBTColors.primary;
    final textColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final chipHeight = dense ? 28.0 : 32.0;
    final iconSize = dense ? 12.0 : 14.0;
    final arrowSize = dense ? 14.0 : 16.0;
    final textStyle = GBTTypography.labelMedium.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      fontSize: dense ? 12 : null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        onTap: () async {
          final selectedId = await _openProjectPickerSheet(
            context: context,
            projects: projects,
            selectedProjectId: selectedProject.id,
            sheetTitle: '프로젝트 선택',
          );
          if (selectedId == null) {
            return;
          }
          final next = projects.firstWhere(
            (project) => project.id == selectedId,
            orElse: () => selectedProject,
          );
          if (next.id == selectedProject.id) {
            onProjectSelected?.call(next);
            return;
          }
          _selectProject(ref, next);
          onProjectSelected?.call(next);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: chipHeight,
              padding: EdgeInsets.symmetric(
                horizontal: dense ? GBTSpacing.xs : GBTSpacing.xs2,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: iconSize,
                    color: textColor,
                  ),
                  const SizedBox(width: GBTSpacing.xs),
                  Flexible(
                    child: Text(
                      selectedProject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: arrowSize,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Single pill item — compact inline avatar + name
// KO: 단일 필 항목 — 컴팩트 인라인 아바타 + 이름
// ========================================

class _ProjectPill extends StatelessWidget {
  const _ProjectPill({
    required this.project,
    required this.isSelected,
    required this.onTap,
  });

  final Project project;
  final bool isSelected;
  final VoidCallback onTap;

  // EN: Deterministic palette — each project gets a stable color via hashCode.
  // KO: 결정적 팔레트 — 각 프로젝트가 hashCode로 고정 색상을 받음.
  static const _avatarPalette = [
    Color(0xFF6366F1), // indigo
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFF8B5CF6), // violet
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paletteColor =
        _avatarPalette[project.name.hashCode.abs() % _avatarPalette.length];

    // EN: Colors per state.
    // KO: 상태별 색상.
    final Color bgColor;
    final Color textColor;

    if (isSelected) {
      bgColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
      textColor = isDark ? GBTColors.darkBackground : GBTColors.textInverse;
    } else {
      // EN: Ghost pill — surface + hairline border keeps unselected pills
      //     quiet so the selected one carries the color.
      // KO: 고스트 필 — 표면색 + 헤어라인 보더로 비선택 필을 차분하게 두어
      //     선택된 필에만 컬러가 실리도록 합니다.
      bgColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
      textColor = isDark
          ? GBTColors.darkTextSecondary
          : GBTColors.textSecondary;
    }

    return Semantics(
      label:
          '${project.name} ${context.l10n(ko: "프로젝트", en: "project", ja: "プロジェクト")}${isSelected ? ', ${context.l10n(ko: "선택됨", en: "selected", ja: "選択済み")}' : ''}',
      button: true,
      selected: isSelected,
      child: GBTPressable(
        onTap: onTap,
        hapticType: GBTHapticType.selection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            // EN: Selected glow follows the pill's own primary fill —
            //     mixing the project palette color here clashed with it.
            // KO: 선택 글로우는 필 자체의 프라이머리 채움색을 따름 —
            //     프로젝트 팔레트색을 섞으면 충돌이 났습니다.
            border: isSelected
                ? Border.all(color: Colors.transparent, width: 1.5)
                : Border.all(
                    color: isDark ? GBTColors.darkBorder : GBTColors.border,
                    width: 1.0,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN: Small avatar circle (20px).
              // KO: 작은 아바타 원 (20px).
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // EN: Unselected avatar is a soft palette tint (not a
                  //     saturated dot) so the row stays calm. The selected
                  //     avatar gains a white ring — an unmistakable active
                  //     marker (Weverse-style filled ring).
                  // KO: 비선택 아바타는 채도 높은 점 대신 은은한 팔레트
                  //     틴트로 두어 행 전체가 차분하게 유지됩니다. 선택된
                  //     아바타에는 화이트 링을 둘러 활성 상태를 명확히
                  //     표시합니다 (위버스식 링 마커).
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : paletteColor.withValues(alpha: 0.15),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? textColor : paletteColor,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              // EN: Project name.
              // KO: 프로젝트 이름.
              AnimatedDefaultTextStyle(
                duration: GBTAnimations.normal,
                curve: GBTAnimations.defaultCurve,
                style: GBTTypography.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Shimmer loading pills
// KO: 쉬머 로딩 필
// ========================================

class _ShimmerPillRow extends StatelessWidget {
  const _ShimmerPillRow();

  static const _widths = [80.0, 96.0, 72.0, 88.0];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return GBTShimmer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.pageHorizontal,
        ),
        child: Row(
          children: [
            for (int i = 0; i < _widths.length; i++) ...[
              if (i > 0) const SizedBox(width: GBTSpacing.sm),
              Container(
                width: _widths[i],
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShimmerDropdownField extends StatelessWidget {
  const _ShimmerDropdownField();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GBTColors.darkSurfaceVariant : GBTColors.surface;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;

    return GBTShimmer(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          border: Border.all(color: borderColor, width: 0.7),
        ),
      ),
    );
  }
}

class _ShimmerAudienceChip extends StatelessWidget {
  const _ShimmerAudienceChip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.35)
        : GBTColors.surface;

    return GBTShimmer(
      child: Container(
        width: 120,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          border: Border.all(color: borderColor, width: 1.0),
        ),
      ),
    );
  }
}

// ========================================
// EN: Top-level helpers
// KO: 톱레벨 헬퍼
// ========================================

void _ensureProjectSelection(
  WidgetRef ref,
  ProjectSelectionState selection,
  List<Project> projects,
) {
  if (selection.projectKey != null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref
        .read(projectSelectionControllerProvider.notifier)
        .selectProject(
          _projectKeyFor(projects.first),
          projectId: projects.first.id,
        );
  });
}

Project _resolveSelectedProject(
  ProjectSelectionState selection,
  List<Project> projects,
) {
  return projects.firstWhere(
    (project) =>
        project.code == selection.projectKey ||
        project.id == selection.projectKey,
    orElse: () => projects.first,
  );
}

String _projectKeyFor(Project project) {
  return project.code.isNotEmpty ? project.code : project.id;
}

void _selectProject(WidgetRef ref, Project project) {
  final targetProjectKey = _projectKeyFor(project);
  ref
      .read(projectSelectionControllerProvider.notifier)
      .selectProject(targetProjectKey, projectId: project.id);
}

Future<String?> _openProjectPickerSheet({
  required BuildContext context,
  required List<Project> projects,
  required String selectedProjectId,
  required String sheetTitle,
}) async {
  // EN: `sheetTitle` remains in the private API for source compatibility;
  // the shared field-notes sheet owns localized copy and hierarchy.
  // KO: `sheetTitle`은 소스 호환성을 위해 유지하며, 지역화 문구와 위계는
  // 공용 필드 노트 시트가 책임집니다.
  assert(sheetTitle.isNotEmpty);
  final selectedProject = projects.firstWhere(
    (project) => project.id == selectedProjectId,
    orElse: () => projects.first,
  );
  final picked = await showFieldProjectPicker(
    context: context,
    projects: projects,
    selectedProject: selectedProject,
  );
  return picked?.id;
}
