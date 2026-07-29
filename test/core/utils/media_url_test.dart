import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/utils/media_url.dart';

void main() {
  setUpAll(() {
    AppConfig.instance.init(baseUrl: 'http://10.0.2.2:8080');
  });

  test('resolveMediaUrl normalizes legacy R2 host to public CDN', () {
    final resolved = resolveMediaUrl(
      'https://abc.r2.cloudflarestorage.com/girlsbandtabi/uploads/a.webp',
    );

    expect(resolved, 'https://r2.noraneko.cc/uploads/a.webp');
  });

  test('resolveMediaUrl accepts host-only public media URL', () {
    final resolved = resolveMediaUrl('r2.noraneko.cc/uploads/a.webp');

    expect(resolved, 'https://r2.noraneko.cc/uploads/a.webp');
  });

  test('resolveMediaUrl resolves upload object key to public CDN', () {
    final resolved = resolveMediaUrl('/uploads/a.webp');

    expect(resolved, 'https://r2.noraneko.cc/uploads/a.webp');
  });

  test('resolveMediaUrl resolves relative uploads key to public CDN', () {
    final resolved = resolveMediaUrl('uploads/a.webp');

    expect(resolved, 'https://r2.noraneko.cc/uploads/a.webp');
  });

  test(
    'resolveMediaUrl resolves non-upload relative path against API origin',
    () {
      final resolved = resolveMediaUrl('/media/a.webp');

      expect(resolved, 'http://10.0.2.2:8080/media/a.webp');
    },
  );

  test('resolveMediaUrl keeps non-url text unchanged', () {
    final resolved = resolveMediaUrl('not-a-url');

    expect(resolved, 'not-a-url');
  });
}
