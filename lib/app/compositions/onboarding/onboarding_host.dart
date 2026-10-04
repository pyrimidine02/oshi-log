/// EN: First-run composition without requiring an account or new data contracts.
/// KO: 계정이나 새 데이터 계약 없이 제공하는 첫 실행 조합입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import 'package:oshi_log/features/identity/account/application/app_preferences.dart';
import 'package:oshi_log/features/identity/account/presentation/widgets/locale_theme_sheet.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/field_project_picker_sheet.dart';

export 'package:oshi_log/features/identity/account/application/app_preferences.dart'
    show firstRunCompletedProvider;
export 'package:oshi_log/features/identity/account/presentation/widgets/locale_theme_sheet.dart'
    show LocaleThemeSheet, showLocaleThemeSheet;

/// EN: Any dismissal means skipping unfinished choices, with local completion.
/// KO: 어떤 닫기 동작도 미완료 선택 건너뛰기로 처리하고 로컬 완료를 기록합니다.
Future<void> showFirstRunPreferencesSheet(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const FirstRunPreferencesSheet(),
  );
  try {
    final storage = await container.read(localStorageProvider.future);
    if (!await storage.setOnboardingCompleted(true)) {
      throw StateError('First-run completion could not be saved');
    }
    container.invalidate(firstRunCompletedProvider);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '첫 실행 설정을 저장하지 못했어요.',
            en: 'Could not save first-run preferences.',
            ja: '初回設定を保存できませんでした。',
          ),
        ),
      ),
    );
  }
}

class FirstRunPreferencesSheet extends ConsumerStatefulWidget {
  const FirstRunPreferencesSheet({super.key});

  @override
  ConsumerState<FirstRunPreferencesSheet> createState() =>
      _FirstRunPreferencesSheetState();
}

class _FirstRunPreferencesSheetState
    extends ConsumerState<FirstRunPreferencesSheet> {
  String? _selectedName;
  bool _selecting = false;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsControllerProvider);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(GBTSpacing.md),
                children: [
                  Text(
                    context.l10n(
                      ko: '나의 오시로그 시작하기',
                      en: 'Make Oshi Log yours',
                      ja: '自分のオシログをはじめよう',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Text(
                    context.l10n(
                      ko: '언어와 좋아하는 프로젝트를 골라 보세요. 나중에 언제든 바꿀 수 있어요.',
                      en: 'Choose your language and favorite project. You can change both later.',
                      ja: '言語と推しプロジェクトを選びましょう。あとからいつでも変更できます。',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.lg),
                  const LocalePreferenceOptions(),
                  const SizedBox(height: GBTSpacing.lg),
                  Text(
                    context.l10n(
                      ko: '좋아하는 프로젝트',
                      en: 'Favorite project',
                      ja: '推しプロジェクト',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  projects.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(GBTSpacing.md),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n(
                            ko: '프로젝트를 불러오지 못했어요. 나중에 선택해도 괜찮아요.',
                            en: 'Projects could not load. You can choose later.',
                            ja: 'プロジェクトを読み込めませんでした。あとから選べます。',
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(projectsControllerProvider.notifier)
                              .load(forceRefresh: true),
                          child: Text(
                            context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                          ),
                        ),
                      ],
                    ),
                    data: (items) => items.isEmpty
                        ? Text(
                            context.l10n(
                              ko: '프로젝트가 등록되면 선택할 수 있어요.',
                              en: 'Projects will appear when available.',
                              ja: 'プロジェクトが登録されると選べます。',
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _selecting
                                ? null
                                : () => _chooseProject(items),
                            icon: const Icon(Icons.favorite_border),
                            label: Text(
                              _selectedName ??
                                  context.l10n(
                                    ko: '프로젝트 선택',
                                    en: 'Choose a project',
                                    ja: 'プロジェクトを選ぶ',
                                  ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(GBTSpacing.md),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: GBTSpacing.sm,
                runSpacing: GBTSpacing.sm,
                children: [
                  TextButton(
                    key: const ValueKey('first-run-skip-all'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n(
                        ko: '모두 건너뛰기',
                        en: 'Skip all',
                        ja: 'すべてスキップ',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n(ko: '시작하기', en: 'Get started', ja: 'はじめる'),
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

  Future<void> _chooseProject(List<Project> projects) async {
    final selectedId = ref.read(selectedProjectIdProvider) ?? '';
    final selected = await showModalBottomSheet<Project>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FieldProjectPickerSheet(
        projects: projects,
        selectedId: selectedId,
        onConfirm: (project) => Navigator.of(sheetContext).pop(project),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _selecting = true);
    try {
      await ref
          .read(projectSelectionControllerProvider.notifier)
          .selectProject(
            selected.code.isNotEmpty ? selected.code : selected.id,
            projectId: selected.id,
          );
      if (mounted) setState(() => _selectedName = selected.name);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '프로젝트를 저장하지 못했어요.',
              en: 'Could not save the project.',
              ja: 'プロジェクトを保存できませんでした。',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }
}
