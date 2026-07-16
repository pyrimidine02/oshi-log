/// EN: Edge-to-edge place row for the clean-sheet map drawer.
/// KO: 새 지도 드로어를 위한 엣지 투 엣지 장소 행입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/widgets/common/gbt_image.dart';

/// EN: Presents one place as an editorial row rather than a floating card.
/// KO: 하나의 장소를 플로팅 카드가 아닌 에디토리얼 행으로 표시합니다.
class FieldPlaceSheetRow extends StatelessWidget {
  const FieldPlaceSheetRow({
    super.key,
    required this.name,
    required this.address,
    required this.onTap,
    this.imageUrl,
    this.distanceLabel,
    this.typeLabel,
    this.isVisited = false,
    this.onDirections,
  });

  final String name;
  final String address;
  final String? imageUrl;
  final String? distanceLabel;
  final String? typeLabel;
  final bool isVisited;
  final VoidCallback onTap;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final distance = distanceLabel?.trim();
    final type = typeLabel?.trim();
    final visitedLabel = context.l10n(ko: '방문 완료', en: 'Visited', ja: '訪問済み');

    return Semantics(
      button: true,
      label: [
        name,
        if (address.trim().isNotEmpty) address,
        if (distance?.isNotEmpty == true) distance!,
        if (isVisited) visitedLabel,
      ].join(', '),
      child: Material(
        color: colors.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  child: SizedBox(
                    width: 76,
                    height: 84,
                    child: imageUrl?.trim().isNotEmpty == true
                        ? GBTImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            semanticLabel: name,
                          )
                        : ColoredBox(
                            color: colors.secondaryContainer,
                            child: Icon(
                              Icons.place_outlined,
                              color: colors.secondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (isVisited) ...[
                            const SizedBox(width: GBTSpacing.xs),
                            Tooltip(
                              message: visitedLabel,
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: colors.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (address.trim().isNotEmpty) ...[
                        const SizedBox(height: GBTSpacing.xxs),
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                      if (type?.isNotEmpty == true ||
                          distance?.isNotEmpty == true) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Wrap(
                          spacing: GBTSpacing.sm,
                          runSpacing: GBTSpacing.xxs,
                          children: [
                            if (type?.isNotEmpty == true)
                              _FieldPlaceMeta(
                                icon: Icons.category_outlined,
                                label: type!,
                                color: colors.secondary,
                              ),
                            if (distance?.isNotEmpty == true)
                              _FieldPlaceMeta(
                                icon: Icons.near_me_outlined,
                                label: distance!,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDirections != null)
                  IconButton(
                    key: const Key('field-place-directions'),
                    onPressed: onDirections,
                    tooltip: context.l10n(
                      ko: '길찾기',
                      en: 'Directions',
                      ja: '経路',
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: GBTSpacing.touchTarget,
                      height: GBTSpacing.touchTarget,
                    ),
                    icon: const Icon(Icons.directions_outlined),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldPlaceMeta extends StatelessWidget {
  const _FieldPlaceMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: GBTSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
