/// EN: Cheer guides list page — browse all available cheer guides.
/// KO: 응원 가이드 목록 페이지 — 모든 응원 가이드 탐색.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/cheer_guides_controller.dart';
import '../../domain/entities/cheer_guide.dart';

/// EN: Displays the cheer guide list screen for the selected project.
/// KO: 선택된 프로젝트의 응원 가이드 목록 화면을 표시합니다.
class CheerGuidesPage extends ConsumerWidget {
  const CheerGuidesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectId = ref.watch(selectedProjectKeyProvider);
    final effectiveProjectId = projectId?.isNotEmpty == true ? projectId : null;
    final guidesAsync = ref.watch(cheerGuidesListProvider(effectiveProjectId));

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '응원 가이드', en: 'Cheer Guide', ja: '応援ガイド'),
      ),
      body: guidesAsync.when(
        loading: () => _CheerGuidesShimmer(),
        error: (_, __) => Center(
          child: GBTEmptyState(
            icon: Icons.wifi_off_rounded,
            message: context.l10n(
              ko: '응원 가이드를 불러오지 못했어요',
              en: 'Could not load cheer guides',
              ja: '応援ガイドを読み込めませんでした',
            ),
            actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
            onAction: () =>
                ref.refresh(cheerGuidesListProvider(effectiveProjectId)),
          ),
        ),
        data: (guides) => guides.isEmpty
            ? Center(
                child: GBTEmptyState(
                  icon: Icons.queue_music_rounded,
                  message: context.l10n(
                    ko: '아직 응원 가이드가 없어요',
                    en: 'No cheer guides yet',
                    ja: '応援ガイドはまだありません',
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.lg,
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.xl,
                ),
                itemCount: guides.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CheerGuideDocumentHeader(count: guides.length);
                  }
                  final guide = guides[index - 1];
                  return _CheerGuideTile(
                    guide: guide,
                    onTap: () => context.push(
                      '/cheer-guides/${Uri.encodeComponent(guide.id)}',
                    ),
                  );
                },
                separatorBuilder: (context, index) => index == 0
                    ? const SizedBox(height: GBTSpacing.lg)
                    : Divider(
                        height: 1,
                        color: isDark
                            ? GBTColors.darkBorderSubtle
                            : GBTColors.divider,
                      ),
              ),
      ),
    );
  }
}

/// EN: Document heading that frames the list as an indexed field reference.
/// KO: 목록을 인덱스화된 현장 참고 문서로 보여주는 헤더.
class _CheerGuideDocumentHeader extends StatelessWidget {
  const _CheerGuideDocumentHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIELD GUIDE / CALL INDEX · ${count.toString().padLeft(2, '0')}',
            style: GBTTypography.labelSmall.copyWith(
              color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '무대를 더 깊게 즐기는 법',
              en: 'Know the room before the show',
              ja: 'ライブ前にコールを確認',
            ),
            style: GBTTypography.headlineSmall.copyWith(
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '곡별 콜, 응답, 펜라이트 타이밍을 한눈에 확인하세요.',
              en: 'Review calls, responses, and penlight timing song by song.',
              ja: '曲ごとのコール、レスポンス、ペンライトのタイミングを確認できます。',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Shimmer skeleton shown while the guide list is loading.
/// KO: 가이드 목록 로딩 중 표시되는 쉬머 스켈레톤.
class _CheerGuidesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
        child: GBTShimmer(
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: GBTColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: List tile for a single cheer guide summary.
/// KO: 단일 응원 가이드 요약을 위한 목록 타일.
class _CheerGuideTile extends StatelessWidget {
  const _CheerGuideTile({required this.guide, required this.onTap});

  final CheerGuideSummary guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: guide.songTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: Row(
                children: [
                  // EN: Music icon avatar
                  // KO: 음악 아이콘 아바타
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? GBTColors.darkPrimary.withValues(alpha: 0.15)
                          : GBTColors.primary.withValues(alpha: 0.1),
                      border: Border(
                        left: BorderSide(
                          color: isDark
                              ? GBTColors.darkPrimary
                              : GBTColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.music_note_outlined,
                      color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          guide.songTitle,
                          style: GBTTypography.bodyMedium.copyWith(
                            color: isDark
                                ? GBTColors.darkTextPrimary
                                : GBTColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (guide.artistName != null) ...[
                          const SizedBox(height: GBTSpacing.xxs),
                          Text(
                            guide.artistName!,
                            style: GBTTypography.bodySmall.copyWith(
                              color: isDark
                                  ? GBTColors.darkTextSecondary
                                  : GBTColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // EN: Compact difficulty notation stays legible at 200% text.
                  // KO: 200% 글자 크기에서도 읽히는 간결한 난이도 표기.
                  if (guide.difficulty != null)
                    Padding(
                      padding: const EdgeInsets.only(right: GBTSpacing.xs),
                      child: Text(
                        '★ ${guide.difficulty}/5',
                        style: GBTTypography.labelSmall.copyWith(
                          color: isDark
                              ? GBTColors.darkSecondary
                              : GBTColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: GBTSpacing.iconSm,
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
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
