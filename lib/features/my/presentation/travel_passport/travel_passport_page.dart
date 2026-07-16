/// EN: Provider and navigation adapter for the clean-sheet travel-passport My root.
/// KO: 새로 설계한 여행 여권 마이 루트를 위한 프로바이더 및 네비게이션 어댑터입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../calendar/application/calendar_controller.dart';
import '../../../calendar/domain/entities/calendar_event.dart';
import '../../../fan_level/application/fan_level_controller.dart';
import '../../../settings/application/settings_controller.dart';
import 'travel_passport_view.dart';
import 'travel_passport_view_data.dart';

/// EN: New My-tab entry that composes existing account and calendar sources.
/// KO: 기존 계정 및 캘린더 소스를 조합하는 새로운 마이 탭 진입점입니다.
class TravelPassportPage extends ConsumerWidget {
  const TravelPassportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final selectedProjectKey = ref.watch(selectedProjectKeyProvider);
    final projectKey = selectedProjectKey?.isNotEmpty == true
        ? selectedProjectKey
        : null;
    final CalendarEventsQuery currentQuery = (
      year: now.year,
      month: now.month,
      projectKey: projectKey,
    );
    final nextMonth = DateTime(now.year, now.month + 1);
    final CalendarEventsQuery nextQuery = (
      year: nextMonth.year,
      month: nextMonth.month,
      projectKey: projectKey,
    );

    final profileState = ref.watch(userProfileControllerProvider);
    final profile = profileState.valueOrNull;
    final profileStatus = profileState.isLoading
        ? PassportProfileStatus.loading
        : profileState.hasError
        ? PassportProfileStatus.unavailable
        : PassportProfileStatus.ready;
    final fanProfile = ref.watch(fanLevelControllerProvider).valueOrNull;
    final currentEventsState = ref.watch(calendarEventsProvider(currentQuery));
    final nextEventsState = ref.watch(calendarEventsProvider(nextQuery));
    final currentEvents =
        currentEventsState.valueOrNull ?? const <CalendarEvent>[];
    final nextEvents = nextEventsState.valueOrNull ?? const <CalendarEvent>[];
    final hasCalendarEvents = currentEvents.isNotEmpty || nextEvents.isNotEmpty;
    final scheduleStatus = hasCalendarEvents
        ? PassportScheduleStatus.ready
        : currentEventsState.isLoading || nextEventsState.isLoading
        ? PassportScheduleStatus.loading
        : currentEventsState.hasError || nextEventsState.hasError
        ? PassportScheduleStatus.unavailable
        : PassportScheduleStatus.ready;
    final data = TravelPassportViewData.fromDomain(
      profile: profile,
      fanProfile: fanProfile,
      calendarEvents: [...currentEvents, ...nextEvents],
      now: now,
      profileStatus: profileStatus,
      scheduleStatus: scheduleStatus,
    );

    return TravelPassportView(
      data: data,
      onRefresh: () async {
        await Future.wait<void>([
          ref
              .read(userProfileControllerProvider.notifier)
              .load(forceRefresh: true),
          ref.read(fanLevelControllerProvider.notifier).refresh(),
          ref
              .refresh(calendarEventsProvider(currentQuery).future)
              .then<void>((_) {}),
          ref
              .refresh(calendarEventsProvider(nextQuery).future)
              .then<void>((_) {}),
        ]);
      },
      onOpenSettings: context.goToSettings,
      onOpenFanLevel: () => context.pushNamed(AppRoutes.fanLevel),
      onOpenCalendar: () => context.pushNamed(AppRoutes.calendar),
      onOpenStop: (stop) {
        final liveEventId = stop.relatedLiveEventId;
        if (liveEventId != null) {
          context.goToEventDetail(liveEventId);
          return;
        }
        context.pushNamed(AppRoutes.calendar);
      },
      onOpenVisits: context.goToVisitHistory,
      onOpenCollection: () => context.pushNamed(AppRoutes.zukan),
      onOpenBookmarks: context.goToPostBookmarks,
      onOpenFavorites: () => context.pushNamed(AppRoutes.favorites),
    );
  }
}
