import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_colors.dart';
import 'package:girlsbandtabi_app/features/music/domain/entities/music_entities.dart';
import 'package:girlsbandtabi_app/features/music/presentation/widgets/music_catalog_tab.dart';

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
}
