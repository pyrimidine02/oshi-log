import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/widgets/navigation/gbt_bottom_nav.dart';

void main() {
  testWidgets('GBTBottomNav triggers onTap with selected index', (
    tester,
  ) async {
    var tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GBTBottomNav(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
            items: const [
              GBTBottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '홈',
              ),
              GBTBottomNavItem(
                icon: Icons.music_note_outlined,
                activeIcon: Icons.music_note,
                label: '라이브',
              ),
            ],
          ),
        ),
      ),
    );

    expect(tappedIndex, -1);

    await tester.tap(find.text('라이브'));
    await tester.pump();

    expect(tappedIndex, 1);
  });

  testWidgets('GBTBottomNav keeps five destinations usable at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GBTBottomNav(
            currentIndex: 4,
            onTap: (_) {},
            items: const [
              GBTBottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),
              GBTBottomNavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Explore',
              ),
              GBTBottomNavItem(
                icon: Icons.event_outlined,
                activeIcon: Icons.event,
                label: 'Schedule',
              ),
              GBTBottomNavItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum,
                label: 'Community',
              ),
              GBTBottomNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'My',
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Community'), findsOneWidget);
  });

  testWidgets('GBTBottomNav has no overflow at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          bottomNavigationBar: GBTBottomNav(
            currentIndex: 4,
            onTap: (_) {},
            items: const [
              GBTBottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '홈',
              ),
              GBTBottomNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: '탐방',
              ),
              GBTBottomNavItem(
                icon: Icons.auto_stories_outlined,
                activeIcon: Icons.auto_stories,
                label: '정보',
              ),
              GBTBottomNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '유저',
              ),
              GBTBottomNavItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum,
                label: '커뮤니티',
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('커뮤니티'), findsOneWidget);
  });
}
