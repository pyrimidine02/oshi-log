/// EN: Floating mode dock for the Explore workspace.
/// KO: 탐방 워크스페이스용 플로팅 모드 도크.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// EN: A compact secondary dock that sits above the app-wide navigation.
/// KO: 앱 전역 내비게이션 위에 배치되는 컴팩트 보조 도크입니다.
class FieldExploreModeDock extends StatelessWidget {
  const FieldExploreModeDock({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  }) : assert(labels.length == 4);

  /// EN: Fixed visual height used by the Explore content-clearance contract.
  /// KO: 탐방 콘텐츠 여백 계약에서 사용하는 고정 시각 높이입니다.
  static const double height = 60;

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  static const _icons = <IconData>[
    Icons.map_outlined,
    Icons.event_note_outlined,
    Icons.route_outlined,
    Icons.collections_bookmark_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SizedBox(
      key: const ValueKey('field-explore-mode-dock'),
      height: height,
      child: Material(
        color: colors.surface.withValues(alpha: isDark ? 0.96 : 0.98),
        elevation: isDark ? 10 : 7,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.46 : 0.18),
        surfaceTintColor: colors.primary.withValues(alpha: 0.04),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          side: BorderSide(
            color: isDark
                ? colors.outlineVariant.withValues(alpha: 0.74)
                : colors.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.xs),
          child: Row(
            children: [
              for (var index = 0; index < labels.length; index++)
                Expanded(
                  child: _ModeDestination(
                    index: index,
                    icon: _icons[index],
                    label: labels[index],
                    isSelected: selectedIndex == index,
                    showIcon: textScale <= 1.35,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeDestination extends StatelessWidget {
  const _ModeDestination({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.showIcon,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          key: ValueKey('field-explore-mode-$index'),
          color: isSelected ? colors.primary : Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: GBTSpacing.touchTarget,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showIcon ? GBTSpacing.xs : GBTSpacing.xxs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showIcon) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: GBTSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
