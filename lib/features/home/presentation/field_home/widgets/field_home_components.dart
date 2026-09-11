/// EN: Editorial primitives for the clean-sheet Field Desk home.
/// KO: 새로 설계한 Field Desk 홈을 위한 에디토리얼 프리미티브.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/common/gbt_image.dart';
import '../../../../../core/widgets/layout/gbt_field_primitives.dart';

/// EN: Section heading with a quiet rule and optional action.
/// KO: 얇은 규칙선과 선택 액션이 있는 섹션 제목입니다.
/// EN: Compatibility alias for callers migrating to the shared heading.
/// KO: 공용 헤딩으로 이전하는 호출자를 위한 호환 별칭입니다.
typedef FieldSectionHeader = GBTFieldSectionHeader;

/// EN: Compact, action-first briefing for the next event or pilgrimage stop.
/// KO: 다음 이벤트나 성지를 보여주는 행동 중심의 컴팩트 브리핑입니다.
class JourneyBriefCard extends StatelessWidget {
  const JourneyBriefCard({
    super.key,
    required this.markerLabel,
    required this.eyebrow,
    required this.title,
    required this.meta,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.secondaryActionLabel,
    required this.onSecondaryAction,
    this.imageUrl,
  });

  final String markerLabel;
  final String eyebrow;
  final String title;
  final String meta;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String secondaryActionLabel;
  final VoidCallback onSecondaryAction;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GBTFieldSurface(
      accentColor: colors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final artWidth = constraints.maxWidth < 330 ? 88.0 : 112.0;
          return IntrinsicHeight(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 176),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GBTSpacing.md,
                        GBTSpacing.md,
                        GBTSpacing.sm,
                        GBTSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: GBTSpacing.sm,
                            runSpacing: GBTSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: GBTSpacing.sm,
                                  vertical: GBTSpacing.xxs,
                                ),
                                color: colors.primary,
                                child: Text(
                                  markerLabel,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                              Text(
                                eyebrow.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: GBTSpacing.sm),
                          Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: GBTSpacing.xs),
                          Text(
                            meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: GBTSpacing.sm),
                          Wrap(
                            spacing: GBTSpacing.xs,
                            runSpacing: GBTSpacing.xs,
                            children: [
                              FilledButton(
                                onPressed: onPrimaryAction,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(
                                    0,
                                    GBTSpacing.touchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GBTSpacing.md,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(primaryActionLabel),
                              ),
                              TextButton(
                                onPressed: onSecondaryAction,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(
                                    0,
                                    GBTSpacing.touchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GBTSpacing.sm,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(secondaryActionLabel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!largeText)
                    SizedBox(
                      width: artWidth,
                      child: imageUrl == null || imageUrl!.trim().isEmpty
                          ? const _JourneyArtPlaceholder()
                          : ExcludeSemantics(
                              child: GBTImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                semanticLabel: title,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JourneyArtPlaceholder extends StatelessWidget {
  const _JourneyArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _RailGridPainter(
          lineColor: colors.outlineVariant,
          accentColor: colors.secondary,
        ),
        child: Center(
          child: Icon(
            Icons.location_city_outlined,
            size: 52,
            color: colors.secondary,
          ),
        ),
      ),
    );
  }
}

class _RailGridPainter extends CustomPainter {
  const _RailGridPainter({required this.lineColor, required this.accentColor});

  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = lineColor;
    for (double y = 20; y < size.height; y += 28) {
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), line);
    }
    final route = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.72),
      Offset(size.width * 0.82, size.height * 0.28),
      route,
    );
  }

  @override
  bool shouldRepaint(covariant _RailGridPainter oldDelegate) {
    return lineColor != oldDelegate.lineColor ||
        accentColor != oldDelegate.accentColor;
  }
}

/// EN: Immutable node on a lightweight route rail.
/// KO: 가벼운 경로 레일 위의 불변 노드입니다.
class FieldRouteNode {
  const FieldRouteNode({
    required this.label,
    required this.meta,
    required this.icon,
    this.isEmphasized = false,
    this.onTap,
  });

  final String label;
  final String meta;
  final IconData icon;
  final bool isEmphasized;
  final VoidCallback? onTap;
}

/// EN: Connected places and events rendered as a rail, not nested cards.
/// KO: 장소와 이벤트를 중첩 카드가 아닌 레일로 연결해 표시합니다.
class FieldRouteRail extends StatelessWidget {
  const FieldRouteRail({super.key, required this.nodes});

  final List<FieldRouteNode> nodes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var index = 0; index < nodes.length; index++)
          _RouteNodeRow(
            node: nodes[index],
            showConnector: index < nodes.length - 1,
            colors: colors,
          ),
      ],
    );
  }
}

class _RouteNodeRow extends StatelessWidget {
  const _RouteNodeRow({
    required this.node,
    required this.showConnector,
    required this.colors,
  });

  final FieldRouteNode node;
  final bool showConnector;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final nodeColor = node.isEmphasized ? colors.primary : colors.secondary;
    return Semantics(
      button: node.onTap != null,
      label: '${node.label}, ${node.meta}',
      onTap: node.onTap,
      excludeSemantics: node.onTap != null,
      child: InkWell(
        onTap: node.onTap,
        excludeFromSemantics: node.onTap != null,
        child: IntrinsicHeight(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GBTSpacing.touchTarget,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: node.isEmphasized ? nodeColor : colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: nodeColor, width: 2),
                        ),
                        child: Icon(
                          node.icon,
                          size: 14,
                          color: node.isEmphasized
                              ? GBTColorValidator.getContrastingTextColor(
                                  nodeColor,
                                )
                              : nodeColor,
                        ),
                      ),
                      if (showConnector)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colors.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: GBTSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.meta.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: nodeColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                        ),
                        Text(
                          node.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                if (node.onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Compact editorial spotlight that keeps the route visible below it.
/// KO: 아래 여정이 계속 보이도록 높이를 줄인 에디토리얼 장소 피처입니다.
class FieldPlaceFeature extends StatelessWidget {
  const FieldPlaceFeature({
    super.key,
    required this.title,
    required this.meta,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String meta;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title, $meta',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = constraints.maxWidth * 0.38;
              return IntrinsicHeight(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 132),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: imageWidth,
                        child: imageUrl == null || imageUrl!.trim().isEmpty
                            ? ColoredBox(
                                color: colors.secondaryContainer,
                                child: Icon(
                                  Icons.map_outlined,
                                  size: 38,
                                  color: colors.secondary,
                                ),
                              )
                            : GBTImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                semanticLabel: title,
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(GBTSpacing.md),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta.toUpperCase(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.secondary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                              ),
                              const SizedBox(height: GBTSpacing.xs),
                              Text(
                                title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: GBTSpacing.sm),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: colors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// EN: Borderless place row for secondary recommendations.
/// KO: 보조 추천 장소용 무테 행입니다.
class FieldPlaceRow extends StatelessWidget {
  const FieldPlaceRow({
    super.key,
    required this.title,
    required this.meta,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String meta;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title, $meta',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                child: SizedBox(
                  width: 88,
                  height: 66,
                  child: imageUrl == null || imageUrl!.trim().isEmpty
                      ? ColoredBox(
                          color: colors.secondaryContainer,
                          child: Icon(
                            Icons.place_outlined,
                            color: colors.secondary,
                          ),
                        )
                      : GBTImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          semanticLabel: title,
                        ),
                ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: colors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Agenda-first event row with a date stub.
/// KO: 날짜 스텁이 있는 일정 우선 이벤트 행입니다.
class FieldAgendaTile extends StatelessWidget {
  const FieldAgendaTile({
    super.key,
    required this.dateLabel,
    required this.title,
    required this.typeLabel,
    required this.onTap,
  });

  final String dateLabel;
  final String title;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title, $dateLabel, $typeLabel',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  dateLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(width: 1, height: 44, color: colors.outlineVariant),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      typeLabel.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Borderless dispatch row for news and local information.
/// KO: 뉴스와 현지 정보를 위한 무테 디스패치 행입니다.
class FieldDispatchRow extends StatelessWidget {
  const FieldDispatchRow({
    super.key,
    required this.title,
    required this.meta,
    required this.onTap,
    this.summary,
    this.imageUrl,
  });

  final String title;
  final String meta;
  final String? summary;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title, $meta${summary == null ? '' : ', $summary'}',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (summary != null && summary!.trim().isNotEmpty) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (imageUrl != null && imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(width: GBTSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                  child: GBTImage(
                    imageUrl: imageUrl!,
                    width: 88,
                    height: 66,
                    fit: BoxFit.cover,
                    semanticLabel: title,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
