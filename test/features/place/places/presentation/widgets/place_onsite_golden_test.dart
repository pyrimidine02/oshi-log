import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/place_onsite_sections.dart';

import '../../../../../testing/tolerant_local_file_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final compact in [false, true]) {
        final name =
            'onsite_${locale}_${dark ? 'dark' : 'light'}_'
            '${compact ? '320_200' : '390_100'}';
        testWidgets(name, (tester) async {
          final original = goldenFileComparator;
          goldenFileComparator = TolerantLocalFileComparator(
            Uri.file(
              '${Directory.current.path}/test/features/place/places/'
              'presentation/widgets/place_onsite_golden_test.dart',
            ),
            precisionTolerance: 0.015,
          );
          addTearDown(() => goldenFileComparator = original);
          await tester.binding.setSurfaceSize(Size(compact ? 320 : 390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              supportedLocales: const [Locale('ja'), Locale('ko')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: dark
                  ? GBTTheme.darkFor(locale)
                  : GBTTheme.lightFor(locale),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: const ValueKey('onsite-golden'),
                child: PlacePresentationSheet(
                  place: PlaceDetail(
                    id: 'p',
                    name: '下北沢 LIVE HAUS',
                    address: '〒155-0031 東京都世田谷区北沢二丁目六番五号 地下一階',
                    types: const [],
                    savedAt: DateTime(2026, 10, 3, 18, 30),
                    isFromCache: true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('onsite-golden')),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}
