import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/places/presentation/pages/place_detail_page.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    double textScale = 1,
    bool useLongCopy = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 760),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PlaceDetailDocumentHeader(
                name: useLongCopy
                    ? 'Shimokitazawa LIVE HAUS with a long venue name'
                    : 'Shimokitazawa LIVE HAUS',
                address: useLongCopy
                    ? '2-6-5 Kitazawa, Setagaya City, Tokyo, Japan'
                    : '2-6-5 Kitazawa, Tokyo',
                visitLabel: '128 visits recorded',
                favoriteLabel: '42 travelers saved this place',
                favoriteTooltip: 'Add favorite',
                isFavorite: false,
                onFavorite: () {},
                directionsLabel: 'Directions',
                onDirections: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('uses a compact document header instead of a tall hero', (
    tester,
  ) async {
    await pumpHeader(tester);

    final header = find.byKey(const ValueKey('place-detail-document-header'));
    expect(header, findsOneWidget);
    expect(tester.getSize(header).height, lessThan(280));
    expect(find.textContaining('LIVE HAUS'), findsOneWidget);
  });

  testWidgets('keeps actions tappable and avoids overflow at 320dp and 200%', (
    tester,
  ) async {
    await pumpHeader(tester, textScale: 2, useLongCopy: true);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byTooltip('Add favorite')).shortestSide,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Directions')).height,
      greaterThanOrEqualTo(48),
    );
  });
}
