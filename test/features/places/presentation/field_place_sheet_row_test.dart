import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/places/presentation/widgets/field_place_sheet_row.dart';

void main() {
  testWidgets('renders a borderless place row at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FieldPlaceSheetRow(
            name: 'Shimokitazawa Live House with a long venue name',
            address: 'Tokyo, Setagaya',
            distanceLabel: '2.4km',
            typeLabel: 'Live venue',
            isVisited: true,
            onTap: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsNothing);
    expect(find.text('2.4km'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.textContaining('Shimokitazawa'));
    expect(opened, isTrue);
  });

  testWidgets('directions remains an independent 48dp action', (tester) async {
    var opened = false;
    var directions = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldPlaceSheetRow(
            name: 'Venue',
            address: 'Tokyo',
            onTap: () => opened = true,
            onDirections: () => directions = true,
          ),
        ),
      ),
    );

    final button = find.byKey(const Key('field-place-directions'));
    expect(tester.getSize(button), const Size(48, 48));
    await tester.tap(button);
    expect(directions, isTrue);
    expect(opened, isFalse);
  });
}
