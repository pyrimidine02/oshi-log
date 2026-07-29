import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/home/presentation/field_home/widgets/field_home_components.dart';

void main() {
  testWidgets('FieldSectionHeader keeps one clear localized heading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FieldSectionHeader(eyebrow: 'PILGRIMAGE', title: '프로젝트 성지'),
        ),
      ),
    );

    expect(find.text('프로젝트 성지'), findsOneWidget);
    expect(find.text('PILGRIMAGE'), findsNothing);
  });

  testWidgets('JourneyBriefCard keeps the next action clear at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JourneyBriefCard(
            key: const ValueKey('journey-brief'),
            markerLabel: 'D-5',
            eyebrow: '가장 가까운 일정',
            title: 'Girls Band Live in Tokyo',
            meta: '7월 20일 · 일 18:00',
            primaryActionLabel: '상세 보기',
            onPrimaryAction: () => tapped = true,
            secondaryActionLabel: '전체 일정',
            onSecondaryAction: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('D-5'), findsOneWidget);
    expect(find.text('가장 가까운 일정'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('journey-brief'))).height,
      lessThan(260),
    );
    await tester.tap(find.text('상세 보기'));
    expect(tapped, isTrue);
  });

  testWidgets('JourneyBriefCard supports 200 percent text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: JourneyBriefCard(
              markerLabel: 'D-12',
              eyebrow: '가장 가까운 일정',
              title: 'BanG Dream! 여름 라이브 투어 인 도쿄',
              meta: '7월 27일 · 일요일 18:00',
              primaryActionLabel: '상세 보기',
              onPrimaryAction: _noop,
              secondaryActionLabel: '전체 일정',
              onSecondaryAction: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('상세 보기'), findsOneWidget);
    expect(find.text('전체 일정'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FieldRouteRail renders route order without card nesting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FieldRouteRail(
            nodes: [
              FieldRouteNode(
                label: '시모키타자와',
                meta: '추천 성지',
                icon: Icons.place_outlined,
              ),
              FieldRouteNode(
                label: '라이브 이벤트',
                meta: '7월 20일',
                icon: Icons.music_note_outlined,
                isEmphasized: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('시모키타자와'), findsOneWidget);
    expect(find.text('라이브 이벤트'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('FieldPlaceFeature keeps the next route item above the fold', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FieldPlaceFeature(
            title: 'KINTEX',
            meta: '고양시 · 방문 4회',
            onTap: _noop,
          ),
        ),
      ),
    );

    expect(find.text('KINTEX'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FieldPlaceFeature)).height,
      lessThan(220),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
