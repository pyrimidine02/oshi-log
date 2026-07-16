import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_font_licenses.dart';

void main() {
  testWidgets('registers the bundled Pretendard license', (tester) async {
    registerGBTFontLicenses();

    final entry = await LicenseRegistry.licenses.firstWhere(
      (candidate) => candidate.packages.contains('Pretendard'),
    );
    final text = entry.paragraphs.map((paragraph) => paragraph.text).join('\n');

    expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
  });
}
