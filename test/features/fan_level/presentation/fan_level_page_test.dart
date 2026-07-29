import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/fan_level/application/fan_level_controller.dart';
import 'package:oshi_log/features/fan_level/domain/entities/fan_level.dart';
import 'package:oshi_log/features/fan_level/domain/repositories/fan_level_repository.dart';
import 'package:oshi_log/features/fan_level/presentation/pages/fan_level_page.dart';

class _FakeFanLevelRepository implements FanLevelRepository {
  const _FakeFanLevelRepository(this.profile);

  final FanLevelProfile profile;

  @override
  Future<Result<FanLevelProfile>> fetchProfile() async {
    return Result.success(profile);
  }

  @override
  Future<Result<CheckInResult>> checkIn() async {
    return const Result.failure(UnknownFailure('not used in this test'));
  }
}

void main() {
  testWidgets('shows scored action catalog and only positive XP history', (
    tester,
  ) async {
    final now = DateTime(2026, 3, 30, 12, 0);
    final profile = FanLevelProfile(
      userId: 'user-1',
      grade: FanGrade.beginner,
      totalXp: 120,
      currentLevelXp: 20,
      nextLevelXp: 200,
      rank: 12,
      recentActivities: [
        FanActivity(
          id: 'a1',
          type: FanActivityType.placeVisit,
          xpEarned: 25,
          earnedAt: now,
        ),
        FanActivity(
          id: 'a2',
          type: FanActivityType.dailyCheckIn,
          xpEarned: 10,
          earnedAt: DateTime(2026, 3, 29, 8, 0),
        ),
        FanActivity(
          id: 'a3',
          type: FanActivityType.bookmark,
          xpEarned: 0,
          earnedAt: DateTime(2026, 3, 28, 9, 0),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fanLevelRepositoryProvider.overrideWithValue(
            _FakeFanLevelRepository(profile),
          ),
        ],
        child: const MaterialApp(locale: Locale('en'), home: FanLevelPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Scored Actions'), findsOneWidget);
    expect(find.text('Daily Check-in'), findsWidgets);
    expect(find.text('Place Visit'), findsWidgets);
    expect(find.text('Live Attendance'), findsOneWidget);
    expect(find.text('Post Created'), findsOneWidget);
    expect(find.text('Comment Created'), findsOneWidget);
    expect(find.text('Post Liked'), findsOneWidget);
    expect(find.text('Admin Grant'), findsOneWidget);
    expect(find.text('Other Activity'), findsOneWidget);

    expect(find.text('Scored History'), findsOneWidget);
    expect(find.text('+25 XP'), findsWidgets);
    expect(find.text('+10 XP'), findsWidgets);
    expect(find.text('+0 XP'), findsNothing);
    expect(find.text('Bookmark Added'), findsNothing);
  });

  testWidgets(
    'uses the field-notes document hierarchy at 320dp and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profile = FanLevelProfile(
        userId: 'user-1',
        grade: FanGrade.enthusiast,
        totalXp: 420,
        currentLevelXp: 120,
        nextLevelXp: 800,
        rank: 7,
        recentActivities: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fanLevelRepositoryProvider.overrideWithValue(
              _FakeFanLevelRepository(profile),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            theme: ThemeData.dark(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const FanLevelPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TRAVEL RECORD / FAN LEVEL'), findsOneWidget);
      expect(find.text('Fan Level'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
