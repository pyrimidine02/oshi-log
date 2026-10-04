/// EN: Inline login keeps the original URI and releases a pending action once.
/// KO: 인라인 로그인은 원래 URI를 유지하고 대기 행동을 한 번 재개합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../platform/providers/core_providers.dart'
    show apiSessionGenerationProvider;
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/login_page.dart';
import '../../design_system/localization/locale_text.dart';
import 'pending_login_action.dart';

final pendingLoginActionProvider = Provider((ref) => PendingLoginAction());

Future<bool> showActionLoginSheet(BuildContext context, Ref ref) async {
  if (ref.read(isAuthenticatedProvider)) return true;
  final pending = ref.read(pendingLoginActionProvider);
  final ticket = pending.begin();
  if (ticket == null) return false;
  final router = GoRouter.of(context);
  final origin = router.state.uri;
  int? session;
  try {
    session = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .94,
        child: ActionLoginSheet(redirectTarget: origin.toString()),
      ),
    );
  } catch (_) {
    pending.cancel();
    rethrow;
  }
  if (!context.mounted || router.state.uri != origin) {
    pending.cancel();
    return false;
  }
  return pending.consume(
    ticket,
    successSession: session,
    currentSession: ref.read(apiSessionGenerationProvider)(),
    authenticated: ref.read(isAuthenticatedProvider),
  );
}

class ActionLoginSheet extends ConsumerStatefulWidget {
  const ActionLoginSheet({super.key, required this.redirectTarget});

  final String redirectTarget;

  @override
  ConsumerState<ActionLoginSheet> createState() => _ActionLoginSheetState();
}

class _ActionLoginSheetState extends ConsumerState<ActionLoginSheet> {
  bool _closed = false;

  void _complete() {
    if (_closed ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        !ref.read(isAuthenticatedProvider)) {
      return;
    }
    _closed = true;
    final session = ref.read(apiSessionGenerationProvider)();
    Navigator.of(context).pop(session);
  }

  void _cancel() {
    if (_closed || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<int>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _closed = true;
      },
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              onPressed: _cancel,
              icon: const Icon(Icons.close),
              tooltip: context.l10n(
                ko: '로그인 취소',
                en: 'Cancel login',
                ja: 'ログインをキャンセル',
              ),
            ),
          ),
          Expanded(
            child: LoginPage(
              onAuthenticated: _complete,
              onCancel: _cancel,
              redirectTarget: widget.redirectTarget,
            ),
          ),
        ],
      ),
    );
  }
}
