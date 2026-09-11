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
    expect(find.text('다음 원정'), findsOneWidget);
    expect(find.text('지도에서 이어지는 장소'), findsOneWidget);
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
        GBTFieldSectionHeader(
          eyebrow: 'NEXT STOP',
          title: '오늘의 원정 기록',
          actionLabel: '전체 보기',
          onAction: _noop,
        ),
        const SizedBox(height: 16),
        JourneyBriefCard(
          markerLabel: 'D-5',
          eyebrow: '다음 원정',
          title: 'Girls Band Cry 라이브 인 도쿄',
          meta: '2026년 7월 20일 · 18:00',
          primaryActionLabel: '상세 보기',
          onPrimaryAction: _noop,
          secondaryActionLabel: '지도 열기',
          onSecondaryAction: _noop,
        ),
        const SizedBox(height: 28),
        GBTFieldSectionHeader(
          eyebrow: 'PILGRIMAGE',
          title: '지도에서 이어지는 장소',
          actionLabel: '지도 보기',
          onAction: _noop,
        ),
        const SizedBox(height: 16),
        FieldPlaceFeature(
          title: '시모키타자와 SHELTER',
          meta: '도쿄 · 방문 4회',
          onTap: _noop,
        ),
        FieldRouteRail(
          nodes: [
            FieldRouteNode(
              label: '시모키타자와역',
              meta: '도보 8분 · 이동 시작',
              icon: Icons.train_outlined,
            ),
            FieldRouteNode(
              label: '오늘의 라이브',
              meta: '18:00 · 방문 예정',
              icon: Icons.music_note_outlined,
              isEmphasized: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GBTFieldSectionHeader(eyebrow: 'LIVE AGENDA', title: '기록할 다음 장면'),
        FieldAgendaTile(
          dateLabel: 'JUL 20',
          title: 'Girls Band Cry 라이브',
          typeLabel: '이벤트',
          onTap: _noop,
        ),
        FieldAgendaTile(
          dateLabel: 'JUL 21',
          title: '시모키타자와 성지 산책',
          typeLabel: '장소',
          onTap: _noop,
        ),
        const SizedBox(height: 16),
        GBTFieldSectionHeader(eyebrow: 'FIELD DISPATCH', title: '현장에서 남긴 소식'),
        FieldDispatchRow(
          title: '공연장 주변의 다음 목적지',
          meta: 'TRAVEL NOTE · 2시간 전',
          summary: '지도에 저장한 장소를 나만의 원정 기록으로 이어보세요.',
          onTap: _noop,
        ),
      ],
    );
  }
}

void _noop() {}
