import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/search/data/dto/search_discovery_dto.dart';

void main() {
  group('Search discovery DTO', () {
    test('parses popular discovery payload', () {
      final dto = SearchPopularDiscoveryDto.fromJson({
        'updatedAt': '2026-03-08T10:00:00Z',
        'popularKeywords': [
          {'keyword': '라이브', 'score': 120},
          {'keyword': '굿즈', 'score': 88},
        ],
      });

      expect(dto.updatedAt, isNotNull);
      expect(dto.popularKeywords.length, 2);
      expect(dto.popularKeywords.first.keyword, '라이브');
      expect(dto.popularKeywords.first.score, 120);
    });

    test('parses category discovery payload', () {
      final dto = SearchCategoryDiscoveryDto.fromJson({
        'updatedAt': '2026-03-08T10:00:00Z',
        'categories': [
          {'code': 'LIVE', 'label': '라이브', 'contentCount': 241},
          {'code': 'EVENT', 'label': '이벤트', 'contentCount': 132},
        ],
      });

      expect(dto.updatedAt, isNotNull);
      expect(dto.categories.length, 2);
      expect(dto.categories.first.code, 'LIVE');
      expect(dto.categories.first.label, '라이브');
      expect(dto.categories.first.contentCount, 241);
    });
  });
}
