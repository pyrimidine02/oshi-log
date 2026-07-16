import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';

/// EN: Requests explicit consent before reactivating an inactive account.
/// KO: 비활성 계정을 다시 활성화하기 전 명시적 동의를 요청합니다.
Future<bool> showAccountRecoveryDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            context.l10n(
              ko: '계정을 복구할까요?',
              en: 'Restore this account?',
              ja: 'アカウントを復元しますか？',
            ),
          ),
          content: Text(
            context.l10n(
              ko: '이 계정은 현재 비활성 상태입니다. 복구하면 다시 로그인할 수 있습니다.',
              en: 'This account is inactive. Restoring it lets you sign in again.',
              ja: 'このアカウントは現在無効です。復元すると再びログインできます。',
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('account-recovery-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
            ),
            FilledButton(
              key: const ValueKey('account-recovery-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.l10n(
                  ko: '계정 복구',
                  en: 'Restore account',
                  ja: 'アカウントを復元',
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;
}
