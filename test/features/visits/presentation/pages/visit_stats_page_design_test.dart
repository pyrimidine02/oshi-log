import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/visits/presentation/pages/visit_stats_page.dart';

void main() {
  testWidgets('stats ledger is linear and overflow-safe at 320dp and 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: VisitStatsDocumentSummary(
                totalVisits: '128 visits',
                uniquePlaces: '42 pilgrimage locations',
                firstVisit: '2024.01.01',
                latestVisit: '2026.07.15',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('visit-stats-document-summary')),
      findsOneWidget,
    );
    expect(find.byType(GridView), findsNothing);
    expect(find.text('128 visits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
