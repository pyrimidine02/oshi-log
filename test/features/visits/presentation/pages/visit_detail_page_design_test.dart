import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/visits/presentation/pages/visit_detail_page.dart';

void main() {
  testWidgets('visit record header survives 320dp and 200% text', (
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
              child: VisitDetailDocumentHeader(
                placeName:
                    'A very long pilgrimage destination in Shimokitazawa',
                visitedAt: '2026.07.15 19:30',
                verificationLabel: 'GPS verified within 12.5 meters',
                isVerified: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('visit-detail-document-header')),
      findsOneWidget,
    );
    expect(find.textContaining('pilgrimage destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
