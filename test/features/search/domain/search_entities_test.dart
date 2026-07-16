import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/search/data/dto/search_item_dto.dart';
import 'package:girlsbandtabi_app/features/search/domain/entities/search_entities.dart';

void main() {
  test('maps a voice actor fan subject to its navigable source identity', () {
    final item = SearchItem.fromDto(
      const SearchItemDto(
        type: 'FAN_SUBJECT',
        item: {
          'id': 'subject-1',
          'sourceId': 'voice-actor-1',
          'subjectType': 'VOICE_ACTOR',
          'title': 'Aimi',
        },
      ),
      projectId: 'project-1',
    );

    expect(item.type, SearchItemType.voiceActor);
    expect(item.sourceId, 'voice-actor-1');
    expect(item.projectId, 'project-1');
  });

  test('maps public user results without requiring email metadata', () {
    final item = SearchItem.fromDto(
      const SearchItemDto(
        type: 'USER',
        item: {'id': 'user-1', 'title': 'Traveler'},
      ),
    );

    expect(item.type, SearchItemType.user);
    expect(item.sourceId, 'user-1');
  });

  test('maps project and unit fan subjects by subtype', () {
    final project = SearchItem.fromDto(
      const SearchItemDto(
        type: 'FAN_SUBJECT',
        item: {
          'id': 'subject-project',
          'sourceId': 'project-source',
          'subjectType': 'PROJECT',
          'canonicalKey': 'project:bang-dream',
          'title': 'BanG Dream!',
        },
      ),
    );
    final unit = SearchItem.fromDto(
      const SearchItemDto(
        type: 'FAN_SUBJECT',
        item: {
          'id': 'subject-unit',
          'sourceId': 'unit-source',
          'subjectType': 'UNIT',
          'title': 'MyGO!!!!!',
        },
      ),
      projectId: 'project-1',
    );

    expect(project.type, SearchItemType.project);
    expect(project.sourceId, 'project-source');
    expect(project.projectKey, 'bang-dream');
    expect(unit.type, SearchItemType.unit);
    expect(unit.sourceId, 'unit-source');
    expect(unit.projectId, 'project-1');
  });

  test('maps artist and anime as first-class fan subjects', () {
    final artist = SearchItem.fromDto(
      const SearchItemDto(
        type: 'FAN_SUBJECT',
        item: {
          'id': 'subject-artist',
          'sourceId': 'artist-source',
          'subjectType': 'ARTIST',
          'title': 'Ado',
        },
      ),
    );
    final anime = SearchItem.fromDto(
      const SearchItemDto(
        type: 'FAN_SUBJECT',
        item: {
          'id': 'subject-anime',
          'sourceId': 'anime-source',
          'subjectType': 'ANIME',
          'title': 'Girls Band Cry',
        },
      ),
    );

    expect(artist.type, SearchItemType.artist);
    expect(anime.type, SearchItemType.anime);
  });

  test(
    'keeps server navigation metadata without replacing source identity',
    () {
      final item = SearchItem.fromDto(
        const SearchItemDto(
          type: 'FAN_SUBJECT',
          item: {
            'id': 'subject-1',
            'sourceId': 'voice-actor-1',
            'subjectType': 'VOICE_ACTOR',
            'title': 'Aimi',
            'navigation': {
              'targetType': 'FAN_SUBJECT',
              'targetId': 'subject-1',
              'route': '/fan-subjects/subject-1',
            },
          },
        ),
      );

      expect(item.sourceId, 'voice-actor-1');
      expect(item.navigationTargetType, 'FAN_SUBJECT');
      expect(item.navigationRoute, '/fan-subjects/subject-1');
    },
  );

  test('keeps generic navigation for future fan subject types', () {
    final item = SearchItem.fromDto(
      const SearchItemDto(
        type: 'FAN_SUBJECT',
        item: {
          'id': 'subject-future',
          'subjectType': 'CREATOR',
          'title': 'Future creator',
          'navigation': {
            'targetType': 'FAN_SUBJECT',
            'targetId': 'subject-future',
            'route': '/fan-subjects/subject-future',
          },
        },
      ),
    );

    expect(item.type, SearchItemType.unknown);
    expect(item.id, 'subject-future');
    expect(item.navigationTargetType, 'FAN_SUBJECT');
  });
}
