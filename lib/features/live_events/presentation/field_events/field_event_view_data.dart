/// EN: Immutable selection rules for the field event desk.
/// KO: 필드 이벤트 데스크를 위한 불변 선택 규칙입니다.
library;

import 'dart:collection';

import '../../domain/entities/live_event_entities.dart';

/// EN: Event time horizon shown by the event desk.
/// KO: 이벤트 데스크에서 표시하는 시간 범위입니다.
enum FieldEventMode { upcoming, archive }

/// EN: Immutable event filters shared by list widgets and tests.
/// KO: 목록 위젯과 테스트가 공유하는 불변 이벤트 필터입니다.
class FieldEventFilter {
  FieldEventFilter({
    required this.mode,
    List<String> unitIds = const [],
    this.year,
  }) : unitIds = UnmodifiableListView(unitIds);

  final FieldEventMode mode;
  final List<String> unitIds;
  final int? year;

  FieldEventFilter copyWith({
    FieldEventMode? mode,
    List<String>? unitIds,
    int? year,
    bool clearYear = false,
  }) {
    return FieldEventFilter(
      mode: mode ?? this.mode,
      unitIds: unitIds ?? this.unitIds,
      year: clearYear ? null : (year ?? this.year),
    );
  }
}

/// EN: Filters and sorts without mutating repository-owned collections.
/// KO: 리포지토리 소유 컬렉션을 변경하지 않고 필터링하고 정렬합니다.
List<LiveEventSummary> selectFieldEvents(
  List<LiveEventSummary> events, {
  required FieldEventFilter filter,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final selected = events
      .where((event) {
        final isUpcoming = !event.showStartTime.isBefore(reference);
        if (filter.mode == FieldEventMode.upcoming && !isUpcoming) return false;
        if (filter.mode == FieldEventMode.archive && isUpcoming) return false;
        if (filter.year != null &&
            event.showStartTime.toLocal().year != filter.year) {
          return false;
        }
        if (filter.unitIds.isNotEmpty &&
            !event.unitIds.any(filter.unitIds.contains)) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
  final sorted = [...selected]
    ..sort((first, second) {
      final order = first.showStartTime.compareTo(second.showStartTime);
      return filter.mode == FieldEventMode.upcoming ? order : -order;
    });
  return List.unmodifiable(sorted);
}

/// EN: Returns descending archive years for the year filter.
/// KO: 연도 필터용 지난 이벤트 연도를 내림차순으로 반환합니다.
List<int> completedFieldEventYears(
  List<LiveEventSummary> events, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final years =
      events
          .where((event) => event.showStartTime.isBefore(reference))
          .map((event) => event.showStartTime.toLocal().year)
          .toSet()
          .toList()
        ..sort((first, second) => second.compareTo(first));
  return List.unmodifiable(years);
}
