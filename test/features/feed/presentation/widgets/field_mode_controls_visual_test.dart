import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/application/board_controller.dart';
import 'package:oshi_log/features/feed/presentation/field_community/widgets/field_community_mode_bar.dart';
import 'package:oshi_log/features/feed/presentation/field_guide/widgets/field_guide_section_switcher.dart';

import '../../../../testing/tolerant_local_file_comparator.dart';

void main() {
  testWidgets('mode controls share the light app theme', (tester) async {
    await _pumpPreview(tester, theme: GBTTheme.light);
    await expectLater(
      find.byKey(const ValueKey('field-mode-controls-preview')),
      matchesGoldenFile(_goldenPath('field_mode_controls_light.png')),
    );
  });

  testWidgets('mode controls share the dark app theme', (tester) async {
    await _pumpPreview(tester, theme: GBTTheme.dark);
    await expectLater(
      find.byKey(const ValueKey('field-mode-controls-preview')),
      matchesGoldenFile(_goldenPath('field_mode_controls_dark.png')),
    );
  });

  testWidgets('mode controls accommodate 320dp and 200 percent text', (
    tester,
  ) async {
    await _pumpPreview(
      tester,
      theme: GBTTheme.light,
      width: 320,
      textScaler: const TextScaler.linear(2),
    );
    await expectLater(
      find.byKey(const ValueKey('field-mode-controls-preview')),
      matchesGoldenFile(_goldenPath('field_mode_controls_compact.png')),
    );
  });
}

/// EN: Uses a baseline matching the host renderer.
/// KO: 실행 호스트 렌더러에 맞는 기준 이미지를 사용합니다.
String _goldenPath(String fileName) {
  return Platform.isLinux ? 'goldens/linux/$fileName' : 'goldens/$fileName';
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required ThemeData theme,
  double width = 390,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await loadAppFonts();
  final previousComparator = goldenFileComparator;
  goldenFileComparator = TolerantLocalFileComparator(
    Uri.file(
      '${Directory.current.path}/test/features/feed/presentation/widgets/'
      'field_mode_controls_visual_test.dart',
    ),
    precisionTolerance: 0.015,
  );
  addTearDown(() => goldenFileComparator = previousComparator);
  await tester.binding.setSurfaceSize(Size(width, 480));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: RepaintBoundary(
            key: const ValueKey('field-mode-controls-preview'),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '컨트롤 미리보기',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text('정보 탐색', style: theme.textTheme.titleSmall),
                    ),
                    FieldGuideSectionSwitcher(
                      selected: FieldGuideSection.updates,
                      onSelected: (_) {},
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text('커뮤니티 피드', style: theme.textTheme.titleSmall),
                    ),
                    FieldCommunityModeBar(
                      modes: CommunityFeedMode.values,
                      selected: CommunityFeedMode.recommended,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(SegmentedButton<FieldGuideSection>), findsOneWidget);
  expect(find.byType(SegmentedButton<CommunityFeedMode>), findsOneWidget);
  expect(tester.takeException(), isNull);
}
