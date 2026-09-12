/// EN: Shared visual primitives for the travel journal field screens.
/// KO: 여행 저널 필드 화면이 공유하는 시각 프리미티브입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: A quiet, outlined surface for a travel record or editorial feature.
/// KO: 여행 기록과 에디토리얼 피처에 사용하는 조용한 외곽선 표면입니다.
class GBTFieldSurface extends StatelessWidget {
  const GBTFieldSurface({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(GBTSpacing.radiusCard);
    final surface = color ?? colors.surface;
    final content = ConstrainedBox(
      constraints: onTap == null
          ? const BoxConstraints()
          : const BoxConstraints(
              minWidth: GBTSpacing.touchTarget,
              minHeight: GBTSpacing.touchTarget,
            ),
      child: Padding(padding: padding, child: child),
    );
    final body = accentColor == null
        ? content
        : DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: accentColor!, width: 4),
              ),
            ),
            child: content,
          );

    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? body
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                excludeFromSemantics: true,
                child: body,
              ),
      ),
    );
  }
}

/// EN: A responsive section heading with an editorial eyebrow and action.
/// KO: 에디토리얼 eyebrow와 액션을 포함한 반응형 섹션 헤더입니다.
class GBTFieldSectionHeader extends StatelessWidget {
  const GBTFieldSectionHeader({
    super.key,
    this.eyebrow = '',
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final heading = Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow.trim().isNotEmpty) ...[
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 2,
                  child: ColoredBox(color: colors.primary),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Flexible(
                  child: Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.xs),
          ],
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );

    if (actionLabel == null || onAction == null) return heading;

    final action = TextButton.icon(
      onPressed: onAction,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: Text(actionLabel!),
      style: TextButton.styleFrom(
        minimumSize: const Size.square(GBTSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            action,
          ],
        );
      },
    );
  }
}

/// EN: A compact status marker used in agenda and record surfaces.
/// KO: 아젠다와 기록 표면에서 사용하는 컴팩트 상태 마커입니다.
class GBTFieldBadge extends StatelessWidget {
  const GBTFieldBadge({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.primary;
    final background = foreground.withValues(alpha: 0.12);
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: GBTSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        border: Border.all(color: foreground.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: GBTSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
