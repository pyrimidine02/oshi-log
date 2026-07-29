import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/presentation/widgets/post_compose_components.dart';

void main() {
  group('sanitizePostTags', () {
    test('normalizes, deduplicates and enforces limits', () {
      final tags = sanitizePostTags([
        '#라이브',
        ' 라이브 ',
        '굿 즈',
        '세트리스트',
        '질문',
        '후기',
        '12345678901234567',
      ]);

      expect(tags, ['라이브', '굿즈', '세트리스트', '질문', '후기']);
    });

    test('supports custom limits', () {
      final tags = sanitizePostTags(
        ['a', 'bb', 'ccc'],
        maxCount: 2,
        maxLength: 2,
      );

      expect(tags, ['a', 'bb']);
    });
  });
}
