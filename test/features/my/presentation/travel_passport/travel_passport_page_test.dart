import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/calendar/application/calendar_controller.dart';
import 'package:girlsbandtabi_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:girlsbandtabi_app/features/fan_level/application/fan_level_controller.dart';
import 'package:girlsbandtabi_app/features/fan_level/domain/entities/fan_level.dart';
import 'package:girlsbandtabi_app/features/fan_level/domain/repositories/fan_level_repository.dart';
import 'package:girlsbandtabi_app/features/my/presentation/travel_passport/travel_passport_page.dart';
import 'package:girlsbandtabi_app/features/settings/application/settings_controller.dart';
import 'package:girlsbandtabi_app/features/settings/domain/entities/user_profile.dart';

void main() {
  testWidgets('refresh stays active until both calendar months finish', (
    tester,
  ) async {
    var calendarFetchCount = 0;
    final refreshCompleters = <Completer<List<CalendarEvent>>>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectKeyProvider.overrideWith((ref) => 'band-project'),
          userProfileControllerProvider.overrideWith(
            (ref) => _StaticUserProfileController(ref, _profile()),
          ),
          fanLevelControllerProvider.overrideWith(
            (ref) => _StaticFanLevelNotifier(_fanProfile()),
          ),
          calendarEventsProvider.overrideWith((ref, query) {
            calendarFetchCount++;
            if (calendarFetchCount <= 2) {
              return Future.value(const <CalendarEvent>[]);
            }
            final completer = Completer<List<CalendarEvent>>();
            refreshCompleters.add(completer);
            return completer.future;
          }),
        ],
        child: const MaterialApp(home: TravelPassportPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(calendarFetchCount, 2);

    var refreshFinished = false;
    final refreshFuture = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh()
        .then((_) => refreshFinished = true);
    await tester.pump();

    expect(refreshCompleters, hasLength(2));
    refreshCompleters.first.complete(const <CalendarEvent>[]);
    await tester.pump();
    expect(refreshFinished, isFalse);

    refreshCompleters.last.complete(const <CalendarEvent>[]);
    await refreshFuture;
    await tester.pumpAndSettle();
    expect(refreshFinished, isTrue);
  });
}

class _StaticUserProfileController extends UserProfileController {
  _StaticUserProfileController(super.ref, UserProfile profile) {
    state = AsyncData(profile);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _StaticFanLevelNotifier extends FanLevelNotifier {
  _StaticFanLevelNotifier(FanLevelProfile profile)
    : super(_StaticFanLevelRepository(profile)) {
    state = AsyncData(profile);
  }

  @override
  Future<void> refresh() async {}
}

class _StaticFanLevelRepository implements FanLevelRepository {
  const _StaticFanLevelRepository(this.profile);

  final FanLevelProfile profile;

  @override
  Future<Result<FanLevelProfile>> fetchProfile() async =>
      Result.success(profile);

  @override
  Future<Result<CheckInResult>> checkIn() async => throw UnimplementedError();
}

UserProfile _profile() {
  return UserProfile(
    id: 'traveler-01',
    email: 'hina@example.com',
    displayName: 'Hina',
    role: 'USER',
    accountRole: 'USER',
    baselineAccessLevel: 'MEMBER',
    effectiveAccessLevel: 'MEMBER',
    grants: const [],
    projectRolesByProject: const {},
    createdAt: DateTime(2024, 3, 7),
    totalVisits: 18,
    uniquePlacesVisited: 12,
  );
}

FanLevelProfile _fanProfile() {
  return const FanLevelProfile(
    userId: 'traveler-01',
    grade: FanGrade.devotee,
    totalXp: 4200,
    currentLevelXp: 200,
    nextLevelXp: 1000,
    rank: 27,
  );
}
