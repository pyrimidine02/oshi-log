import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/auth_controller.dart';
import 'package:oshi_log/features/identity/auth/presentation/widgets/oauth_buttons.dart';

class _BusyAuth extends StateNotifier<AsyncValue<void>>
    implements AuthController {
  _BusyAuth() : super(const AsyncLoading());
  int googleCalls = 0;

  void finishPassword() => state = const AsyncData(null);

  @override
  Future<Result<void>> loginWithGoogle() async {
    googleCalls++;
    return const Result.failure(
      AuthFailure('cancelled', code: 'sign_in_cancelled'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('social login waits for the active password operation', (
    tester,
  ) async {
    final controller = _BusyAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: Scaffold(body: OAuthButtonsSection())),
      ),
    );
    final google = find.byWidgetPredicate(
      (widget) => widget is Text && widget.data!.contains('Google'),
    );
    await tester.tap(google);
    await tester.pump();
    expect(controller.googleCalls, 0);
    controller.finishPassword();
    await tester.pump();
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(controller.googleCalls, 1);
  });
}
