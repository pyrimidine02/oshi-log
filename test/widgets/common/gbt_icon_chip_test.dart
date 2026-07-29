import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/core/widgets/common/gbt_icon_chip.dart';

void main() {
  testWidgets('GBTIconChip chooses an accessible glyph color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            GBTIconChip(icon: Icons.event, color: GBTColors.accent),
            GBTIconChip(icon: Icons.place, color: GBTColors.primary),
          ],
        ),
      ),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.event)).color,
      GBTColors.textPrimary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.place)).color,
      GBTColors.textInverse,
    );
  });
}
