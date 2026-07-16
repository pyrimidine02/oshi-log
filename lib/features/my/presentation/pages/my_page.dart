/// EN: "유저" tab — visual-first hub with XP ring, stat strip, 2-column action grid.
/// KO: "유저" 탭 — XP 링, 통계 스트립, 2열 액션 그리드의 시각적 허브.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_decorations.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_pressable.dart';
import '../../../../core/widgets/navigation/gbt_profile_action.dart';
import '../../../fan_level/application/fan_level_controller.dart';
import '../../../settings/application/settings_controller.dart';
import '../widgets/action_cell.dart';
import '../widgets/check_in_card.dart';
import '../widgets/settings_card.dart';
import '../widgets/stat_strip.dart';
import '../widgets/user_hero_card.dart';

// ===========================================================================
// EN: Page root
// KO: 페이지 루트
// ===========================================================================

/// EN: Root widget for the "유저" tab.
/// KO: "유저" 탭의 루트 위젯.
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // EN: Derive dark mode once and pass down to avoid repeated Theme.of calls.
    // KO: 다크 모드를 한 번 계산해 하위 위젯에 전달, 반복 Theme.of 호출 방지.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = ref
        .watch(userProfileControllerProvider)
        .valueOrNull
        ?.avatarUrl;

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? GBTColors.darkSurface : GBTColors.surface,
        titleSpacing: GBTSpacing.md,
        title: Text(
          context.l10n(ko: '유저', en: 'My', ja: 'マイ'),
          style: GBTTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
          ),
        ),
        actions: [GBTProfileAction(avatarUrl: avatarUrl)],
      ),
      body: RefreshIndicator(
        color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
        onRefresh: () async {
          await ref.read(fanLevelControllerProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
            vertical: GBTSpacing.md,
          ),
          children: [
            // EN: Hero fan-level card with XP ring + grade info.
            // KO: XP 링과 등급 정보가 있는 히어로 팬레벨 카드.
            UserHeroCard(isDark: isDark),
            const SizedBox(height: GBTSpacing.sm),

            // EN: Three-tile stat strip — streak, XP, rank.
            // KO: 3개 통계 타일 스트립 — 연속 출석, XP, 랭킹.
            StatStrip(isDark: isDark),
            const SizedBox(height: GBTSpacing.sm),

            // EN: Daily check-in button — below XP section.
            // KO: 일일 출석 체크 버튼 — XP 섹션 아래 배치.
            CheckInCard(isDark: isDark),
            const SizedBox(height: GBTSpacing.lg),

            // EN: Section: Explore & Plan
            // KO: 탐색 & 계획 섹션
            _SectionLabel(
              label: context.l10n(
                ko: '탐방 & 계획',
                en: 'Explore & Plan',
                ja: '探索 & 計画',
              ),
              isDark: isDark,
            ),
            const SizedBox(height: GBTSpacing.sm),

            // EN: Wide calendar banner card for quick event access.
            // KO: 빠른 이벤트 접근을 위한 와이드 달력 배너 카드.
            Semantics(
              button: true,
              label: context.l10n(
                ko: '이벤트 달력, 라이브 & 이벤트 일정 확인',
                en: 'Event Calendar, check live & event schedule',
                ja: 'イベントカレンダー、ライブ・イベントスケジュールを確認',
              ),
              child: GBTPressable(
                onTap: () => context.pushNamed(AppRoutes.calendar),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(GBTSpacing.md),
                  // EN: Override default card radius with the 2026 bento radius.
                  // KO: 기본 카드 반지름을 2026 벤토 반지름으로 재정의.
                  decoration: GBTDecorations.card(isDark: isDark).copyWith(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: GBTSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n(
                                ko: '이벤트 달력',
                                en: 'Event Calendar',
                                ja: 'イベントカレンダー',
                              ),
                              style: GBTTypography.labelLarge.copyWith(
                                color: isDark
                                    ? GBTColors.darkTextPrimary
                                    : GBTColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              context.l10n(
                                ko: '라이브 & 이벤트 일정 확인',
                                en: 'Check live & event schedule',
                                ja: 'ライブ・イベントスケジュール',
                              ),
                              style: GBTTypography.bodySmall.copyWith(
                                color: isDark
                                    ? GBTColors.darkTextSecondary
                                    : GBTColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? GBTColors.darkTextTertiary
                            : GBTColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),

            // EN: Visit log action cell — full width after calendar banner split.
            // KO: 달력 배너 분리 후 전체 너비로 표시되는 방문기록 셀.
            ActionCell(
              icon: Icons.pin_drop_outlined,
              label: context.l10n(ko: '방문 기록', en: 'Visit Log', ja: '訪問記録'),
              subtitle: context.l10n(
                ko: '성지순례 기록',
                en: 'Pilgrimage log',
                ja: '巡礼記録',
              ),
              color: isDark
                  ? GBTSemanticColors.darkMetadataDistance
                  : GBTColors.accentTeal,
              isDark: isDark,
              onTap: () => context.goToVisitHistory(),
            ),
            const SizedBox(height: GBTSpacing.lg),

            // EN: Section: My Collection
            // KO: 나의 컬렉션 섹션
            _SectionLabel(
              label: context.l10n(
                ko: '나의 컬렉션',
                en: 'My Collection',
                ja: 'マイコレクション',
              ),
              isDark: isDark,
            ),
            const SizedBox(height: GBTSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ActionCell(
                    icon: Icons.star_outline_rounded,
                    label: context.l10n(
                      ko: '즐겨찾기',
                      en: 'Favorites',
                      ja: 'お気に入り',
                    ),
                    subtitle: context.l10n(
                      ko: '저장한 장소',
                      en: 'Saved places',
                      ja: '保存した場所',
                    ),
                    color: isDark ? GBTColors.darkAccent : GBTColors.accent,
                    isDark: isDark,
                    onTap: () => context.pushNamed(AppRoutes.favorites),
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: ActionCell(
                    icon: Icons.bookmark_outline_rounded,
                    label: context.l10n(
                      ko: '북마크',
                      en: 'Bookmarks',
                      ja: 'ブックマーク',
                    ),
                    subtitle: context.l10n(
                      ko: '저장한 게시글',
                      en: 'Saved posts',
                      ja: '保存した投稿',
                    ),
                    color: isDark
                        ? GBTColors.darkSecondary
                        : GBTColors.secondary,
                    isDark: isDark,
                    onTap: () => context.goToPostBookmarks(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.lg),

            // EN: Section: Fan Activity Collection
            // KO: 덕질 컬렉션 섹션
            _SectionLabel(
              label: context.l10n(
                ko: '덕질 컬렉션',
                en: 'Fan Collection',
                ja: 'ファン活動',
              ),
              isDark: isDark,
            ),
            const SizedBox(height: GBTSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ActionCell(
                    icon: Icons.photo_album_rounded,
                    label: context.l10n(
                      ko: '성지순례 도감',
                      en: 'Place Guide',
                      ja: '聖地図鑑',
                    ),
                    subtitle: context.l10n(
                      ko: '성지 & 관련 장소',
                      en: 'Sacred & related places',
                      ja: '聖地 & 関連スポット',
                    ),
                    color: GBTColors.success,
                    isDark: isDark,
                    onTap: () => context.pushNamed(AppRoutes.zukan),
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: ActionCell(
                    icon: Icons.music_note_rounded,
                    label: context.l10n(
                      ko: '응원 가이드',
                      en: 'Cheer Guide',
                      ja: '応援ガイド',
                    ),
                    subtitle: context.l10n(
                      ko: '공연 응원법',
                      en: 'Concert cheer guide',
                      ja: 'ライブ応援ガイド',
                    ),
                    color: GBTColors.warning,
                    isDark: isDark,
                    onTap: () => context.pushNamed(AppRoutes.cheerGuides),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ActionCell(
                    icon: Icons.format_quote_rounded,
                    label: context.l10n(
                      ko: '명대사 카드',
                      en: 'Quote Cards',
                      ja: '名言カード',
                    ),
                    subtitle: context.l10n(
                      ko: '인상 깊은 명대사',
                      en: 'Memorable quotes',
                      ja: '名言コレクション',
                    ),
                    color: GBTColors.favorite,
                    isDark: isDark,
                    onTap: () => context.pushNamed(AppRoutes.quotes),
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: ActionCell(
                    icon: Icons.workspace_premium_rounded,
                    label: context.l10n(ko: '칭호 관리', en: 'Titles', ja: '称号管理'),
                    subtitle: context.l10n(
                      ko: '획득 칭호 확인·설정',
                      en: 'View & set your title',
                      ja: '称号の確認と設定',
                    ),
                    color: isDark
                        ? GBTColors.darkSecondary
                        : GBTColors.secondary,
                    isDark: isDark,
                    onTap: () => context.pushNamed(AppRoutes.titlePicker),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.lg),

            // EN: Settings entry — neutral, at the bottom.
            // KO: 설정 진입 — 중립 색상, 하단 배치.
            SettingsCard(isDark: isDark, onTap: () => context.goToSettings()),
            const SizedBox(height: GBTSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// EN: Section label widget.
// KO: 섹션 라벨 위젯.
// ===========================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GBTTypography.labelMedium.copyWith(
        color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
