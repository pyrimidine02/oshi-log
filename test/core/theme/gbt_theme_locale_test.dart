import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/theme/gbt_typography.dart';

void main() {
  group('GBTTheme locale-aware typography', () {
    test('ja text theme uses JP system font fallback, not Pretendard', () {
      final theme = GBTTheme.lightFor('ja');
      final body = theme.textTheme.bodyLarge!;
      expect(body.fontFamily, isNull);
      expect(body.fontFamilyFallback, GBTTypography.jaFontFallback);
    });

    test(
      'ja body text follows height 1.6 / letterSpacing 0.02em / min 14sp',
      () {
        final theme = GBTTheme.lightFor('ja');
        final bodyLarge = theme.textTheme.bodyLarge!;
        expect(bodyLarge.fontSize, 16);
        expect(bodyLarge.height, 1.6);
        expect(bodyLarge.letterSpacing, closeTo(0.32, 0.001));

        final bodySmall = theme.textTheme.bodySmall!;
        expect(bodySmall.fontSize, greaterThanOrEqualTo(14));
        expect(bodySmall.height, 1.6);
      },
    );

    test('ko text theme keeps Pretendard with KR fallback', () {
      final theme = GBTTheme.lightFor('ko');
      final body = theme.textTheme.bodyLarge!;
      expect(body.fontFamily, GBTTypography.primaryFontFamily);
      expect(body.fontFamilyFallback, contains('Noto Sans KR'));
    });

    test('dark theme also applies ja fallback', () {
      final theme = GBTTheme.darkFor('ja');
      final body = theme.textTheme.bodyLarge!;
      expect(body.fontFamily, isNull);
      expect(body.fontFamilyFallback, GBTTypography.jaFontFallback);
    });
  });
}
