import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/localization/locale_resolution.dart';

void main() {
  const supportedLocales = [
    Locale('ko', 'KR'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ];

  group('resolveAppLocale', () {
    test('ja-JP resolves to supported ja', () {
      expect(
        resolveAppLocale(const Locale('ja', 'JP'), supportedLocales),
        const Locale('ja', 'JP'),
      );
    });

    test('ko-KR resolves to supported ko', () {
      expect(
        resolveAppLocale(const Locale('ko', 'KR'), supportedLocales),
        const Locale('ko', 'KR'),
      );
    });

    test('en-GB resolves to supported en by language code', () {
      expect(
        resolveAppLocale(const Locale('en', 'GB'), supportedLocales),
        const Locale('en', 'US'),
      );
    });

    test('unsupported locale (fr) falls back to ja', () {
      expect(
        resolveAppLocale(const Locale('fr'), supportedLocales),
        fallbackAppLocale,
      );
      expect(fallbackAppLocale, const Locale('ja', 'JP'));
    });

    test('null device locale falls back to ja', () {
      expect(resolveAppLocale(null, supportedLocales), fallbackAppLocale);
    });
  });
}
