/// EN: Immutable presentation data for the field visit ledger.
/// KO: 탐방 원장을 위한 불변 프레젠테이션 데이터입니다.
library;

import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/visits/domain/entities/visit_entities.dart';

typedef FieldVisitPlaceMetadata = ({
  PlaceSummary place,
  String projectId,
  String projectName,
});

/// EN: A resolved place-visit row backed only by API entities.
/// KO: API 엔티티만으로 구성한 장소 방문 행입니다.
class FieldPlaceLedgerEntry {
  const FieldPlaceLedgerEntry({required this.visit, this.metadata});

  final VisitEvent visit;
  final FieldVisitPlaceMetadata? metadata;

  DateTime? get recordedAt => visit.visitedAt;
  PlaceSummary? get place => metadata?.place;
  String? get projectName => metadata?.projectName;
  bool get isGpsVerified => visit.isVerified;
}

/// EN: Factual place-ledger totals and chronologically ordered entries.
/// KO: 사실 기반 장소 원장 지표와 시간순 항목입니다.
class FieldPlaceLedgerData {
  const FieldPlaceLedgerData._({
    required this.entries,
    required this.totalRecords,
    required this.uniquePlaces,
    required this.projectCount,
  });

  factory FieldPlaceLedgerData.from({
    required List<VisitEvent> visits,
    required Map<String, FieldVisitPlaceMetadata> places,
  }) {
    final entries =
        visits
            .map(
              (visit) => FieldPlaceLedgerEntry(
                visit: visit,
                metadata: places[visit.placeId],
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => _compareNewest(a.recordedAt, b.recordedAt));
    final projectIds = entries
        .map((entry) => entry.metadata?.projectId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    return FieldPlaceLedgerData._(
      entries: List.unmodifiable(entries),
      totalRecords: entries.length,
      uniquePlaces: visits.map((visit) => visit.placeId).toSet().length,
      projectCount: projectIds.length,
    );
  }

  final List<FieldPlaceLedgerEntry> entries;
  final int totalRecords;
  final int uniquePlaces;
  final int projectCount;
}

/// EN: A resolved event-attendance row backed by attendance history.
/// KO: 출석 기록을 기반으로 구성한 이벤트 출석 행입니다.
class FieldEventLedgerEntry {
  const FieldEventLedgerEntry({
    required this.record,
    required this.projectName,
  });

  final LiveAttendanceHistoryRecord record;
  final String projectName;

  DateTime? get recordedAt => record.attendedAt ?? record.showStartTime;
  bool get isVerified =>
      LiveAttendanceStatus.normalize(record.status) ==
      LiveAttendanceStatus.verified;
}

/// EN: Factual attendance totals and chronologically ordered event entries.
/// KO: 사실 기반 출석 지표와 시간순 이벤트 항목입니다.
class FieldEventLedgerData {
  const FieldEventLedgerData._({
    required this.entries,
    required this.totalRecords,
    required this.verifiedRecords,
    required this.projectCount,
  });

  factory FieldEventLedgerData.from({
    required List<LiveAttendanceHistoryRecord> records,
    required Map<String, String> projectNames,
  }) {
    final entries =
        records
            .map(
              (record) => FieldEventLedgerEntry(
                record: record,
                projectName:
                    projectNames[record.projectKey] ?? record.projectKey,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => _compareNewest(a.recordedAt, b.recordedAt));

    return FieldEventLedgerData._(
      entries: List.unmodifiable(entries),
      totalRecords: entries.length,
      verifiedRecords: entries.where((entry) => entry.isVerified).length,
      projectCount: records
          .map((record) => record.projectKey)
          .where((key) => key.isNotEmpty)
          .toSet()
          .length,
    );
  }

  final List<FieldEventLedgerEntry> entries;
  final int totalRecords;
  final int verifiedRecords;
  final int projectCount;
}

int _compareNewest(DateTime? a, DateTime? b) {
  final aValue = a ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bValue = b ?? DateTime.fromMillisecondsSinceEpoch(0);
  return bValue.compareTo(aValue);
}

/// EN: A typed, namespaced record in the combined visit/attendance timeline.
/// KO: 방문/참전 통합 타임라인의 유형과 네임스페이스를 가진 기록입니다.
class UnifiedRecordEntry {
  const UnifiedRecordEntry.visit(FieldPlaceLedgerEntry entry)
    : visit = entry,
      event = null;
  const UnifiedRecordEntry.event(FieldEventLedgerEntry entry)
    : event = entry,
      visit = null;

  final FieldPlaceLedgerEntry? visit;
  final FieldEventLedgerEntry? event;
  String get id => visit != null
      ? 'visit:${visit!.visit.id}'
      : 'attendance:${event!.record.projectKey}:${event!.record.attendanceId ?? event!.record.eventId}';
  DateTime? get recordedAt => visit?.recordedAt ?? event?.recordedAt;
}

/// EN: Deduplicates within each source and sorts known dates newest first.
/// KO: 소스별 중복을 제거하고 확인된 날짜를 최신순으로 정렬합니다.
List<UnifiedRecordEntry> composeUnifiedRecords({
  required Iterable<FieldPlaceLedgerEntry> visits,
  required Iterable<FieldEventLedgerEntry> events,
}) {
  final records = <String, UnifiedRecordEntry>{};
  for (final entry in [
    ...visits.map(UnifiedRecordEntry.visit),
    ...events.map(UnifiedRecordEntry.event),
  ]) {
    records[entry.id] = entry;
  }
  return List.unmodifiable(
    records.values.toList()..sort((a, b) {
      final dateOrder = _compareNewest(a.recordedAt, b.recordedAt);
      return dateOrder == 0 ? a.id.compareTo(b.id) : dateOrder;
    }),
  );
}
