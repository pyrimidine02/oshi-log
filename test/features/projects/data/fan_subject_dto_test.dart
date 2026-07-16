import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/projects/data/dto/fan_subject_dto.dart';

void main() {
  test('known fan subject kinds preserve their wire contract', () {
    const expected = {
      'PROJECT': FanSubjectKind.project,
      'UNIT': FanSubjectKind.unit,
      'VOICE_ACTOR': FanSubjectKind.voiceActor,
      'ARTIST': FanSubjectKind.artist,
      'ANIME': FanSubjectKind.anime,
    };

    for (final entry in expected.entries) {
      expect(FanSubjectKind.fromWire(entry.key), entry.value);
      expect(entry.value.wireName, entry.key);
    }
    expect(FanSubjectKind.fromWire('future_type'), FanSubjectKind.unknown);
  });

  test(
    'fan subject DTO keeps source identity independent from subject type',
    () {
      final dto = FanSubjectDto.fromJson({
        'id': 'subject-1',
        'type': 'VOICE_ACTOR',
        'entityId': 'actor-1',
        'key': 'voice-actor:actor-1',
        'name': '림요미',
        'description': '성우',
        'imageUrl': 'https://cdn.example/actor.webp',
      });

      expect(dto.id, 'subject-1');
      expect(dto.type, FanSubjectKind.voiceActor);
      expect(dto.entityId, 'actor-1');
      expect(dto.key, 'voice-actor:actor-1');
    },
  );

  test('subscription DTO accepts nested subject metadata', () {
    final dto = FanSubjectSubscriptionDto.fromJson({
      'subject': {
        'id': 'subject-2',
        'type': 'UNIT',
        'entityId': 'unit-1',
        'key': 'unit:bang-dream:mygo',
        'name': 'MyGO!!!!!',
      },
      'subscribed': true,
      'subscribedAt': '2026-07-16T00:00:00Z',
    });

    expect(dto.subject.type, FanSubjectKind.unit);
    expect(dto.subscribed, isTrue);
    expect(dto.subscribedAt, DateTime.utc(2026, 7, 16));
  });

  test('artist and anime subjects round-trip as first-class types', () {
    for (final entry in const {
      'ARTIST': FanSubjectKind.artist,
      'ANIME': FanSubjectKind.anime,
    }.entries) {
      final dto = FanSubjectDto.fromJson({
        'id': 'subject-${entry.key}',
        'type': entry.key,
        'sourceId': 'source-${entry.key}',
        'canonicalKey': 'subject:${entry.key}',
        'displayName': entry.key,
      });

      expect(dto.type, entry.value);
      expect(dto.toJson()['type'], entry.key);
      expect(dto.entityId, 'source-${entry.key}');
    }
  });
}
