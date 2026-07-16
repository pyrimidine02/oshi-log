/// EN: Full-page title catalog for browsing and applying user titles.
/// KO: 사용자 칭호를 탐색하고 적용하기 위한 전체 페이지 칭호 카탈로그.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../projects/application/projects_controller.dart';
import '../../application/titles_controller.dart';
import '../../domain/entities/title_entities.dart';

// =============================================================================
// EN: Category helper utilities
// KO: 카테고리 헬퍼 유틸리티
// =============================================================================

/// EN: Returns the Korean display label for [category].
/// KO: [category]에 해당하는 한국어 표시 레이블을 반환합니다.
String _categoryLabel(TitleCategory category) => switch (category) {
  TitleCategory.activity => '활동',
  TitleCategory.commemorative => '기념',
  TitleCategory.event => '이벤트',
  TitleCategory.admin => '특별',
};

/// EN: Returns the accent color associated with [category], drawn from the
/// Journey Ticket palette: mint (activity) → gold (commemorative) → violet
/// (event) → brand magenta (admin, the most special tier).
/// KO: [category]에 연결된 강조 색상 — "여정의 티켓" 팔레트에서 가져옵니다:
/// 민트(활동) → 골드(기념) → 바이올렛(이벤트) → 브랜드 마젠타(특별, 가장
/// 특별한 등급).
Color _categoryColor(TitleCategory category, bool isDark) => switch (category) {
  TitleCategory.activity => GBTSemanticColors.getDistanceColor(
    isDark ? Brightness.dark : Brightness.light,
  ),
  TitleCategory.commemorative =>
    isDark ? GBTColors.darkAccent : GBTColors.accent,
  TitleCategory.event => isDark ? GBTColors.darkSecondary : GBTColors.secondary,
  TitleCategory.admin => isDark ? GBTColors.darkPrimary : GBTColors.primary,
};

/// EN: Returns a representative icon for the given [category].
/// KO: 주어진 [category]에 대한 대표 아이콘을 반환합니다.
IconData _categoryIcon(TitleCategory category) => switch (category) {
  TitleCategory.activity => Icons.directions_walk_rounded,
  TitleCategory.commemorative => Icons.cake_rounded,
  TitleCategory.event => Icons.celebration_rounded,
  TitleCategory.admin => Icons.star_rounded,
};

// =============================================================================
// EN: TitleCatalogPage — ConsumerStatefulWidget
// KO: TitleCatalogPage — ConsumerStatefulWidget
// =============================================================================

/// EN: Full-page route for browsing and applying user titles.
///     Groups [TitleCatalogItem]s by category into a sectioned ListView.
///     Respects earned/active states with appropriate visual treatments.
/// KO: 사용자 칭호를 탐색하고 적용하기 위한 전체 페이지 라우트.
///     [TitleCatalogItem]을 카테고리별로 분리하여 섹션 ListView로 표시합니다.
///     획득/활성 상태에 따라 적절한 시각적 처리를 제공합니다.
class TitleCatalogPage extends ConsumerStatefulWidget {
  const TitleCatalogPage({super.key, this.initialTitleId});

  /// EN: When provided (e.g. from a TITLE_EARNED notification tap), the
  ///     catalog opens with this title pre-selected instead of the active one.
  /// KO: 제공된 경우(예: TITLE_EARNED 알림 탭), 활성 칭호 대신 이 칭호를
  ///     미리 선택한 상태로 카탈로그를 엽니다.
  final String? initialTitleId;

  @override
  ConsumerState<TitleCatalogPage> createState() => _TitleCatalogPageState();
}

class _TitleCatalogPageState extends ConsumerState<TitleCatalogPage> {
  // EN: Locally selected title id (not yet applied).
  // KO: 아직 적용되지 않은 로컬 선택 칭호 ID.
  String? _selectedId;

  // EN: True while the apply mutation is in-flight.
  // KO: 적용 변이가 진행 중인 경우 true.
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    // EN: Seed the selection with the currently active title on first render.
    // KO: 첫 렌더 시 현재 활성 칭호로 선택값을 초기화합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // EN: Prefer initialTitleId (from TITLE_EARNED notification) over the
      //     current active title so the earned title is immediately selected.
      // KO: TITLE_EARNED 알림에서 전달된 initialTitleId를 활성 칭호보다 우선
      //     적용하여 획득한 칭호가 즉시 선택됩니다.
      final fromNotification = widget.initialTitleId?.trim();
      if (fromNotification != null && fromNotification.isNotEmpty) {
        setState(() => _selectedId = fromNotification);
        return;
      }
      final activeTitle = ref.read(activeTitleProvider).valueOrNull;
      if (_selectedId == null && activeTitle?.hasTitle == true) {
        setState(() => _selectedId = activeTitle!.titleId);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // EN: Interaction handlers
  // KO: 상호작용 핸들러
  // ---------------------------------------------------------------------------

  void _onTitleTap(TitleCatalogItem item) {
    // EN: isEarned null is treated as not earned (unauthenticated state).
    // KO: isEarned가 null이면 미획득으로 취급합니다(미인증 상태).
    final isEarned = item.isEarned ?? false;

    if (!isEarned) {
      final description = item.description?.isNotEmpty == true
          ? item.description!
          : '이 칭호를 획득하려면 조건을 달성하세요';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('아직 획득하지 못한 칭호예요'),
              if (item.description?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GBTTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _selectedId = item.id);
  }

  Future<void> _onApply() async {
    final selectedId = _selectedId;
    if (selectedId == null || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      await ref.read(titleCatalogProvider.notifier).applyTitle(selectedId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('칭호가 적용되었어요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('칭호 적용에 실패했어요: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _onClearActive() async {
    try {
      await ref.read(activeTitleProvider.notifier).clearActive();
      if (!mounted) return;
      setState(() => _selectedId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('칭호가 해제되었어요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('칭호 해제에 실패했어요: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // EN: Build
  // KO: 빌드
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalogState = ref.watch(titleCatalogProvider);
    final activeTitleAsync = ref.watch(activeTitleProvider);

    // EN: Derive the currently active title id from the notifier.
    // KO: 노티파이어에서 현재 활성 칭호 ID를 도출합니다.
    final activeTitle = activeTitleAsync.valueOrNull;
    final activeId = activeTitle?.hasTitle == true
        ? activeTitle!.titleId
        : null;
    final hasActiveTitle = activeTitle?.hasTitle == true;

    // EN: The apply button is disabled when:
    //   1. No item is selected.
    //   2. The selected item is already the active title.
    //   3. An apply mutation is in-flight.
    // KO: 적용 버튼 비활성화 조건:
    //   1. 선택된 항목이 없는 경우.
    //   2. 선택된 항목이 이미 활성 칭호인 경우.
    //   3. 적용 변이가 진행 중인 경우.
    final isApplyDisabled =
        _selectedId == null || _selectedId == activeId || _isApplying;

    final scaffoldBg = isDark ? GBTColors.darkBackground : GBTColors.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: gbtStandardAppBar(
        context,
        title: '칭호 관리',
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).pop(),
        ),
        // EN: Show the clear-active action in the app bar when a title is active.
        // KO: 활성 칭호가 있을 때 앱 바에 해제 액션을 표시합니다.
        actions: [
          if (hasActiveTitle)
            TextButton(
              onPressed: _onClearActive,
              child: Text(
                '칭호 해제',
                style: GBTTypography.bodyMedium.copyWith(
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TitleDocumentHeader(),

          // EN: Catalog list (expands to fill available space)
          // KO: 카탈로그 리스트 (가용 공간 채움)
          Expanded(
            child: catalogState.when(
              loading: () => _TitleListShimmer(isDark: isDark),
              error: (error, _) => _TitleErrorState(
                onRetry: () =>
                    ref.read(titleCatalogProvider.notifier).refreshCatalog(),
              ),
              data: (items) => _TitleCatalogList(
                items: items,
                selectedId: _selectedId,
                activeId: activeId,
                onTap: _onTitleTap,
              ),
            ),
          ),

          // EN: Bottom apply bar
          // KO: 하단 적용 바
          _ApplyBar(
            isDark: isDark,
            isDisabled: isApplyDisabled,
            isApplying: _isApplying,
            onApply: _onApply,
          ),
        ],
      ),
    );
  }
}

/// EN: Document heading for the earned-title archive and active selection.
/// KO: 획득 칭호 아카이브와 활성 선택을 위한 문서 헤더.
class _TitleDocumentHeader extends StatelessWidget {
  const _TitleDocumentHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.lg,
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Container(
          padding: const EdgeInsets.only(bottom: GBTSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? GBTColors.darkBorder : GBTColors.border,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PASSPORT / TITLE ARCHIVE',
                style: GBTTypography.labelSmall.copyWith(
                  color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                '나의 여정을 나타내는 칭호',
                style: GBTTypography.titleLarge.copyWith(
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                '활동과 이벤트 달성으로 획득한 칭호를 골라 프로필에 표시하세요.',
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Title catalog list — groups items by project, then by category.
// KO: 칭호 카탈로그 리스트 — 프로젝트별, 이후 카테고리별로 그룹화합니다.
// =============================================================================

class _TitleCatalogList extends ConsumerWidget {
  const _TitleCatalogList({
    required this.items,
    required this.selectedId,
    required this.activeId,
    required this.onTap,
  });

  final List<TitleCatalogItem> items;
  final String? selectedId;
  final String? activeId;
  final void Function(TitleCatalogItem) onTap;

  // EN: Sentinel key for titles that belong to all projects (null projectId).
  // KO: 전체 프로젝트 공통 칭호(null projectId)를 위한 센티넬 키.
  static const _commonKey = '__common__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          '표시할 칭호가 없습니다',
          style: GBTTypography.bodyMedium.copyWith(
            color: GBTColors.textSecondary,
          ),
        ),
      );
    }

    // EN: Build a projectId → project name lookup from the projects provider.
    // KO: 프로젝트 프로바이더에서 projectId → 프로젝트 이름 조회 맵을 구성합니다.
    final projectNameOf = <String, String>{};
    ref.watch(projectsControllerProvider).whenData((projects) {
      for (final p in projects) {
        projectNameOf[p.id] = p.name;
      }
    });

    // EN: Partition items into buckets: null projectId → _commonKey,
    //     otherwise keyed by projectId.
    // KO: null projectId → _commonKey 버킷, 그 외에는 projectId로 분류합니다.
    final buckets = <String, List<TitleCatalogItem>>{};
    for (final item in items) {
      final key = item.projectId ?? _commonKey;
      (buckets[key] ??= []).add(item);
    }

    // EN: Order: common titles first, then projects in insertion order.
    // KO: 순서: 공통 칭호 먼저, 그 다음 삽입 순서대로 프로젝트.
    final orderedKeys = [
      if (buckets.containsKey(_commonKey)) _commonKey,
      ...buckets.keys.where((k) => k != _commonKey),
    ];

    // EN: Build a flat list of project headers → category headers → tiles.
    // KO: 프로젝트 헤더 → 카테고리 헤더 → 타일 순으로 평탄한 리스트 구성.
    final listChildren = <Widget>[];

    for (var pi = 0; pi < orderedKeys.length; pi++) {
      final projectKey = orderedKeys[pi];
      final projectItems = buckets[projectKey]!;
      final projectName = projectKey == _commonKey
          ? '공통'
          : (projectNameOf[projectKey] ?? projectKey);

      listChildren.add(_ProjectSectionHeader(projectName: projectName));

      // EN: Within each project bucket, group by category.
      // KO: 각 프로젝트 버킷 내에서 카테고리별로 그룹화합니다.
      final grouped = <TitleCategory, List<TitleCatalogItem>>{};
      for (final category in TitleCategory.values) {
        final categoryItems =
            projectItems.where((i) => i.category == category).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (categoryItems.isNotEmpty) {
          grouped[category] = categoryItems;
        }
      }

      final categories = grouped.keys.toList();
      for (var ci = 0; ci < categories.length; ci++) {
        final category = categories[ci];
        final categoryItems = grouped[category]!;

        listChildren.add(_CategorySectionHeader(category: category));

        for (final item in categoryItems) {
          listChildren.add(
            _TitleTile(
              item: item,
              isSelected: item.id == selectedId,
              isActive: item.id == activeId,
              onTap: () => onTap(item),
            ),
          );
        }

        // EN: Subtle divider between category sections (not after the last).
        // KO: 카테고리 섹션 사이 구분선 (마지막 뒤에는 추가하지 않음).
        if (ci < categories.length - 1) {
          listChildren.add(
            const Divider(
              height: GBTSpacing.xs,
              indent: GBTSpacing.pageHorizontal,
              endIndent: GBTSpacing.pageHorizontal,
            ),
          );
        }
      }

      // EN: Thicker divider between project sections (not after the last).
      // KO: 프로젝트 섹션 사이 구분선 (마지막 뒤에는 추가하지 않음).
      if (pi < orderedKeys.length - 1) {
        listChildren.add(const Divider(height: GBTSpacing.lg, thickness: 1));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
      children: listChildren,
    );
  }
}

// =============================================================================
// EN: Project section header
// KO: 프로젝트 섹션 헤더
// =============================================================================

class _ProjectSectionHeader extends StatelessWidget {
  const _ProjectSectionHeader({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xxs,
      ),
      child: Text(
        projectName,
        style: GBTTypography.headlineSmall.copyWith(
          color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Category section header
// KO: 카테고리 섹션 헤더
// =============================================================================

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({required this.category});

  final TitleCategory category;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _categoryColor(category, isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.lg,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xs,
      ),
      child: Row(
        children: [
          // EN: Small colored vertical bar beside the category label.
          // KO: 카테고리 레이블 옆 작은 컬러 세로 막대.
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
            ),
          ),
          const SizedBox(width: GBTSpacing.xs),
          Text(
            _categoryLabel(category),
            style: GBTTypography.labelMedium.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EN: Single title tile
// KO: 단일 칭호 타일
// =============================================================================

class _TitleTile extends StatelessWidget {
  const _TitleTile({
    required this.item,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
  });

  final TitleCatalogItem item;

  // EN: Whether this tile is currently selected in the local state (not yet applied).
  // KO: 로컬 상태에서 현재 선택된 타일인지 여부 (아직 적용 전).
  final bool isSelected;

  // EN: Whether this title is the user's currently active (applied) title.
  // KO: 이 칭호가 사용자의 현재 활성(적용됨) 칭호인지 여부.
  final bool isActive;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // EN: isEarned null → treat as not earned (unauthenticated state).
    // KO: isEarned가 null이면 미획득으로 취급합니다(미인증 상태).
    final isEarned = item.isEarned ?? false;
    final accentColor = _categoryColor(item.category, isDark);
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    // EN: Name text color: primary when active, tertiary when locked,
    //     else standard primary text.
    // KO: 이름 텍스트 색상: 활성이면 primary, 잠금이면 tertiary, 그 외 기본 텍스트.
    final nameColor = isActive
        ? primaryColor
        : (!isEarned
              ? (isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary)
              : (isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary));

    // EN: Description text color is always secondary/tertiary for visual hierarchy.
    // KO: 설명 텍스트 색상은 시각적 계층을 위해 항상 secondary/tertiary입니다.
    final descColor = !isEarned
        ? (isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary)
        : (isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary);

    // EN: Trailing icon: check_circle for active, check for selected-unactive,
    //     lock for locked, nothing for earned-unselected.
    // KO: 후행 아이콘: 활성이면 check_circle, 선택됐으나 미활성이면 check,
    //     잠금이면 lock, 획득했으나 미선택이면 없음.
    Widget? trailingIcon;
    if (isActive) {
      trailingIcon = Icon(
        Icons.check_circle_rounded,
        color: primaryColor,
        size: GBTSpacing.iconSm,
        semanticLabel: '현재 적용 중',
      );
    } else if (isSelected && isEarned) {
      trailingIcon = Icon(
        Icons.check_rounded,
        color: primaryColor,
        size: GBTSpacing.iconSm,
        semanticLabel: '선택됨',
      );
    } else if (!isEarned) {
      trailingIcon = Icon(
        Icons.lock_rounded,
        color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        size: GBTSpacing.iconSm,
        semanticLabel: '잠김',
      );
    }

    return Semantics(
      label:
          '${item.name}, ${_categoryLabel(item.category)}, '
          '${isActive ? "현재 적용 중" : (isEarned ? "획득함" : "미획득")}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          margin: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
          ),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected && !isActive
                ? primaryColor.withValues(alpha: isDark ? 0.08 : 0.05)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected || isActive
                    ? primaryColor
                    : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(
                color: isDark ? GBTColors.darkBorderSubtle : GBTColors.divider,
              ),
            ),
          ),
          child: Row(
            children: [
              // EN: Circular category color icon on the left.
              // KO: 왼쪽 원형 카테고리 색상 아이콘.
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: GBTSpacing.sm),
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: isEarned ? (isDark ? 0.2 : 0.12) : 0.06,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  size: 18,
                  color: isEarned
                      ? accentColor
                      : (isDark
                            ? GBTColors.darkTextTertiary
                            : GBTColors.textTertiary),
                ),
              ),
              const SizedBox(width: GBTSpacing.md),

              // EN: Name and description text column.
              // KO: 이름 및 설명 텍스트 컬럼.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: GBTTypography.titleSmall.copyWith(
                        color: nameColor,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        style: GBTTypography.bodySmall.copyWith(
                          color: descColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // EN: Trailing status icon (check / lock / empty).
              // KO: 후행 상태 아이콘 (체크 / 잠금 / 없음).
              if (trailingIcon != null) ...[
                const SizedBox(width: GBTSpacing.sm),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Shimmer loading placeholder for the title list.
// KO: 칭호 리스트용 쉬머 로딩 플레이스홀더.
// =============================================================================

class _TitleListShimmer extends StatelessWidget {
  const _TitleListShimmer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shimmerColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return Semantics(
      label: '칭호 목록 로딩 중',
      excludeSemantics: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.pageHorizontal,
          vertical: GBTSpacing.md,
        ),
        // EN: Show 10 shimmer rows as placeholder.
        // KO: 플레이스홀더로 10개의 쉬머 행을 표시합니다.
        itemCount: 10,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
          child: GBTShimmer(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Error state with retry button.
// KO: 재시도 버튼이 있는 오류 상태.
// =============================================================================

class _TitleErrorState extends StatelessWidget {
  const _TitleErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
          const SizedBox(height: GBTSpacing.md),
          Text(
            '칭호 목록을 불러오지 못했어요',
            style: GBTTypography.bodyMedium.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          ),
          const SizedBox(height: GBTSpacing.lg),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

// =============================================================================
// EN: Bottom apply bar — sticky CTA.
// KO: 하단 적용 바 — 고정 CTA.
// =============================================================================

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({
    required this.isDark,
    required this.isDisabled,
    required this.isApplying,
    required this.onApply,
  });

  final bool isDark;
  final bool isDisabled;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // EN: Matches the FilledButton theme's foreground so the spinner reads
    // correctly against the pill-shaped CTA in both brightness modes.
    // KO: 두 밝기 모드 모두에서 알약형 CTA 위에 스피너가 잘 보이도록
    // FilledButton 테마의 전경색과 맞춥니다.
    final onButtonColor = isDark
        ? GBTColors.darkBackground
        : GBTColors.textInverse;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurface : GBTColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? GBTColors.darkSurfaceVariant
                : GBTColors.surfaceVariant,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.md,
          GBTSpacing.pageHorizontal,
          GBTSpacing.md + bottomPadding,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          // EN: Uses the shared FilledButton theme (pill shape, brand
          // primary) instead of a bespoke ElevatedButton style.
          // KO: 별도 ElevatedButton 스타일 대신 공유 FilledButton 테마
          // (알약 모양, 브랜드 primary)를 사용합니다.
          child: FilledButton(
            onPressed: isDisabled ? null : onApply,
            child: isApplying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onButtonColor,
                    ),
                  )
                : const Text('이 칭호 적용'),
          ),
        ),
      ),
    );
  }
}
