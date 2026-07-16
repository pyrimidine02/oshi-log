/// EN: Cheer guide detail page — full section-by-section guide.
/// KO: 응원 가이드 상세 페이지 — 섹션별 전체 가이드.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/cheer_guides_controller.dart';
import '../../domain/entities/cheer_guide.dart';

/// EN: Displays the full section-by-section cheer guide for a single song.
/// KO: 한 곡의 섹션별 전체 응원 가이드를 표시합니다.
class CheerGuideDetailPage extends ConsumerWidget {
  const CheerGuideDetailPage({super.key, required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guideAsync = ref.watch(cheerGuideDetailProvider(guideId));
    final appBarTitle = guideAsync.maybeWhen(
      data: (guide) => guide.songTitle,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: gbtStandardAppBar(
        context,
        title: appBarTitle?.isNotEmpty == true
            ? appBarTitle!
            : context.l10n(ko: '응원 가이드', en: 'Cheer Guide', ja: '応援ガイド'),
      ),
      body: guideAsync.when(
        loading: () => _CheerGuideDetailShimmer(),
        error: (error, __) => Center(
          child: error is NotFoundFailure
              ? GBTEmptyState(
                  icon: Icons.search_off_rounded,
                  message: context.l10n(
                    ko: '가이드를 찾을 수 없어요',
                    en: 'Guide not found',
                    ja: 'ガイドが見つかりません',
                  ),
                )
              : GBTEmptyState(
                  icon: Icons.wifi_off_rounded,
                  message: context.l10n(
                    ko: '가이드를 불러오지 못했어요',
                    en: 'Could not load guide',
                    ja: 'ガイドを読み込めませんでした',
                  ),
                  actionLabel: context.l10n(
                    ko: '다시 시도',
                    en: 'Retry',
                    ja: '再試行',
                  ),
                  onAction: () =>
                      ref.refresh(cheerGuideDetailProvider(guideId)),
                ),
        ),
        data: (guide) => _GuideContent(guide: guide),
      ),
    );
  }
}

/// EN: Shimmer skeleton shown while the guide detail is loading.
/// KO: 가이드 상세 로딩 중 표시되는 쉬머 스켈레톤.
class _CheerGuideDetailShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      child: Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
            child: GBTShimmer(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: GBTColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Scrollable content for a full [CheerGuide].
/// KO: 전체 [CheerGuide]의 스크롤 가능한 콘텐츠.
class _GuideContent extends StatelessWidget {
  const _GuideContent({required this.guide});

  final CheerGuide guide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      children: [
        _GuideDocumentHeader(guide: guide),
        const SizedBox(height: GBTSpacing.lg),
        // EN: Overall guide notes banner
        // KO: 전체 가이드 메모 배너
        if (guide.overallNotes != null) ...[
          Container(
            padding: const EdgeInsets.all(GBTSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? GBTColors.darkPrimary.withValues(alpha: 0.1)
                  : GBTColors.primary.withValues(alpha: 0.07),
              border: Border(
                left: BorderSide(
                  color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                  width: 3,
                ),
                top: BorderSide(
                  color: isDark ? GBTColors.darkBorder : GBTColors.border,
                ),
                bottom: BorderSide(
                  color: isDark ? GBTColors.darkBorder : GBTColors.border,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                ),
                const SizedBox(width: GBTSpacing.xs),
                Expanded(
                  child: Text(
                    guide.overallNotes!,
                    style: GBTTypography.bodySmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
        ],
        ...guide.sections.asMap().entries.map(
          (entry) =>
              _SectionCard(stepNumber: entry.key + 1, section: entry.value),
        ),
        const SizedBox(height: GBTSpacing.xl),
      ],
    );
  }
}

/// EN: Indexed document heading for a song's full audience-participation note.
/// KO: 한 곡의 전체 관객 참여 노트를 위한 인덱스 문서 헤더.
class _GuideDocumentHeader extends StatelessWidget {
  const _GuideDocumentHeader({required this.guide});

  final CheerGuide guide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = <String>[
      if (guide.artistName?.isNotEmpty == true) guide.artistName!,
      context.l10n(
        ko: '${guide.sections.length}개 구간',
        en: '${guide.sections.length} sections',
        ja: '${guide.sections.length}セクション',
      ),
      if (guide.difficulty != null) '★ ${guide.difficulty}/5',
    ];
    return Semantics(
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
              'CALL SHEET / PERFORMANCE NOTE',
              style: GBTTypography.labelSmall.copyWith(
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
            Text(
              guide.songTitle,
              style: GBTTypography.headlineSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: GBTSpacing.xs),
              Text(
                meta.join('  ·  '),
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// EN: Card for a single [CheerSection] showing lyrics, cheer text, and
/// penlight colors.
/// KO: 가사, 응원 텍스트, 펜라이트 색상을 표시하는 단일 [CheerSection] 카드.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.stepNumber, required this.section});

  /// EN: 1-based position of this section within the guide, shown as a
  /// numbered step badge.
  /// KO: 가이드 내 이 섹션의 1부터 시작하는 위치이며, 번호가 매겨진
  /// 스텝 배지로 표시됩니다.
  final int stepNumber;
  final CheerSection section;

  // EN: Semantic color for each cheer type (light / dark). Call/response —
  // the two audience-participation types — map onto the brand's
  // primary/secondary stage colors; the rest stay neutral/amber.
  // KO: 응원 유형별 시맨틱 색상 (라이트 / 다크). 관객 참여 유형인
  // 콜/응답은 브랜드의 primary/secondary 스테이지 색상에 매핑하고,
  // 나머지는 뉴트럴/앰버를 유지합니다.
  Color _typeColor(CheerType type, bool isDark) {
    return switch (type) {
      CheerType.call => isDark ? GBTColors.darkPrimary : GBTColors.primary,
      CheerType.response =>
        isDark ? GBTColors.darkSecondary : GBTColors.secondary,
      CheerType.silence =>
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      CheerType.unified =>
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      CheerType.none =>
        isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
    };
  }

  // EN: Call-and-response blocks get the design system's dedicated light
  // fills in light mode (no dark-mode equivalent token exists, so dark
  // mode falls back to a tinted solid color); other cheer types always
  // use the tinted fallback.
  // KO: 콜앤리스폰스 블록은 라이트 모드에서 디자인 시스템의 전용 라이트
  // 컬러를 사용합니다 (다크 모드 전용 토큰은 없어 다크 모드는 틴트된
  // solid 색상으로 대체). 그 외 유형은 항상 틴트 폴백을 사용합니다.
  Color _blockFill(CheerType type, Color typeColor, bool isDark) {
    if (isDark) return typeColor.withValues(alpha: 0.14);
    return switch (type) {
      CheerType.call => GBTColors.primaryLight,
      CheerType.response => GBTColors.secondaryLight,
      _ => typeColor.withValues(alpha: 0.08),
    };
  }

  String _typeLabel(CheerType type, BuildContext context) {
    return switch (type) {
      CheerType.call => context.l10n(ko: '콜', en: 'Call', ja: 'コール'),
      CheerType.response => context.l10n(ko: '응답', en: 'Response', ja: 'レスポンス'),
      CheerType.silence => context.l10n(ko: '조용히', en: 'Silence', ja: '静かに'),
      CheerType.unified => context.l10n(ko: '합창', en: 'Unified', ja: 'ユニゾン'),
      CheerType.none => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor(section.cheerType, isDark);

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
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
            // EN: Section header row (name, timing, cheer type badge)
            // KO: 섹션 헤더 행 (이름, 타이밍, 응원 유형 배지)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.md,
                vertical: GBTSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? GBTColors.darkSurfaceVariant
                    : GBTColors.surfaceVariant,
              ),
              child: Row(
                children: [
                  // EN: Numbered step badge — gives the guide a clear
                  // sequential, walk-through feel.
                  // KO: 번호가 매겨진 스텝 배지 — 가이드에 순차적인
                  // 워크스루 느낌을 부여합니다.
                  Text(
                    stepNumber.toString().padLeft(2, '0'),
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: Text(
                      section.sectionName,
                      style: GBTTypography.labelMedium.copyWith(
                        color: isDark
                            ? GBTColors.darkTextPrimary
                            : GBTColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (section.timing != null) ...[
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      section.timing!,
                      style: GBTTypography.labelSmall.copyWith(
                        color: isDark
                            ? GBTColors.darkTextTertiary
                            : GBTColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                  ],
                  if (section.cheerType != CheerType.none)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _typeLabel(section.cheerType, context),
                        style: GBTTypography.labelSmall.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // EN: Section body (penlight colors, lyrics, cheer text, notes)
            // KO: 섹션 본문 (펜라이트 색상, 가사, 응원 텍스트, 메모)
            Padding(
              padding: const EdgeInsets.all(GBTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.penlightColors.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.flashlight_on_outlined,
                          size: 14,
                          color: isDark
                              ? GBTColors.darkTextSecondary
                              : GBTColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        ...section.penlightColors.map(
                          (hex) => Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: _hexToColor(hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? GBTColors.darkSurfaceVariant
                                    : GBTColors.surfaceVariant,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                  ],
                  if (section.lyrics != null) ...[
                    Text(
                      section.lyrics!,
                      style: GBTTypography.bodySmall.copyWith(
                        color: isDark
                            ? GBTColors.darkTextSecondary
                            : GBTColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                  ],
                  if (section.cheerText != null)
                    Container(
                      padding: const EdgeInsets.all(GBTSpacing.sm),
                      decoration: BoxDecoration(
                        color: _blockFill(section.cheerType, typeColor, isDark),
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusXs,
                        ),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        section.cheerText!,
                        style: GBTTypography.bodyMedium.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (section.notes != null) ...[
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      section.notes!,
                      style: GBTTypography.bodySmall.copyWith(
                        color: isDark
                            ? GBTColors.darkTextTertiary
                            : GBTColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EN: Parse a CSS hex color string to a Flutter [Color].
  // KO: CSS 16진수 색상 문자열을 Flutter [Color]로 파싱합니다.
  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return GBTColors.textTertiary;
  }
}
