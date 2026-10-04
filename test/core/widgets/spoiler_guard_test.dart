import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/design_system/widgets/common/spoiler_guard.dart';

void main() {
  testWidgets(
    'hidden body excluded from widgets and semantics; identity resets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      Widget page(String id) => MaterialApp(
        home: Scaffold(
          body: SpoilerGuard(
            contentId: id,
            child: const Text('Secret setlist'),
          ),
        ),
      );
      await tester.pumpWidget(page('event-1'));
      expect(find.text('Secret setlist'), findsNothing);
      expect(find.bySemanticsLabel('Secret setlist'), findsNothing);
      await tester.tap(find.text('Show spoilers'));
      await tester.pump();
      expect(find.text('Secret setlist'), findsOneWidget);
      await tester.tap(find.text('Hide spoilers'));
      await tester.pump();
      expect(find.bySemanticsLabel('Secret setlist'), findsNothing);
      await tester.tap(find.text('Show spoilers'));
      await tester.pump();
      await tester.pumpWidget(page('event-2'));
      expect(find.text('Secret setlist'), findsNothing);
      semantics.dispose();
    },
  );
}
