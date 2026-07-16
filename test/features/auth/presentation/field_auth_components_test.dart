import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/auth/presentation/widgets/field_auth_components.dart';
import 'package:girlsbandtabi_app/features/auth/presentation/widgets/account_recovery_dialog.dart';

void main() {
  testWidgets('uses a solid blue field-note account header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const Scaffold(
          body: FieldAuthHeader(
            eyebrow: 'TRAVEL ACCOUNT',
            title: 'Continue your journey',
            subtitle: 'Sign in to keep places and schedules together.',
          ),
        ),
      ),
    );

    expect(find.text('TRAVEL ACCOUNT'), findsOneWidget);
    expect(find.text('Continue your journey'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byKey(const ValueKey('field-auth-mark')), findsOneWidget);
  });

  testWidgets('account header reflows at 320dp and 200 percent text', (
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
          child: Scaffold(
            body: SingleChildScrollView(
              child: FieldAuthHeader(
                eyebrow: 'TRAVEL ACCOUNT',
                title: 'Continue your pilgrimage journey',
                subtitle:
                    'Sign in to keep saved places, live schedules, and travel records together.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('field-auth-mark')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inactive account recovery requires explicit confirmation', (
    tester,
  ) async {
    bool? decision;
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              decision = await showAccountRecoveryDialog(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-recovery-confirm')), findsOne);

    await tester.tap(find.byKey(const ValueKey('account-recovery-confirm')));
    await tester.pumpAndSettle();
    expect(decision, isTrue);
  });
}
