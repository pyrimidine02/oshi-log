import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/utils/image_url_extractor.dart';

void main() {
  setUpAll(() {
    AppConfig.instance.init(baseUrl: 'http://10.0.2.2:8080');
  });

  test('extractImageUrls supports markdown relative upload paths', () {
    const content = '본문\n![](/uploads/sample.webp)\n';

    final urls = extractImageUrls(content);

    expect(urls, contains('/uploads/sample.webp'));
  });

  test('extractImageUrls supports scheme-less R2 URLs', () {
    const content = '본문\n![](r2.noraneko.cc/uploads/sample.webp)\n';

    final urls = extractImageUrls(content);

    expect(urls, contains('r2.noraneko.cc/uploads/sample.webp'));
  });

  test('stripImageMarkdown removes relative markdown image blocks', () {
    const content = 'line1\n![](/uploads/sample.webp)\nline2';

    final stripped = stripImageMarkdown(content);

    expect(stripped, isNot(contains('![](')));
    expect(stripped, contains('line1'));
    expect(stripped, contains('line2'));
  });
}
