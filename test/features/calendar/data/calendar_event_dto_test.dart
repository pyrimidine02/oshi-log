import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/calendar/data/dto/calendar_event_dto.dart';
import 'package:oshi_log/features/calendar/domain/entities/calendar_event.dart';

void main() {
  group('CalendarEventDto backend contract', () {
    test(
      'maps the public calendar response fields without losing metadata',
      () {
        final dto = CalendarEventDto.fromJson(const {
          'id': 'birthday-1',
          'type': 'BIRTHDAY_CHARACTER',
          'title': 'Kasumi birthday',
          'date': '2026-07-14',
          'projectId': 'project-id',
          'projectKey': 'bang-dream',
          'characterId': 'character-id',
          'characterImageUrl': 'https://cdn.example/kasumi.webp',
          'isAnnual': true,
        });

        final event = dto.toEntity();

        expect(event.type, CalendarEventType.characterBirthday);
        expect(event.projectCode, 'bang-dream');
        expect(event.imageUrl, 'https://cdn.example/kasumi.webp');
        expect(event.relatedEntityId, 'character-id');
        expect(event.relatedEntityType, 'character');
        expect(event.isRecurringAnnually, isTrue);
      },
    );

    test('maps all server calendar type names', () {
      expect(
        CalendarEventType.fromString('BIRTHDAY_CHARACTER'),
        CalendarEventType.characterBirthday,
      );
      expect(
        CalendarEventType.fromString('BIRTHDAY_VOICE_ACTOR'),
        CalendarEventType.voiceActorBirthday,
      );
      expect(
        CalendarEventType.fromString('TICKET'),
        CalendarEventType.ticketSale,
      );
      expect(CalendarEventType.fromString('EVENT'), CalendarEventType.general);
    });

    test('projects a live response into a linked calendar event', () {
      final dto = CalendarEventDto.fromLiveEventJson(const {
        'id': 'live-1',
        'title': 'MyGO!!!!! 9th LIVE',
        'showStartTime': '2026-07-17T15:00:00Z',
        'endTime': '2026-07-19T14:59:59Z',
        'bannerUrl': 'https://cdn.example/mygo.webp',
        'projectIds': ['project-id'],
      }, projectKey: 'bang-dream');

      final event = dto.toEntity();

      expect(event.id, 'live:live-1');
      expect(event.type, CalendarEventType.live);
      expect(event.relatedEntityId, 'live-1');
      expect(event.relatedEntityType, 'live_event');
      expect(event.projectId, 'project-id');
      expect(event.projectCode, 'bang-dream');
      expect(event.imageUrl, 'https://cdn.example/mygo.webp');
      expect(event.date, DateTime.parse('2026-07-17T15:00:00Z'));
      expect(dto.endDate, DateTime.parse('2026-07-19T14:59:59Z'));
    });
  });
}
