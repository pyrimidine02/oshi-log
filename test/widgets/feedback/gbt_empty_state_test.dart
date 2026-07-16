import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/widgets/feedback/gbt_empty_state.dart';

void main() {
  testWidgets('GBTEmptyState supports the canonical title and subtitle API', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GBTEmptyState(
          icon: Icons.map_outlined,
          title: '아직 저장한 장소가 없어요',
          subtitle: '마음에 드는 성지를 여정에 담아보세요.',
        ),
      ),
    );

    expect(find.text('아직 저장한 장소가 없어요'), findsOneWidget);
    expect(find.text('마음에 드는 성지를 여정에 담아보세요.'), findsOneWidget);
  });

  testWidgets('GBTEmptyState preserves the legacy message API', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GBTEmptyState(message: '등록된 일정이 없습니다.')),
    );

    expect(find.text('등록된 일정이 없습니다.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
