import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/layout/gbt_field_primitives.dart';
import 'package:oshi_log/features/home/presentation/field_home/widgets/field_home_components.dart';
import '../../../testing/tolerant_local_file_comparator.dart';

void main() {
  testWidgets('field home composition is legible in light mode', (
    tester,
  ) async {
    await _pumpShowcase(tester, theme: GBTTheme.light, width: 390);
    await expectLater(
      find.byKey(const ValueKey('field-home-visual-light')),
      matchesGoldenFile(_homeGoldenPath('field_home_light.png')),
    );
  });

  testWidgets('field home composition keeps the night field in dark mode', (
    tester,
  ) async {
    await _pumpShowcase(tester, theme: GBTTheme.dark, width: 390);
    await expectLater(
      find.byKey(const ValueKey('field-home-visual-dark')),
      matchesGoldenFile(_homeGoldenPath('field_home_dark.png')),
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
      matchesGoldenFile(_homeGoldenPath('field_home_compact.png')),
    );
  });
}

/// EN: Selects a baseline for the host renderer used by Flutter golden tests.
/// KO: Flutter 골든 테스트에서 실행 호스트 렌더러에 맞는 기준 이미지를 선택합니다.
String _homeGoldenPath(String fileName) {
  return Platform.isLinux ? 'goldens/linux/$fileName' : 'goldens/$fileName';
}

Future<void> _pumpShowcase(
  WidgetTester tester, {
  required ThemeData theme,
  required double width,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await loadAppFonts();
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
      locale: const Locale('ko'),
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
                    child: const _FieldHomeShowcase(),
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
  const _FieldHomeShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GBTFieldSectionHeader(title: '다음 여행'),
        const SizedBox(height: 16),
        JourneyBriefCard(
          markerLabel: 'D-5',
          eyebrow: '가장 가까운 일정',
          title: 'Girls Band Cry 라이브 인 도쿄',
          meta: '2026년 7월 20일 · 18:00',
          primaryActionLabel: '상세 보기',
          onPrimaryAction: _noop,
          secondaryActionLabel: '전체 일정',
          onSecondaryAction: _noop,
        ),
        const SizedBox(height: 28),
        GBTFieldSectionHeader(
          title: '이 프로젝트의 성지',
          actionLabel: '지도 열기',
          onAction: _noop,
        ),
        const SizedBox(height: 16),
        FieldPlaceFeature(
          title: '시모키타자와 SHELTER',
          meta: '도쿄 · 방문 4회',
          onTap: _noop,
        ),
        const SizedBox(height: 16),
        GBTFieldSectionHeader(title: '다가오는 공연'),
        FieldAgendaTile(
          dateLabel: 'JUL 20',
          title: 'Girls Band Cry 라이브',
          typeLabel: '이벤트',
          onTap: _noop,
        ),
        FieldAgendaTile(
          dateLabel: 'JUL 21',
          title: 'Girls Band Cry 앙코르 라이브',
          typeLabel: '이벤트',
          onTap: _noop,
        ),
        const SizedBox(height: 16),
        GBTFieldSectionHeader(title: '프로젝트 소식'),
        FieldDispatchRow(
          title: '공연장 주변의 다음 목적지',
          meta: '2026년 7월 15일',
          summary: '공연 전 들를 수 있는 시모키타자와의 성지를 소개합니다.',
          onTap: _noop,
        ),
      ],
    );
  }
}

void _noop() {}
