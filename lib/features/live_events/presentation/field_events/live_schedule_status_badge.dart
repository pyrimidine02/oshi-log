/// EN: Cancelled / postponed badge and copy shared by event and calendar views.
/// KO: 이벤트·캘린더 화면이 공유하는 취소/연기 배지와 문구입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/widgets/layout/gbt_field_primitives.dart';
import '../../domain/entities/live_event_entities.dart';

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
