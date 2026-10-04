/// EN: Cancelled / postponed badge and copy shared by event and calendar views.
/// KO: 이벤트·캘린더 화면이 공유하는 취소/연기 배지와 문구입니다.
library;

import 'package:flutter/material.dart';
import '../../domain/event_time_policy.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/widgets/layout/gbt_field_primitives.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';

/// EN: Returns the badge label, or null for a regular scheduled event.
/// KO: 배지 문구를 반환하며, 정상 예정 이벤트는 null입니다.
String? liveScheduleStatusLabel(BuildContext context, String? status) {
  return switch (LiveScheduleStatus.normalize(status)) {
    LiveScheduleStatus.cancelled => context.l10n(
      ko: '취소',
      en: 'Cancelled',
      ja: '中止',
    ),
    LiveScheduleStatus.postponed => context.l10n(
      ko: '연기',
      en: 'Postponed',
      ja: '延期',
    ),
    _ => null,
  };
}

/// EN: Explains why attendance is closed (also used for LIVE_EVENT_NOT_ATTENDABLE).
/// KO: 참여가 막힌 이유를 설명합니다(LIVE_EVENT_NOT_ATTENDABLE 에도 사용).
String liveCancelledMessage(BuildContext context) {
  return context.l10n(
    ko: '이 공연은 취소되었습니다',
    en: 'This show has been cancelled',
    ja: 'この公演は中止になりました',
  );
}

/// EN: True for the server's "not open for attendance" rejection. Toggle and
/// appeal paths reuse older codes, so the server message is matched too.
/// KO: 서버의 "참여 불가" 거절이면 true. 토글·이의제기는 기존 코드를 쓰므로
/// 서버 메시지도 함께 확인합니다.
bool isLiveNotAttendableFailure(Failure failure) {
  return failure.code == 'LIVE_EVENT_NOT_ATTENDABLE' ||
      failure.message.contains('not open for attendance');
}

/// EN: Badge shown only for cancelled or postponed events.
/// KO: 취소되거나 연기된 이벤트에만 표시되는 배지입니다.
class LiveScheduleStatusBadge extends StatelessWidget {
  const LiveScheduleStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final label = liveScheduleStatusLabel(context, status);
    if (label == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final cancelled =
        LiveScheduleStatus.normalize(status) == LiveScheduleStatus.cancelled;
    return GBTFieldBadge(
      label: label,
      icon: cancelled ? Icons.event_busy_rounded : Icons.update_rounded,
      color: cancelled ? colors.error : colors.tertiary,
    );
  }
}

/// EN: One badge per independent schedule, time and attendance axis.
/// KO: 일정 변경, 공연 시간, 참전 기록의 각 독립 축별 배지입니다.
class EventStatusBadges extends StatelessWidget {
  const EventStatusBadges({
    super.key,
    required this.start,
    this.end,
    this.scheduleStatus,
    this.attended = false,
    this.now,
  });
  final DateTime start;
  final DateTime? end;
  final String? scheduleStatus;
  final bool attended;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final schedule = LiveScheduleStatus.normalize(scheduleStatus);
    final label = eventTimeStatusLabel(
      context,
      start: start,
      end: end,
      now: now,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (schedule == LiveScheduleStatus.postponed)
          GBTFieldBadge(
            label: context.l10n(ko: '변경 있음', en: 'Changed', ja: '変更あり'),
            icon: Icons.update,
            color: colors.tertiary,
          ),
        if (schedule == LiveScheduleStatus.cancelled)
          LiveScheduleStatusBadge(status: schedule)
        else if (schedule != LiveScheduleStatus.postponed)
          GBTFieldBadge(
            label: label,
            icon: Icons.schedule,
            color: colors.primary,
          ),
        if (attended)
          GBTFieldBadge(
            label: context.l10n(
              ko: '참전 기록됨',
              en: 'Attendance recorded',
              ja: '参戦済み',
            ),
            icon: Icons.check,
            color: colors.secondary,
          ),
      ],
    );
  }
}

String eventTimeStatusLabel(
  BuildContext context, {
  required DateTime start,
  DateTime? end,
  DateTime? now,
}) {
  return switch (EventTimePolicy.status(
    start: start,
    end: end,
    now: now ?? DateTime.now(),
  )) {
    EventTimeStatus.upcoming => context.l10n(
      ko: '공연 전',
      en: 'Upcoming',
      ja: '開催前',
    ),
    EventTimeStatus.today => context.l10n(
      ko: '오늘 · 종료 미정',
      en: 'Today · end unknown',
      ja: '本日・終演未定',
    ),
    EventTimeStatus.ongoing => context.l10n(
      ko: '진행 중',
      en: 'Ongoing',
      ja: '開催中',
    ),
    EventTimeStatus.ended => context.l10n(ko: '종료', en: 'Ended', ja: '終了'),
    EventTimeStatus.past => context.l10n(
      ko: '지난 일정',
      en: 'Past date',
      ja: '過去の日程',
    ),
  };
}
