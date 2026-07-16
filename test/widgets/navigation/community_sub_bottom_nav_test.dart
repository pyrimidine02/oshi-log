import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/shared/main_scaffold.dart';

void main() {
  testWidgets(
    'Android community navigation survives 320dp and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: CommunitySubBottomNav(
              section: CommunitySubSection.feed,
              onBackTap: () {},
              onSectionChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Travel Reviews'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
