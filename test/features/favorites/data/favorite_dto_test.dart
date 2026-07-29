import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/favorites/data/dto/favorite_dto.dart';

void main() {
  test('FavoriteItemDto parses swagger keys', () {
    final json = {
      'entityId': 'place-1',
      'entityType': 'PLACE',
      'projectCode': 'girls-band-cry',
      'title': '도쿄돔',
      'thumbnailUrl': 'https://example.com/place.png',
    };

    final dto = FavoriteItemDto.fromJson(json);
    expect(dto.entityId, 'place-1');
    expect(dto.entityType, 'PLACE');
    expect(dto.projectCode, 'girls-band-cry');
    expect(dto.title, '도쿄돔');
    expect(dto.thumbnailUrl, 'https://example.com/place.png');
  });

  test(
    'FavoriteItemDto parses nested entity payload and normalizes deeplink ID',
    () {
      final json = {
        'entityType': 'POST',
        'entity': {
          'targetId':
              'https://api.example.com/api/v1/projects/girls-band-cry/posts/38f55757-6953-44d4-abb8-8ab0ec35003e',
          'title': '커뮤니티 글',
          'project': {'code': 'girls-band-cry'},
        },
      };

      final dto = FavoriteItemDto.fromJson(json);
      expect(dto.entityId, '38f55757-6953-44d4-abb8-8ab0ec35003e');
      expect(dto.entityType, 'POST');
      expect(dto.projectCode, 'girls-band-cry');
      expect(dto.title, '커뮤니티 글');
    },
  );
}
