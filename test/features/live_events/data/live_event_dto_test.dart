import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/live_events/data/dto/live_event_dto.dart';

void main() {
  test('LiveEventSummaryDto parses swagger keys', () {
    final json = {
      'id': 'event-1',
      'title': 'Live Show',
      'showStartTime': '2026-02-01T18:00:00Z',
      'status': 'LIVE',
      'projectIds': ['proj-1'],
      'unitIds': ['unit-1', 'unit-2'],
    };

    final dto = LiveEventSummaryDto.fromJson(json);
    expect(dto.id, 'event-1');
    expect(dto.title, 'Live Show');
    expect(dto.status, 'LIVE');
    expect(dto.showStartTime, DateTime.parse('2026-02-01T18:00:00Z'));
    expect(dto.unitIds.length, 2);
  });

  test('LiveEventDetailDto parses banner and times', () {
    final json = {
      'id': 'event-2',
      'title': 'Show',
      'showStartTime': '2026-03-10T19:00:00Z',
      'doorsOpenTime': '2026-03-10T18:00:00Z',
      'status': 'UPCOMING',
      'projectIds': ['proj-2'],
      'unitIds': ['unit-3'],
      'banner': {
        'imageId': 'img-1',
        'url': 'https://example.com/banner.png',
        'filename': 'banner.png',
        'contentType': 'image/png',
        'fileSize': 1234,
        'uploadedAt': '2026-01-28T00:00:00Z',
        'isPrimary': true,
      },
    };

    final dto = LiveEventDetailDto.fromJson(json);
    expect(dto.doorsOpenTime, DateTime.parse('2026-03-10T18:00:00Z'));
    expect(dto.banner?.url, 'https://example.com/banner.png');
  });

  test('LiveAttendanceStateDto parses v1 attendance payload', () {
    final json = {
      'id': 'attendance-3',
      'liveEventId': 'event-3',
      'attended': true,
      'status': 'DECLARED',
      'canUndo': true,
    };

    final dto = LiveAttendanceStateDto.fromJson(json);
    expect(dto.attendanceId, 'attendance-3');
    expect(dto.liveEventId, 'event-3');
    expect(dto.attended, isTrue);
    expect(dto.status, 'DECLARED');
    expect(dto.canUndo, isTrue);
  });

  test('LiveAttendanceStateDto tolerates fallback keys and bool values', () {
    final json = {
      'eventId': 'event-4',
      'attended': 'false',
      'status': 'none',
      'canUndo': 0,
    };

    final dto = LiveAttendanceStateDto.fromJson(json);
    expect(dto.liveEventId, 'event-4');
    expect(dto.attended, isFalse);
    expect(dto.status, 'NONE');
    expect(dto.canUndo, isFalse);
  });
}
