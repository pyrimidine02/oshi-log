import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/music/presentation/widgets/music_catalog_tab.dart';

void main() {
  testWidgets('short music filter keeps a 48dp touch target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MusicCatalogFilterChip(
              label: 'I',
              selected: false,
              isDark: false,
              accent: GBTColors.secondary,
              chipBg: GBTColors.surfaceVariant,
              textSecondary: GBTColors.textSecondary,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final target = find.descendant(
      of: find.byType(MusicCatalogFilterChip),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
  });

  testWidgets('tappable album track row keeps a 48dp height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicAlbumSheetTrackRow(
            track: const MusicAlbumTrack(
              songId: 'song-1',
              trackNo: 1,
              title: 'Song',
            ),
            isDark: false,
            accent: GBTColors.secondary,
            isTitleTrack: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final target = find.descendant(
      of: find.byType(MusicAlbumSheetTrackRow),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
  });

  testWidgets('unknown album track position stays neutral', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicAlbumSheetTrackRow(
            track: const MusicAlbumTrack(
              songId: 'song-unknown-position',
              trackNo: null,
              title: 'Digital release',
            ),
            isDark: false,
            accent: GBTColors.secondary,
            isTitleTrack: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('null'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Track number unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('album track row handles long metadata at 300 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(3),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MusicAlbumSheetTrackRow(
                track: const MusicAlbumTrack(
                  songId: 'song-1',
                  trackNo: 12,
                  title: 'A very long live arrangement track title',
                  versionCode: 'LIVE ARRANGEMENT',
                  durationMs: 372000,
                ),
                isDark: false,
                accent: GBTColors.secondary,
                isTitleTrack: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MusicAlbumSheetTrackRow)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
