import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/uploads/application/upload_routing_policy.dart';

void main() {
  group('shouldUseDirectUploadForContentType', () {
    test('returns true for gif images', () {
      expect(shouldUseDirectUploadForContentType('image/gif'), isTrue);
    });

    test('returns true for non-gif images', () {
      expect(shouldUseDirectUploadForContentType('image/jpeg'), isTrue);
      expect(shouldUseDirectUploadForContentType('image/webp'), isTrue);
    });

    test('returns false for non-image files', () {
      expect(shouldUseDirectUploadForContentType('application/pdf'), isFalse);
    });
  });
}
