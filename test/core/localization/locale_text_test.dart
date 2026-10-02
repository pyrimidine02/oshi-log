import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/localization/locale_text.dart';

void main() {
  Future<String> l10nUnder(
    WidgetTester tester,
    Locale locale, {
    required String ko,
    String? en,
    String? ja,
  }) async {
    late String result;
    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            result = context.l10n(ko: ko, en: en, ja: ja);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  group('LocaleTextX.l10n fallback matrix', () {
    testWidgets('ja locale with all values present returns ja', (tester) async {
      final result = await l10nUnder(
        tester,
        const Locale('ja'),
        ko: '한국어',
        en: 'English',
        ja: '日本語',
      );
      expect(result, '日本語');
    });

    testWidgets('ja locale falls back to en when ja missing', (tester) async {
      final result = await l10nUnder(
        tester,
        const Locale('ja'),
        ko: '한국어',
        en: 'English',
      );
      expect(result, 'English');
    });

    testWidgets('ja locale falls back to ko when ja and en missing', (
      tester,
    ) async {
      final result = await l10nUnder(tester, const Locale('ja'), ko: '한국어');
      expect(result, '한국어');
    });

    testWidgets('ja locale treats empty ja string as missing', (tester) async {
      final result = await l10nUnder(
        tester,
        const Locale('ja'),
        ko: '한국어',
        en: 'English',
        ja: '',
      );
      expect(result, 'English');
    });

    testWidgets('ja locale treats empty ja and en strings as missing', (
      tester,
    ) async {
      final result = await l10nUnder(
        tester,
        const Locale('ja'),
        ko: '한국어',
        en: '',
        ja: '',
      );
      expect(result, '한국어');
    });

    testWidgets('en locale falls back to ko when en missing', (tester) async {
      final result = await l10nUnder(
        tester,
        const Locale('en'),
        ko: '한국어',
        ja: '日本語',
      );
      expect(result, '한국어');
    });

    testWidgets('en locale treats empty en string as missing', (tester) async {
      final result = await l10nUnder(
        tester,
        const Locale('en'),
        ko: '한국어',
        en: '',
      );
      expect(result, '한국어');
    });

    testWidgets('ko locale always returns ko', (tester) async {
      final result = await l10nUnder(
        tester,
        const Locale('ko'),
        ko: '한국어',
        en: 'English',
        ja: '日本語',
      );
      expect(result, '한국어');
    });
  });
}
