import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/application/board_controller.dart';
import 'package:oshi_log/features/feed/presentation/field_community/widgets/field_community_mode_bar.dart';
import 'package:oshi_log/features/feed/presentation/field_guide/widgets/field_guide_section_switcher.dart';

Widget _host(Widget child, {double textScale = 1}) {
  return MaterialApp(
    theme: GBTTheme.light,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('guide uses native controlled segments with one selected label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    FieldGuideSection? requested;
    await tester.pumpWidget(
      _host(
        FieldGuideSectionSwitcher(
          selected: FieldGuideSection.updates,
          onSelected: (section) => requested = section,
        ),
      ),
    );
    final control = find.byType(SegmentedButton<FieldGuideSection>);
    expect(control, findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      0,
    );
    for (final section in FieldGuideSection.values.skip(1)) {
      await tester.tap(find.byKey(Key('field-guide-section-${section.name}')));
      await tester.pump();
      expect(requested, section);
      expect(
        tester.widget<SegmentedButton<FieldGuideSection>>(control).selected,
        {FieldGuideSection.updates},
      );
    }
    for (final label in ['Updates', 'Artists', 'Fan library']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(label))
            .flagsCollection
            .isSelected,
        label == 'Updates' ? Tristate.isTrue : Tristate.isFalse,
      );
    }
    semantics.dispose();
  });

  testWidgets('community preserves supplied mode order and parent selection', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    CommunityFeedMode? requested;
    const modes = [
      CommunityFeedMode.trending,
      CommunityFeedMode.latest,
      CommunityFeedMode.recommended,
    ];
    await tester.pumpWidget(
      _host(
        FieldCommunityModeBar(
          modes: modes,
          selected: CommunityFeedMode.trending,
          onSelected: (mode) => requested = mode,
        ),
      ),
    );
    final control = find.byType(SegmentedButton<CommunityFeedMode>);
    expect(control, findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      0,
    );
    expect(
      tester
          .widget<SegmentedButton<CommunityFeedMode>>(control)
          .segments
          .map((segment) => segment.value),
      modes,
    );
    expect(find.text('Following'), findsNothing);
    for (final mode in modes.skip(1)) {
      await tester.tap(find.byKey(Key('field-community-mode-${mode.name}')));
      await tester.pump();
      expect(requested, mode);
      expect(
        tester.widget<SegmentedButton<CommunityFeedMode>>(control).selected,
        {CommunityFeedMode.trending},
      );
    }
    for (final label in ['Trending', 'Latest', 'Recommended']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(label))
            .flagsCollection
            .isSelected,
        label == 'Trending' ? Tristate.isTrue : Tristate.isFalse,
      );
    }
    semantics.dispose();
  });

  testWidgets('both controls stay usable at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FieldGuideSection? guideRequest;
    CommunityFeedMode? modeRequest;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            FieldGuideSectionSwitcher(
              selected: FieldGuideSection.updates,
              onSelected: (section) => guideRequest = section,
            ),
            FieldCommunityModeBar(
              modes: CommunityFeedMode.values,
              selected: CommunityFeedMode.recommended,
              onSelected: (mode) => modeRequest = mode,
            ),
          ],
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    final lastGuide = find.byKey(const Key('field-guide-section-kit'));
    await tester.ensureVisible(lastGuide);
    await tester.pumpAndSettle();
    await tester.tap(lastGuide);
    expect(guideRequest, FieldGuideSection.kit);
    for (final mode in CommunityFeedMode.values.skip(1)) {
      final destination = find.byKey(Key('field-community-mode-${mode.name}'));
      await tester.ensureVisible(destination);
      await tester.pumpAndSettle();
      await tester.tap(destination);
      expect(modeRequest, mode);
      expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));
    }
    expect(tester.getSize(lastGuide).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
