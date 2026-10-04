/// EN: Keeps the shell visible without building a protected data consumer.
/// KO: 보호된 데이터 소비자를 만들지 않고 쉘과 로그인 안내를 유지합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/localization/locale_text.dart';
import '../../design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/features/identity/auth/application/auth_action_gate.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

class ProtectedReadGate extends ConsumerWidget {
  const ProtectedReadGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isAuthenticatedProvider)) return child;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GBTSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40),
            const SizedBox(height: GBTSpacing.md),
            Text(
              context.l10n(
                ko: '로그인하면 볼 수 있어요',
                en: 'Log in to explore this section',
                ja: 'ログインすると利用できます',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GBTSpacing.md),
            FilledButton(
              onPressed: () => ref.read(authenticationGateProvider)(context),
              child: Text(context.l10n(ko: '로그인', en: 'Log in', ja: 'ログイン')),
            ),
          ],
        ),
      ),
    );
  }
}
