import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/search/data/dto/search_item_dto.dart';

void main() {
  test('SearchItemDto parses swagger keys', () {
    final json = {
      'type': 'PLACE',
      'item': {
        'id': 'place-1',
        'name': '도쿄돔',
        'thumbnailUrl': 'https://example.com/place.png',
      },
    };

    final dto = SearchItemDto.fromJson(json);
    expect(dto.type, 'PLACE');
    expect(dto.item['id'], 'place-1');
  });
}
