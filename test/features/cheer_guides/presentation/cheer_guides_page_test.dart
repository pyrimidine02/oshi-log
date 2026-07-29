import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/features/cheer_guides/application/cheer_guides_controller.dart';
import 'package:oshi_log/features/cheer_guides/domain/entities/cheer_guide.dart';
import 'package:oshi_log/features/cheer_guides/presentation/pages/cheer_guides_page.dart';

void main() {
  testWidgets(
    'renders the indexed guide document at 320dp and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guides = [
        CheerGuideSummary(
          id: 'guide-1',
          songId: 'song-1',
          songTitle: 'Returns',
          artistName: 'Poppin Party',
          difficulty: 4,
          sectionCount: 8,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedProjectKeyProvider.overrideWith((ref) => 'project-1'),
            cheerGuidesListProvider(
              'project-1',
            ).overrideWith((ref) async => guides),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const CheerGuidesPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FIELD GUIDE / CALL INDEX · 01'), findsOneWidget);
      expect(find.text('Returns'), findsOneWidget);
      expect(find.text('★ 4/5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
