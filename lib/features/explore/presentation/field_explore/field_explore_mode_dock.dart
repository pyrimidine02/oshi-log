/// EN: Persistent bottom mode control for non-map Explore pages.
/// KO: 지도 외 탐방 페이지에서 유지되는 하단 모드 제어입니다.
library;

import 'package:flutter/material.dart';

/// EN: Keeps Explore navigation in one stable bottom position.
/// KO: 탐방 내비게이션을 일관된 하단 위치에 유지합니다.
class FieldExploreModeDock extends StatelessWidget {
  const FieldExploreModeDock({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  }) : assert(labels.length == 4);

  static const double height = 48;

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('field-explore-mode-segments'),
      width: double.infinity,
      height: height,
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        segments: [
          for (var index = 0; index < labels.length; index++)
            ButtonSegment<int>(
              value: index,
              label: Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
        ],
        selected: {selectedIndex.clamp(0, labels.length - 1)},
        onSelectionChanged: (selection) => onSelected(selection.first),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, height)),
          visualDensity: VisualDensity.compact,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 6),
          ),
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}
