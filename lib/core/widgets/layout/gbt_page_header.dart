/// EN: Shared editorial page header for routed feature screens.
/// KO: 라우팅된 기능 화면에서 공유하는 에디토리얼 페이지 헤더입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: Establishes the page hierarchy with an eyebrow, title, description,
/// and optional trailing control without introducing another card surface.
/// KO: 별도 카드 표면을 추가하지 않고 분류명, 제목, 설명, 선택적 우측
/// 컨트롤로 페이지 위계를 구성합니다.
class GBTPageHeader extends StatelessWidget {
  const GBTPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.trailing,
    this.padding,
    this.showDivider = true,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectivePadding =
        padding ??
        EdgeInsets.fromLTRB(
          GBTResponsiveSpacing.pageHorizontal(context),
          GBTSpacing.sm,
          GBTResponsiveSpacing.pageHorizontal(context),
          GBTSpacing.md,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
              )
            : null,
      ),
      child: Padding(
        padding: effectivePadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final header = Semantics(
              container: true,
              header: true,
              label: [
                if (eyebrow != null) eyebrow!,
                title,
                if (description != null) description!,
              ].join('. '),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.xs2),
                    ],
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: GBTSpacing.sm),
                      Text(
                        description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );

            if (trailing == null) return header;

            if (constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: GBTSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing!,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: header),
                const SizedBox(width: GBTSpacing.sm),
                trailing!,
              ],
            );
          },
        ),
      ),
    );
  }
}
