import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/admin_ops/domain/entities/admin_ops_entities.dart';
import 'package:oshi_log/features/admin_ops/presentation/pages/admin_ops_page.dart';

void main() {
  testWidgets('operations navigation stays scrollable with 48dp targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
          ),
          child: DefaultTabController(
            length: 4,
            child: Scaffold(body: AdminOpsSectionNavigation()),
          ),
        ),
      ),
    );

    expect(find.text('개요'), findsOneWidget);
    expect(find.text('미디어 삭제'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(
      tester.getSize(find.byType(AdminOpsSectionNavigation)).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary is a linear ledger at 320dp and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const summary = AdminDashboardSummary(
      openReports: 7,
      inReviewReports: 3,
      pendingAccessGrantRequests: 2,
      pendingVerificationAppeals: 1,
      pendingMediaDeletionRequests: 4,
      activeSanctions: 5,
      extraMetrics: <String, int>{'신규 가입자': 9},
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: AdminOpsSummaryLedger(summary: summary),
            ),
          ),
        ),
      ),
    );

    expect(find.text('운영 대기 원장'), findsOneWidget);
    expect(find.text('신규 신고'), findsOneWidget);
    expect(find.text('활성 제재'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter rail preserves 48dp tap targets at large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: AdminOpsFilterRail(
              labels: const ['전체', '접수됨', '검토 중', '조치 완료'],
              selectedIndex: selected,
              onSelected: (index) => selected = index,
            ),
          ),
        ),
      ),
    );

    final controls = find.byType(InkWell);
    expect(controls, findsNWidgets(4));
    for (final element in controls.evaluate()) {
      expect(
        tester.getSize(find.byWidget(element.widget)).height,
        greaterThanOrEqualTo(48),
      );
    }

    await tester.tap(find.text('검토 중'));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });
}
