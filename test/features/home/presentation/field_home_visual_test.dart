import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/design_system/widgets/layout/gbt_field_primitives.dart';
import 'package:oshi_log/app/compositions/home/presentation/field_home/widgets/field_home_components.dart';
import '../../../testing/tolerant_local_file_comparator.dart';
import '../../../testing/platform_golden.dart';

void main() {
  testWidgets('field home composition is legible in light mode', (
    tester,
  ) async {
    await _pumpShowcase(tester, theme: GBTTheme.light, width: 390);
    await expectLater(
      find.byKey(const ValueKey('field-home-visual-light')),
      matchesGoldenFile('$platformGoldenDirectory/field_home_light.png'),
    );
  });

  testWidgets('field home composition keeps the night field in dark mode', (
    tester,
  ) async {
    await _pumpShowcase(tester, theme: GBTTheme.dark, width: 390);
    await expectLater(
      find.byKey(const ValueKey('field-home-visual-dark')),
      matchesGoldenFile('$platformGoldenDirectory/field_home_dark.png'),
    );
  });

  testWidgets('field home composition reflows on a compact viewport', (
    tester,
  ) async {
    await _pumpShowcase(
      tester,
      theme: GBTTheme.light,
      width: 320,
      textScaler: const TextScaler.linear(1.5),
    );
    expect(find.text('다음 여행'), findsOneWidget);
    expect(find.text('이 프로젝트의 성지'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('field-home-visual-compact')),
      matchesGoldenFile('$platformGoldenDirectory/field_home_compact.png'),
    );
  });

  group('localized home visual coverage', () {
    for (final brightness in Brightness.values) {
      final themeName = brightness.name;

      testWidgets('ja $themeName at default text size', (tester) async {
        await _pumpShowcase(
          tester,
          theme: brightness == Brightness.dark
              ? GBTTheme.darkFor('ja')
              : GBTTheme.lightFor('ja'),
          width: 390,
          locale: const Locale('ja'),
          useRepositoryFonts: true,
        );
        await expectLater(
          find.byKey(ValueKey('field-home-visual-$themeName')),
          matchesGoldenFile(
            '$platformGoldenDirectory/field_home_ja_$themeName.png',
          ),
        );
      });

      for (final language in ['ja', 'ko']) {
        testWidgets('$language $themeName at 320dp and 200%', (tester) async {
          var openedLastAction = false;
          await _pumpShowcase(
            tester,
            theme: brightness == Brightness.dark
                ? GBTTheme.darkFor(language)
                : GBTTheme.lightFor(language),
            width: 320,
            locale: Locale(language),
            textScaler: const TextScaler.linear(2),
            onDispatchTap: () => openedLastAction = true,
            useRepositoryFonts: true,
          );
          final boundary = find.byKey(
            const ValueKey('field-home-visual-compact'),
          );
          final name = 'field_home_${language}_${themeName}_compact_200';
          await expectLater(
            boundary,
            matchesGoldenFile('$platformGoldenDirectory/$name.png'),
          );

          final lastAction = find.byType(FieldDispatchRow);
          await tester.ensureVisible(lastAction);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            boundary,
            matchesGoldenFile('$platformGoldenDirectory/${name}_bottom.png'),
          );
          await tester.tap(lastAction);
          expect(openedLastAction, isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

Future<void> _pumpShowcase(
  WidgetTester tester, {
  required ThemeData theme,
  required double width,
  Locale locale = const Locale('ko'),
  TextScaler textScaler = TextScaler.noScaling,
  VoidCallback? onDispatchTap,
  bool useRepositoryFonts = false,
}) async {
  if (useRepositoryFonts) {
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
  } else {
    await loadAppFonts();
  }
  final testFile = Uri.file(
    '${Directory.current.path}/test/features/home/presentation/'
    'field_home_visual_test.dart',
  );
  final previousComparator = goldenFileComparator;
  goldenFileComparator = TolerantLocalFileComparator(
    testFile,
    precisionTolerance: 0.015,
  );
  addTearDown(() => goldenFileComparator = previousComparator);

  await tester.binding.setSurfaceSize(Size(width, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final key = width == 320
      ? const ValueKey('field-home-visual-compact')
      : theme.brightness == Brightness.dark
      ? const ValueKey('field-home-visual-dark')
      : const ValueKey('field-home-visual-light');
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      home: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler);
          return Scaffold(
            body: MediaQuery(
              data: mediaQuery,
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: _FieldHomeShowcase(onDispatchTap: onDispatchTap),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _FieldHomeShowcase extends StatelessWidget {
  const _FieldHomeShowcase({this.onDispatchTap});

  final VoidCallback? onDispatchTap;

  @override
  Widget build(BuildContext context) {
    final isJapanese = Localizations.localeOf(context).languageCode == 'ja';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GBTFieldSectionHeader(title: isJapanese ? '次の旅' : '다음 여행'),
        const SizedBox(height: 16),
        JourneyBriefCard(
          markerLabel: 'D-5',
          eyebrow: isJapanese ? '直近の予定' : '가장 가까운 일정',
          title: isJapanese
              ? 'Girls Band Cry ライブ・イン・東京'
              : 'Girls Band Cry 라이브 인 도쿄',
          meta: isJapanese ? '2026年7月20日 · 18:00' : '2026년 7월 20일 · 18:00',
          primaryActionLabel: isJapanese ? '詳細を見る' : '상세 보기',
          onPrimaryAction: _noop,
          secondaryActionLabel: isJapanese ? 'すべての予定' : '전체 일정',
          onSecondaryAction: _noop,
        ),
        const SizedBox(height: 28),
        GBTFieldSectionHeader(
          title: isJapanese ? 'このプロジェクトの聖地' : '이 프로젝트의 성지',
          actionLabel: isJapanese ? '地図を開く' : '지도 열기',
          onAction: _noop,
        ),
        const SizedBox(height: 16),
        FieldPlaceFeature(
          title: isJapanese ? '下北沢 SHELTER' : '시모키타자와 SHELTER',
          meta: isJapanese ? '東京 · 訪問4回' : '도쿄 · 방문 4회',
          onTap: _noop,
        ),
        const SizedBox(height: 16),
        GBTFieldSectionHeader(title: isJapanese ? '今後の公演' : '다가오는 공연'),
        FieldAgendaTile(
          dateLabel: 'JUL 20',
          title: isJapanese ? 'Girls Band Cry ライブ' : 'Girls Band Cry 라이브',
          typeLabel: isJapanese ? 'イベント' : '이벤트',
          onTap: _noop,
        ),
        FieldAgendaTile(
          dateLabel: 'JUL 21',
          title: isJapanese
              ? 'Girls Band Cry アンコールライブ'
              : 'Girls Band Cry 앙코르 라이브',
          typeLabel: isJapanese ? 'イベント' : '이벤트',
          onTap: _noop,
        ),
        const SizedBox(height: 16),
        GBTFieldSectionHeader(title: isJapanese ? 'プロジェクトのニュース' : '프로젝트 소식'),
        FieldDispatchRow(
          title: isJapanese ? '会場周辺の次の目的地' : '공연장 주변의 다음 목적지',
          meta: isJapanese ? '2026年7月15日' : '2026년 7월 15일',
          summary: isJapanese
              ? '公演前に立ち寄れる下北沢の聖地を紹介します。'
              : '공연 전 들를 수 있는 시모키타자와의 성지를 소개합니다.',
          onTap: onDispatchTap ?? _noop,
        ),
      ],
    );
  }
}

void _noop() {}
