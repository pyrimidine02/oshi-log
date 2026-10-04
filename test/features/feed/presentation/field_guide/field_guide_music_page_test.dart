import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/music/application/music_controller.dart';
import 'package:oshi_log/features/oshikatsu/music/domain/entities/music_entities.dart';
import 'package:oshi_log/design_system/widgets/layout/gbt_page_header.dart';
import 'package:oshi_log/app/compositions/guide/presentation/field_guide/field_guide_music_page.dart';

void main() {
  testWidgets('archive restores selections and emits only supported filters', (
    tester,
  ) async {
    Map<String, String>? selection;
    await _pumpArchive(
      tester,
      page: FieldGuideMusicPage(
        embedded: true,
        initialSection: 'songs',
        initialQuery: 'Blue',
        initialUnitKey: 'id:band-a',
        initialSort: 'title',
        onSelectionChanged: (value) => selection = value,
      ),
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(GBTPageHeader), findsNothing);
    expect(find.text('Blue'), findsNWidgets(2));
    expect(find.text('Amber'), findsNothing);
    expect(find.textContaining('First album'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('music-catalog-search')),
      'Amber',
    );
    await tester.pumpAndSettle();
    expect(selection, {
      'archiveSection': 'songs',
      'unit': 'id:band-a',
      'q': 'Amber',
      'sort': 'title',
    });
    await tester.tap(find.byKey(const ValueKey('music-archive-albums')));
    await tester.pumpAndSettle();
    expect(selection?['archiveSection'], 'albums');
    expect(selection?['q'], 'Amber');

    // EN: A route update must replace the existing widget's local selection.
    // KO: 경로가 바뀌면 유지된 위젯의 선택도 URL 값으로 바뀌어야 합니다.
    await _pumpArchive(
      tester,
      page: const FieldGuideMusicPage(
        embedded: true,
        initialSection: 'songs',
        initialQuery: 'Blue',
        initialUnitKey: 'id:band-a',
        initialSort: 'oldest',
      ),
    );
    expect(find.text('Blue'), findsNWidgets(2));
    expect(find.text('Amber'), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('music-archive-songs')))
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'members load only after choosing a band and restore its identity',
    (tester) async {
      final memberLoads = <String>[];
      Map<String, String>? selection;
      await _pumpArchive(
        tester,
        memberLoads: memberLoads,
        page: FieldGuideMusicPage(
          embedded: true,
          initialSection: 'members',
          onSelectionChanged: (value) => selection = value,
        ),
      );
      expect(memberLoads, isEmpty);
      await tester.tap(find.text('Band A'));
      await tester.pumpAndSettle();
      expect(memberLoads, ['band-a-code']);
      expect(selection?['unit'], 'id:band-a');
      expect(find.text('Character A'), findsOneWidget);
      expect(find.textContaining('Performer A'), findsOneWidget);
      expect(find.text('CHARACTER'), findsNothing);
      expect(find.text('BAND · UNIT'), findsOneWidget);
    },
  );

  testWidgets('song ordinals stay fully visible on one line at 200 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpArchive(
      tester,
      locale: const Locale('ko'),
      scale: 2,
      page: const FieldGuideMusicPage(
        embedded: true,
        initialSection: 'songs',
        initialUnitKey: 'id:band-a',
      ),
    );

    for (final ordinal in ['01', '02']) {
      final label = find.text(ordinal);
      expect(label, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(label);
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 2),
      );
      expect(boxes, hasLength(1), reason: '$ordinal must not wrap');
      expect(boxes.single.right, lessThanOrEqualTo(paragraph.size.width));
      expect(boxes.single.bottom, lessThanOrEqualTo(paragraph.size.height));
      expect(paragraph.textScaler.scale(10), 20);
    }
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ko', 'ja']) {
    for (final dark in [false, true]) {
      for (final section in ['songs', 'albums', 'members']) {
        testWidgets(
          '$language $section fits 320dp at 200 percent, dark=$dark',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(320, 640));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            await _pumpArchive(
              tester,
              locale: Locale(language),
              dark: dark,
              scale: 2,
              page: FieldGuideMusicPage(
                embedded: true,
                initialSection: section,
                initialUnitKey: 'id:band-a',
              ),
            );
            expect(tester.takeException(), isNull);
            final vertical = find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            );
            if (vertical.evaluate().isNotEmpty) {
              await tester.drag(vertical.last, const Offset(0, -500));
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            expect(find.byType(ChoiceChip), findsWidgets);
            expect(
              find.text(switch (section) {
                'songs' => 'Blue',
                'albums' => 'First album',
                _ => 'Character A',
              }),
              findsOneWidget,
            );
            await expectLater(
              find.byKey(const ValueKey('music-archive-preview')),
              matchesGoldenFile(
                'goldens/music_archive_${language}_${section}_'
                '${dark ? 'dark' : 'light'}_320_200.png',
              ),
            );
          },
        );
      }
    }
  }

  testWidgets('music archive uses standard chrome at 320dp and 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: GBTTheme.light,
            locale: const Locale('ko'),
            home: const FieldGuideMusicPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GBTPageHeader), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}

class _Selection extends ProjectSelectionController {
  _Selection(super.ref) {
    state = const ProjectSelectionState(projectKey: 'project', unitIds: []);
  }
}

class _Albums extends MusicAlbumsController {
  _Albums(super.ref, super.projectId);

  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = const MusicCursorState(
      items: [
        MusicAlbumSummary(
          id: 'album-a',
          projectId: 'project',
          title: 'First album',
          type: 'ALBUM',
          unitId: 'band-a',
          unitName: 'Band A',
          releaseDate: '2026-01-01',
        ),
      ],
    );
  }
}

class _Songs extends MusicSongsController {
  _Songs(super.ref, super.projectId);

  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = const MusicCursorState(
      items: [
        MusicSongSummary(
          id: 'song-a',
          projectId: 'project',
          title: 'Blue',
          primaryUnitId: 'band-a',
          primaryUnitName: 'Band A',
          albumId: 'album-a',
        ),
        MusicSongSummary(
          id: 'song-b',
          projectId: 'project',
          title: 'Amber',
          primaryUnitId: 'band-a',
          primaryUnitName: 'Band A',
          albumId: 'album-a',
        ),
      ],
    );
  }
}

class _Units extends ProjectUnitsController {
  _Units(super.ref, super.projectKey);

  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncData([
      Unit(id: 'band-a', code: 'band-a-code', displayName: 'Band A'),
      Unit(id: 'band-b', code: 'band-b-code', displayName: 'Band B'),
    ]);
  }
}

class _Members extends UnitMembersController {
  _Members(super.ref, super.projectId, super.unitIdentifier);

  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncData([
      UnitMember(
        id: 'character-a',
        name: 'Character A',
        voiceActorName: 'Performer A',
        role: 'VOCAL',
      ),
    ]);
  }
}

Future<void> _pumpArchive(
  WidgetTester tester, {
  required FieldGuideMusicPage page,
  List<String>? memberLoads,
  Locale locale = const Locale('en'),
  bool dark = false,
  double scale = 1,
}) async {
  await loadAppFonts();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWith(
          (ref) => Completer<LocalStorage>().future,
        ),
        projectSelectionControllerProvider.overrideWith(_Selection.new),
        selectedProjectKeyProvider.overrideWith((ref) => 'project'),
        musicAlbumsControllerProvider.overrideWith(
          (ref, key) => _Albums(ref, key),
        ),
        musicSongsControllerProvider.overrideWith(
          (ref, key) => _Songs(ref, key),
        ),
        projectUnitsControllerProvider.overrideWith(
          (ref, key) => _Units(ref, key),
        ),
        unitMembersControllerProvider.overrideWith((ref, key) {
          memberLoads?.add(key.$2);
          return _Members(ref, key.$1, key.$2);
        }),
      ],
      child: MaterialApp(
        theme: dark ? GBTTheme.dark : GBTTheme.light,
        locale: locale,
        supportedLocales: const [Locale('ko'), Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('music-archive-preview'),
          child: Scaffold(body: page),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
