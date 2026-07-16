/// EN: Designed empty state — every list gets an intentional empty view
/// instead of a blank screen (KR community-app convention).
/// KO: 설계된 엠티 스테이트 — 빈 화면 대신 모든 리스트에 의도된 빈 상태 뷰 제공
/// (한국 커뮤니티 앱 관례).
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: Standard empty state with icon, title, optional subtitle and action.
/// KO: 아이콘, 제목, 선택적 부제목·액션 버튼을 가진 표준 엠티 스테이트.
class GBTEmptyState extends StatelessWidget {
  const GBTEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : assert(
         title != null || message != null,
         'GBTEmptyState requires either title or message.',
       );

  /// EN: Illustrative icon shown inside a tinted circle.
  /// KO: 틴트 원 안에 표시되는 일러스트 아이콘.
  final IconData icon;

  /// EN: One-line headline describing the empty situation.
  /// KO: 빈 상태를 설명하는 한 줄 헤드라인.
  final String? title;

  /// EN: Legacy body copy. With no title it becomes the headline; otherwise
  ///     it becomes supporting copy. Kept while call sites migrate.
  /// KO: 레거시 본문 문구. 제목이 없으면 헤드라인, 있으면 보조 문구가 됩니다.
  ///     호출부를 점진적으로 이전하는 동안 호환성을 유지합니다.
  final String? message;

  /// EN: Optional supporting copy.
  /// KO: 선택적 보조 문구.
  final String? subtitle;

  /// EN: Optional call-to-action button label.
  /// KO: 선택적 CTA 버튼 라벨.
  final String? actionLabel;

  /// EN: Callback for the CTA button.
  /// KO: CTA 버튼 콜백.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final effectiveTitle = title ?? message!;
    final effectiveSubtitle = subtitle ?? (title != null ? message : null);

    return Semantics(
      container: true,
      label: [
        effectiveTitle,
        if (effectiveSubtitle != null) effectiveSubtitle,
      ].join('. '),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.xl,
            vertical: GBTSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.32 : 0.20),
                  ),
                ),
                child: Icon(icon, size: GBTSpacing.iconLg, color: accent),
              ),
              const SizedBox(height: GBTSpacing.lg),
              Text(
                effectiveTitle,
                textAlign: TextAlign.center,
                style: GBTTypography.headlineSmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                ),
              ),
              if (effectiveSubtitle != null) ...[
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  effectiveSubtitle,
                  textAlign: TextAlign.center,
                  style: GBTTypography.bodyMedium.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: GBTSpacing.lg),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
