import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/identity/social/application/user_follow_list_controller.dart';
import 'package:oshi_log/features/identity/social/domain/entities/social_entities.dart';
import 'package:oshi_log/features/identity/social/presentation/pages/user_connections_page.dart';

void main() {
  testWidgets('connection row remains readable without a duplicate view CTA', (
    tester,
  ) async {
    await _pumpCompact(
      tester,
      UserConnectionRow(
        item: UserFollowSummary(
          userId: 'user-1',
          displayName: '순례자',
          followedAt: DateTime.utc(2026, 7, 15),
          bio: '라이브와 성지를 따라 여행합니다.',
        ),
        onTap: () {},
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('순례자'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connections page keeps app bar concise for long display names', (
    tester,
  ) async {
    const displayName = '도쿄와 카와사키 라이브 하우스를 기록하는 긴 이름의 순례자';

    await _pumpPage(
      tester,
      ProviderScope(
        overrides: [
          userFollowersProvider.overrideWith((ref, userId) async => const []),
          userFollowingProvider.overrideWith((ref, userId) async => const []),
        ],
        child: const UserConnectionsPage(
          userId: 'user-1',
          displayName: displayName,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('연결'), findsOneWidget);
    expect(find.text('$displayName 연결'), findsNothing);
    expect(find.textContaining(displayName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: GBTTheme.light,
      home: child,
    ),
  );
}

Future<void> _pumpCompact(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 568),
        textScaler: TextScaler.linear(2),
      ),
      child: MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}
