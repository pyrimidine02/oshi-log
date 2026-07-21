import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/feed_entities.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/field_guide/field_guide_page.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/field_guide/field_guide_providers.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/project_entities.dart';

void main() {
  final updates = <NewsSummary>[
    NewsSummary(
      id: 'news-featured',
      title: 'Tour announcements and ticket guide',
      publishedAt: DateTime.utc(2026, 7, 15),
    ),
    NewsSummary(
      id: 'news-2',
      title: 'Pop-up store field report',
      publishedAt: DateTime.utc(2026, 7, 12),
    ),
  ];
  final artists = <Unit>[
    const Unit(
      id: 'unit-mygo',
      code: 'mygo',
      displayName: 'MyGO!!!!!',
      description: 'A band finding its way through the city.',
      colorHex: '#2B7773',
      memberSummaries: [
        UnitMemberSummary(id: '1', characterName: 'Tomori'),
        UnitMemberSummary(id: '2', characterName: 'Anon'),
        UnitMemberSummary(id: '3', characterName: 'Rāna'),
        UnitMemberSummary(id: '4', characterName: 'Soyo'),
        UnitMemberSummary(id: '5', characterName: 'Taki'),
      ],
    ),
  ];

  Widget buildSubject({
    Locale locale = const Locale('en'),
    ThemeData? theme,
    AsyncValue<List<NewsSummary>>? updatesState,
    AsyncValue<List<Unit>>? artistsState,
    String? projectKey = 'bandori',
  }) {
    return ProviderScope(
      overrides: [
        fieldGuideUpdatesProvider.overrideWith(
          (ref) => updatesState ?? AsyncData(updates),
        ),
        fieldGuideArtistsProvider.overrideWith(
          (ref) => artistsState ?? AsyncData(artists),
        ),
        fieldGuideProjectKeyProvider.overrideWith((ref) => projectKey),
      ],
      child: MaterialApp(
        locale: locale,
        theme: theme ?? GBTTheme.light,
        home: const FieldGuidePage(),
      ),
    );
  }

  testWidgets('starts with a compact localized information header', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Field guide'), findsOneWidget);
    expect(find.text('Bandori'), findsOneWidget);
    expect(find.text('GBT / TRAVEL & FANDOM'), findsNothing);
    expect(find.text('ISSUE 01'), findsNothing);
    expect(find.text('01'), findsNothing);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Fan library'), findsOneWidget);
    expect(find.text('Tour announcements and ticket guide'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('field-guide-updates-scroll')),
      const Offset(0, -240),
    );
    await tester.pump();
    expect(find.text('Pop-up store field report'), findsOneWidget);
  });

  testWidgets('switches between artists and the practical field kit', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(const Key('field-guide-section-artists')));
    await tester.pumpAndSettle();

    expect(find.text('MyGO!!!!!'), findsOneWidget);
    expect(find.text('5 members'), findsOneWidget);

    await tester.tap(find.byKey(const Key('field-guide-section-kit')));
    await tester.pumpAndSettle();

    expect(find.text('FAN REFERENCE'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Music & cheering'), findsOneWidget);
    expect(find.text('Memories & collection'), findsOneWidget);
    expect(find.text('Music & lyrics'), findsOneWidget);
    expect(find.text('Cheer guides'), findsOneWidget);
    expect(find.text('Event calendar'), findsOneWidget);
  });

  testWidgets('keeps all three guide destinations usable at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    for (final key in const [
      Key('field-guide-section-updates'),
      Key('field-guide-section-artists'),
      Key('field-guide-section-kit'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps section navigation visible and can jump to oldest news', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('field-guide-updates-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(find.text('Fan library'), findsOneWidget);

    await tester.tap(find.byKey(const Key('field-guide-update-filter-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest first'));
    await tester.pumpAndSettle();

    final olderTop = tester
        .getTopLeft(find.text('Pop-up store field report'))
        .dy;
    final newerTop = tester
        .getTopLeft(find.text('Tour announcements and ticket guide'))
        .dy;
    expect(olderTop, lessThan(newerTop));
  });

  testWidgets('explains empty updates and a missing project in context', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        updatesState: const AsyncData(<NewsSummary>[]),
        artistsState: const AsyncData(<Unit>[]),
        projectKey: null,
      ),
    );
    await tester.pump();

    expect(find.text('No field updates yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('field-guide-section-artists')));
    await tester.pump();

    expect(find.text('Choose a project first'), findsOneWidget);
  });

  testWidgets('uses the night field palette without changing destinations', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(theme: GBTTheme.dark));
    await tester.pump();

    await tester.tap(find.byKey(const Key('field-guide-section-kit')));
    await tester.pump();

    expect(find.text('Music & lyrics'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pump();
    expect(find.text('Collection index'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
