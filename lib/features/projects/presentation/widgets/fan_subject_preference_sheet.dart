/// EN: Unified interest picker for fandom people, groups, and media.
/// KO: 팬덤의 인물·그룹·미디어를 하나의 관심 대상 선택기에서 다룹니다.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/inputs/gbt_search_bar.dart';
import '../../application/fan_subjects_controller.dart';
import '../../data/dto/fan_subject_dto.dart';
import '../../domain/entities/fan_subject.dart';

const _mobileFanSubjectKinds = <FanSubjectKind>{
  FanSubjectKind.project,
  FanSubjectKind.unit,
  FanSubjectKind.voiceActor,
};

/// EN: Opens interests without changing the primary project travel context.
/// KO: Primary travel context remains a project while interests can be broader.
Future<void> showFanSubjectPreferenceSheet({
  required BuildContext context,
  required String projectId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
    builder: (_) => FanSubjectPreferenceSheet(projectId: projectId),
  );
}

class FanSubjectPreferenceSheet extends ConsumerStatefulWidget {
  const FanSubjectPreferenceSheet({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<FanSubjectPreferenceSheet> createState() =>
      _FanSubjectPreferenceSheetState();
}

class _FanSubjectPreferenceSheetState
    extends ConsumerState<FanSubjectPreferenceSheet> {
  final _searchController = TextEditingController();
  final _pendingIds = <String>{};
  Timer? _searchDebounce;
  FanSubjectKind? _kind;
  String? _query;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authenticated = ref.watch(isAuthenticatedProvider);
    final subjects = ref.watch(
      fanSubjectsProvider(
        FanSubjectQuery(
          kind: _kind,
          projectId: widget.projectId,
          query: _query,
          size: 100,
        ),
      ),
    );
    final subscriptions = authenticated
        ? ref.watch(myFanSubjectsControllerProvider)
        : const AsyncValue<List<FanSubjectSubscription>>.data([]);
    final selectedIds =
        subscriptions.valueOrNull
            ?.where((item) => item.subscribed)
            .map((item) => item.subject.id)
            .toSet() ??
        const <String>{};

    return FractionallySizedBox(
      heightFactor: 0.9,
      alignment: Alignment.bottomCenter,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusXl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const _SheetHandle(),
            const _SubjectHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.lg,
                0,
                GBTSpacing.lg,
                GBTSpacing.sm,
              ),
              child: GBTSearchBar(
                controller: _searchController,
                hint: context.l10n(
                  ko: '\uD504\uB85C\uC81D\uD2B8\u00B7\uBC34\uB4DC\u00B7\uC131\uC6B0 \uAC80\uC0C9',
                  en: 'Search projects, bands, or voice actors',
                  ja: '\u4F5C\u54C1\u30FB\u30D0\u30F3\u30C9\u30FB\u58F0\u512A\u3092\u691C\u7D22',
                ),
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
            ),
            _KindRail(selected: _kind, onSelected: _selectKind),
            if (!authenticated) const _SignInNotice(),
            Divider(height: 1, color: colors.outlineVariant),
            Expanded(
              child: subjects.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, __) => _LoadFailure(
                  onRetry: () => ref.invalidate(fanSubjectsProvider),
                ),
                data: (items) {
                  final visibleItems = items
                      .where(
                        (item) => _mobileFanSubjectKinds.contains(item.kind),
                      )
                      .toList(growable: false);
                  return visibleItems.isEmpty
                      ? const _EmptySubjects()
                      : RefreshIndicator.adaptive(
                          onRefresh: () async {
                            ref.invalidate(fanSubjectsProvider);
                            if (authenticated) {
                              await ref
                                  .read(
                                    myFanSubjectsControllerProvider.notifier,
                                  )
                                  .load();
                            }
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              GBTSpacing.lg,
                              GBTSpacing.sm,
                              GBTSpacing.lg,
                              GBTSpacing.xxl,
                            ),
                            itemCount: visibleItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: GBTSpacing.xs),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
                              final selected = selectedIds.contains(item.id);
                              return _SubjectRow(
                                subject: item,
                                selected: selected,
                                pending: _pendingIds.contains(item.id),
                                enabled: authenticated,
                                onTap: () => _toggleSubject(item, selected),
                              );
                            },
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final normalized = value.trim();
      setState(() => _query = normalized.isEmpty ? null : normalized);
    });
  }

  void _selectKind(FanSubjectKind? kind) {
    if (_kind == kind) return;
    setState(() => _kind = kind);
  }

  Future<void> _toggleSubject(FanSubject subject, bool selected) async {
    if (!ref.read(isAuthenticatedProvider) ||
        _pendingIds.contains(subject.id)) {
      return;
    }
    setState(() => _pendingIds.add(subject.id));
    final result = await ref
        .read(myFanSubjectsControllerProvider.notifier)
        .setSelected(subjectId: subject.id, selected: !selected);
    if (!mounted) return;
    setState(() => _pendingIds.remove(subject.id));
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.sm),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.lg,
        GBTSpacing.sm,
        GBTSpacing.sm,
        GBTSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(
                    ko: '\uB0B4 \uAD00\uC2EC \uB300\uC0C1',
                    en: 'MY FAN SUBJECTS',
                    ja: '\u30DE\u30A4\u30D5\u30A1\u30F3\u5BFE\u8C61',
                  ),
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '\uC88B\uC544\uD558\uB294 \uC138\uACC4\uB97C \uB354 \uAC00\uAE5D\uAC8C',
                    en: 'Keep every fandom close',
                    ja: '\u597D\u304D\u306A\u4E16\u754C\u3092\u3082\u3063\u3068\u8FD1\u304F\u306B',
                  ),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '\uD504\uB85C\uC81D\uD2B8\u00B7\uBC34\uB4DC\u00B7\uC131\uC6B0\uB97C \uB9DE\uCDA4 \uC77C\uC815\uACFC \uCD94\uCC9C\uC758 \uAE30\uC900\uC73C\uB85C \uC800\uC7A5\uD569\uB2C8\uB2E4.',
                    en: 'Follow projects, bands, and voice actors for tailored schedules and recommendations.',
                    ja: '\u4F5C\u54C1\u30FB\u30D0\u30F3\u30C9\u30FB\u58F0\u512A\u3092\u30D5\u30A9\u30ED\u30FC\u3067\u304D\u307E\u3059\u3002',
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n(
              ko: '\uB2EB\uAE30',
              en: 'Close',
              ja: '\u9589\u3058\u308B',
            ),
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _KindRail extends StatelessWidget {
  const _KindRail({required this.selected, required this.onSelected});

  final FanSubjectKind? selected;
  final ValueChanged<FanSubjectKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <(FanSubjectKind?, String)>[
      (
        null,
        context.l10n(ko: '\uC804\uCCB4', en: 'All', ja: '\u3059\u3079\u3066'),
      ),
      (
        FanSubjectKind.project,
        context.l10n(
          ko: '\uD504\uB85C\uC81D\uD2B8',
          en: 'Projects',
          ja: '\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8',
        ),
      ),
      (
        FanSubjectKind.unit,
        context.l10n(
          ko: '\uBC34\uB4DC\u00B7\uC720\uB2DB',
          en: 'Bands',
          ja: '\u30D0\u30F3\u30C9',
        ),
      ),
      (
        FanSubjectKind.voiceActor,
        context.l10n(
          ko: '\uC131\uC6B0',
          en: 'Voice actors',
          ja: '\u58F0\u512A',
        ),
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.lg,
        0,
        GBTSpacing.lg,
        GBTSpacing.sm,
      ),
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              key: ValueKey('fan-subject-kind-${option.$1?.wireName ?? 'ALL'}'),
              avatar: option.$1 == null
                  ? null
                  : Icon(_kindIcon(option.$1!), size: 16),
              label: Text(option.$2),
              selected: selected == option.$1,
              onSelected: (_) => onSelected(option.$1),
            ),
            const SizedBox(width: GBTSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.selected,
    required this.pending,
    required this.enabled,
    required this.onTap,
  });

  final FanSubject subject;
  final bool selected;
  final bool pending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = subject.imageUrl;
    final circular =
        subject.kind == FanSubjectKind.voiceActor ||
        subject.kind == FanSubjectKind.artist;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled && !pending,
      label: subject.name,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled && !pending ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.sm,
                vertical: GBTSpacing.xs,
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          circular
                              ? GBTSpacing.radiusFull
                              : GBTSpacing.radiusSm,
                        ),
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? Icon(_kindIcon(subject.kind), color: colors.primary)
                          : GBTImage(
                              imageUrl: imageUrl,
                              width: 44,
                              height: 44,
                              borderRadius: BorderRadius.circular(
                                circular
                                    ? GBTSpacing.radiusFull
                                    : GBTSpacing.radiusSm,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _kindLabel(context, subject.kind),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  if (pending)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInNotice extends StatelessWidget {
  const _SignInNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        GBTSpacing.lg,
        0,
        GBTSpacing.lg,
        GBTSpacing.sm,
      ),
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Text(
        context.l10n(
          ko: '\uB85C\uADF8\uC778\uD558\uBA74 \uAD00\uC2EC \uB300\uC0C1\uC744 \uC800\uC7A5\uD558\uACE0 \uB9DE\uCDA4 \uC77C\uC815\uC744 \uBC1B\uC744 \uC218 \uC788\uC5B4\uC694.',
          en: 'Sign in to save interests and receive tailored schedules.',
          ja: '\u30ED\u30B0\u30A4\u30F3\u3059\u308B\u3068\u5BFE\u8C61\u3092\u4FDD\u5B58\u3057\u3066\u4E88\u5B9A\u3092\u53D7\u3051\u53D6\u308C\u307E\u3059\u3002',
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onPrimaryContainer,
          height: 1.4,
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onRetry,
        child: Text(
          context.l10n(
            ko: '\uAD00\uC2EC \uB300\uC0C1 \uB2E4\uC2DC \uBD88\uB7EC\uC624\uAE30',
            en: 'Retry loading interests',
            ja: '\u5BFE\u8C61\u3092\u518D\u8AAD\u307F\u8FBC\u307F',
          ),
        ),
      ),
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n(
          ko: '\uC870\uAC74\uC5D0 \uB9DE\uB294 \uAD00\uC2EC \uB300\uC0C1\uC774 \uC5C6\uC5B4\uC694',
          en: 'No matching interests',
          ja: '\u6761\u4EF6\u306B\u5408\u3046\u5BFE\u8C61\u304C\u3042\u308A\u307E\u305B\u3093',
        ),
      ),
    );
  }
}

IconData _kindIcon(FanSubjectKind kind) => switch (kind) {
  FanSubjectKind.project => Icons.public_rounded,
  FanSubjectKind.unit => Icons.groups_rounded,
  FanSubjectKind.voiceActor => Icons.record_voice_over_rounded,
  FanSubjectKind.artist => Icons.mic_rounded,
  FanSubjectKind.anime => Icons.movie_filter_rounded,
  FanSubjectKind.unknown => Icons.interests_rounded,
};

String _kindLabel(BuildContext context, FanSubjectKind kind) => switch (kind) {
  FanSubjectKind.project => context.l10n(
    ko: '\uD504\uB85C\uC81D\uD2B8',
    en: 'Project',
    ja: '\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8',
  ),
  FanSubjectKind.unit => context.l10n(
    ko: '\uBC34\uB4DC\u00B7\uC720\uB2DB',
    en: 'Band / unit',
    ja: '\u30D0\u30F3\u30C9\u30FB\u30E6\u30CB\u30C3\u30C8',
  ),
  FanSubjectKind.voiceActor => context.l10n(
    ko: '\uAC1C\uC778 \uC131\uC6B0',
    en: 'Voice actor',
    ja: '\u500B\u4EBA\u58F0\u512A',
  ),
  FanSubjectKind.artist => context.l10n(
    ko: '\uC544\uD2F0\uC2A4\uD2B8',
    en: 'Artist',
    ja: '\u30A2\u30FC\u30C6\u30A3\u30B9\u30C8',
  ),
  FanSubjectKind.anime => context.l10n(
    ko: '\uC560\uB2C8\uBA54\uC774\uC158',
    en: 'Anime',
    ja: '\u30A2\u30CB\u30E1',
  ),
  FanSubjectKind.unknown => context.l10n(
    ko: '\uAD00\uC2EC \uB300\uC0C1',
    en: 'Fan subject',
    ja: '\u30D5\u30A1\u30F3\u5BFE\u8C61',
  ),
};
