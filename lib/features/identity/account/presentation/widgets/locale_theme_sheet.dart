/// EN: Guest-accessible language and theme preferences using existing storage.
/// KO: 기존 저장소를 사용하는 비회원 언어·테마 설정입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import '../../application/app_preferences.dart';

Future<void> showLocaleThemeSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const LocaleThemeSheet(),
    );

class LocaleThemeSheet extends ConsumerWidget {
  const LocaleThemeSheet({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '언어·테마',
                      en: 'Language & theme',
                      ja: '言語・テーマ',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
                  onPressed: onClose ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.md),
            const LocalePreferenceOptions(),
            const SizedBox(height: GBTSpacing.lg),
            Text(
              context.l10n(ko: '테마', en: 'Theme', ja: 'テーマ'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioGroup<String>(
              groupValue: mode,
              onChanged: (value) {
                if (value != null) {
                  _savePreference(
                    context,
                    () => ref.read(themeModeProvider.notifier).setMode(value),
                  );
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'system',
                    title: Text(
                      context.l10n(ko: '시스템 설정', en: 'System', ja: 'システム'),
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'light',
                    title: Text(
                      context.l10n(
                        ko: '라이트 모드',
                        en: 'Light mode',
                        ja: 'ライトモード',
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'dark',
                    title: Text(
                      context.l10n(ko: '다크 모드', en: 'Dark mode', ja: 'ダークモード'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: Shared language choices for first run and the preferences sheet.
/// KO: 첫 실행과 환경설정 시트가 공유하는 언어 선택입니다.
class LocalePreferenceOptions extends ConsumerWidget {
  const LocalePreferenceOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n(ko: '언어', en: 'Language', ja: '言語'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RadioGroup<String>(
          groupValue: locale?.languageCode ?? 'system',
          onChanged: (value) {
            if (value != null) {
              _savePreference(
                context,
                () => ref.read(localeProvider.notifier).setLocaleByCode(value),
              );
            }
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'system',
                title: Text(
                  context.l10n(ko: '시스템 설정', en: 'System', ja: 'システム'),
                ),
              ),
              const RadioListTile<String>(value: 'ja', title: Text('日本語')),
              const RadioListTile<String>(value: 'ko', title: Text('한국어')),
              const RadioListTile<String>(value: 'en', title: Text('English')),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _savePreference(
  BuildContext context,
  Future<void> Function() save,
) async {
  try {
    await save();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '설정을 저장하지 못했어요. 다시 선택해 주세요.',
            en: 'Could not save. Please select the option again.',
            ja: '設定を保存できませんでした。もう一度選択してください。',
          ),
        ),
      ),
    );
  }
}
