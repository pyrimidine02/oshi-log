/// EN: Active title badge widget for user profile display.
/// KO: 사용자 프로필 표시용 활성 칭호 배지 위젯.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../domain/entities/title_entities.dart';

// =============================================================================
// EN: Category color helper — maps [TitleCategory] to a representative color.
// KO: 카테고리 색상 헬퍼 — [TitleCategory]를 대표 색상으로 매핑합니다.
// =============================================================================

/// EN: Returns the accent color associated with [category], drawn from the
/// Journey Ticket palette (mint/gold/violet/brand magenta) — matches the
/// mapping used in the title catalog page. Falls back to primary for null /
/// unknown categories.
/// KO: [category]에 연결된 강조 색상 — "여정의 티켓" 팔레트(민트/골드/
/// 바이올렛/브랜드 마젠타)에서 가져오며, 칭호 카탈로그 페이지와 동일한
/// 매핑을 사용합니다. null 또는 알 수 없는 카테고리는 primary로 폴백합니다.
Color _categoryColor(TitleCategory? category, bool isDark) {
  return switch (category) {
    TitleCategory.activity => GBTSemanticColors.getDistanceColor(
      isDark ? Brightness.dark : Brightness.light,
    ),
    TitleCategory.commemorative =>
      isDark ? GBTColors.darkAccent : GBTColors.accent,
    TitleCategory.event =>
      isDark ? GBTColors.darkSecondary : GBTColors.secondary,
    TitleCategory.admin ||
    null => isDark ? GBTColors.darkPrimary : GBTColors.primary,
  };
}

// =============================================================================
// EN: ActiveTitleBadge
// KO: ActiveTitleBadge
// =============================================================================

/// EN: Displays the active title badge for a user profile.
///     Shows the title name with a category color accent.
///     Hides itself when no title is set (empty [titleName]).
/// KO: 사용자 프로필의 활성 칭호 배지를 표시합니다.
///     카테고리 색상 강조와 함께 칭호 이름을 표시합니다.
///     칭호가 없으면(빈 [titleName]) 위젯을 숨깁니다.
///
/// Usage:
/// ```dart
/// // Direct construction
/// ActiveTitleBadge(
///   titleName: '열정적인 탐험가',
///   category: TitleCategory.activity,
/// )
///
/// // Factory shorthand from an ActiveTitleItem
/// ActiveTitleBadge.fromActiveItem(activeTitleItem)
/// ```
class ActiveTitleBadge extends StatelessWidget {
  /// EN: Direct constructor — pass the display name and optional category.
  /// KO: 직접 생성자 — 표시 이름과 선택적 카테고리를 전달합니다.
  const ActiveTitleBadge({super.key, required this.titleName, this.category});

  /// EN: Factory constructor that reads fields from an [ActiveTitleItem] entity.
  /// KO: [ActiveTitleItem] 엔티티에서 필드를 읽어오는 팩토리 생성자.
  factory ActiveTitleBadge.fromActiveItem(ActiveTitleItem item) {
    return ActiveTitleBadge(titleName: item.name, category: item.category);
  }

  /// EN: Factory constructor that reads fields from a [TitleCatalogItem] entity.
  /// KO: [TitleCatalogItem] 엔티티에서 필드를 읽어오는 팩토리 생성자.
  factory ActiveTitleBadge.fromCatalogItem(TitleCatalogItem item) {
    return ActiveTitleBadge(titleName: item.name, category: item.category);
  }

  /// EN: The title name to display. An empty string hides the badge.
  /// KO: 표시할 칭호 이름. 빈 문자열이면 배지를 숨깁니다.
  final String titleName;

  /// EN: Category determines the accent color of the badge.
  ///     Null falls back to [GBTColors.primary].
  /// KO: 카테고리는 배지 강조 색상을 결정합니다.
  ///     null이면 [GBTColors.primary]로 폴백합니다.
  final TitleCategory? category;

  @override
  Widget build(BuildContext context) {
    // EN: Hide badge when no title is set.
    // KO: 칭호가 없으면 배지를 숨깁니다.
    if (titleName.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _categoryColor(category, isDark);

    // EN: Background uses low-alpha fill; border uses slightly higher alpha.
    // KO: 배경은 낮은 알파 채우기, 테두리는 약간 높은 알파를 사용합니다.
    final bgAlpha = isDark ? 0.2 : 0.12;

    return Semantics(
      label: '현재 칭호: $titleName',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EN: Small circular dot indicating the category color.
            // KO: 카테고리 색상을 나타내는 작은 원형 dot.
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: GBTSpacing.xxs + 2),

            // EN: Title name — single line with ellipsis overflow.
            // KO: 칭호 이름 — 한 줄, 말줄임 오버플로.
            Flexible(
              child: Text(
                titleName,
                style: GBTTypography.labelSmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
