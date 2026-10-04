/// EN: Reusable horizontal carousel section wrapper
/// KO: 재사용 가능한 수평 캐러셀 섹션 래퍼
library;

import 'package:flutter/material.dart';

import '../../localization/locale_text.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Section wrapper with bold header + "전체보기" button + horizontal list.
///     Provides consistent layout for all carousel sections on the home page.
/// KO: 볼드 헤더 + "전체보기" 버튼 + 수평 리스트를 가진 섹션 래퍼.
///     홈 페이지의 모든 캐러셀 섹션에 일관된 레이아웃을 제공합니다.
class GBTCarouselSection extends StatelessWidget {
  const GBTCarouselSection({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.itemHeight = 204,
    this.onSeeAll,
  });

  /// EN: Section title displayed as headlineLarge
  /// KO: headlineLarge로 표시되는 섹션 제목
  final String title;

  /// EN: Number of items in the carousel
  /// KO: 캐러셀 아이템 수
  final int itemCount;

  /// EN: Builder for each carousel item
  /// KO: 각 캐러셀 아이템 빌더
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// EN: Total height of the carousel content area
  /// KO: 캐러셀 콘텐츠 영역의 전체 높이
  final double itemHeight;

  /// EN: Callback when "전체보기" is tapped
  /// KO: "전체보기"가 탭되었을 때 콜백
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // EN: Section header row
        // KO: 섹션 헤더 행
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GBTTypography.headlineLarge.copyWith(
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                ),
              ),
              if (onSeeAll != null)
                Semantics(
                  label:
                      '$title ${context.l10n(ko: "전체 보기", en: "see all", ja: "すべて見る")}',
                  button: true,
                  child: TextButton(
                    onPressed: onSeeAll,
                    child: Text(
                      context.l10n(ko: '전체 보기', en: 'See all', ja: 'すべて見る'),
                      style: GBTTypography.bodySmall.copyWith(
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),

        // EN: Horizontal scrollable list
        // KO: 수평 스크롤 리스트
        SizedBox(
          height: itemHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: Theme.of(context).platform == TargetPlatform.android
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.pageHorizontal,
            ),
            itemCount: itemCount,
            separatorBuilder: (_, __) =>
                const SizedBox(width: GBTSpacing.carouselItemGap),
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}
