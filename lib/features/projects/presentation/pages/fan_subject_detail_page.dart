/// EN: Generic detail page for every selectable fandom subject.
/// KO: 선택 가능한 모든 팬 대상을 위한 공통 상세 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/fan_subjects_controller.dart';
import '../../data/dto/fan_subject_dto.dart';
import '../../domain/entities/fan_subject.dart';

/// EN: Resolves project, band/unit, voice actor, artist, and anime subjects
/// through one stable route while specialized pages remain available.
/// KO: 전용 상세 화면은 유지하면서 프로젝트·밴드/유닛·성우·아티스트·
/// 애니메이션 대상을 하나의 안정적인 경로로 조회합니다.
class FanSubjectDetailPage extends ConsumerStatefulWidget {
  const FanSubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<FanSubjectDetailPage> createState() =>
      _FanSubjectDetailPageState();
}

class _FanSubjectDetailPageState extends ConsumerState<FanSubjectDetailPage> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(fanSubjectDetailProvider(widget.subjectId));

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '관심 대상', en: 'Fan subject', ja: '関心対象'),
      ),
      body: detailState.when(
        loading: () => GBTLoading(
          message: context.l10n(
            ko: '관심 대상 정보를 불러오는 중이에요',
            en: 'Loading subject details',
            ja: '関心対象の情報を読み込み中です',
          ),
        ),
        error: (error, _) => GBTEmptyState(
          icon: Icons.sync_problem_rounded,
          title: context.l10n(
            ko: '관심 대상을 불러오지 못했어요',
            en: 'Could not load this subject',
            ja: '関心対象を読み込めませんでした',
          ),
          subtitle: error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '잠시 후 다시 시도해 주세요.',
                  en: 'Please try again shortly.',
                  ja: 'しばらくしてからもう一度お試しください。',
                ),
          actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
          onAction: () =>
              ref.invalidate(fanSubjectDetailProvider(widget.subjectId)),
        ),
        data: _buildDetail,
      ),
    );
  }

  Widget _buildDetail(FanSubject subject) {
    final subscriptions = ref.watch(myFanSubjectsControllerProvider);
    final loadedSubscriptions = subscriptions.valueOrNull;
    final isSubscribed =
        loadedSubscriptions?.any(
          (item) => item.subject.id == subject.id && item.subscribed,
        ) ??
        false;
    final subscriptionError = fanSubjectSelectionFailure(subscriptions);
    final followLabel = isSubscribed
        ? context.l10n(ko: '관심 해제', en: 'Unfollow', ja: '関心を解除')
        : context.l10n(ko: '관심 등록', en: 'Follow', ja: '関心に追加');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(fanSubjectDetailProvider(widget.subjectId));
        await ref.read(myFanSubjectsControllerProvider.notifier).load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: GBTSpacing.bottomNavClearanceOf(context),
        ),
        children: [
          _FanSubjectHero(subject: subject),
          Padding(
            padding: EdgeInsets.fromLTRB(
              GBTResponsiveSpacing.pageHorizontal(context),
              GBTSpacing.lg,
              GBTResponsiveSpacing.pageHorizontal(context),
              GBTSpacing.sm,
            ),
            child: GBTButton(
              label: followLabel,
              icon: isSubscribed
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              variant: isSubscribed
                  ? GBTButtonVariant.secondary
                  : GBTButtonVariant.primary,
              isFullWidth: true,
              isLoading: _isUpdating || subscriptions.isLoading,
              semanticLabel: '${subject.name} $followLabel',
              semanticHint: context.l10n(
                ko: '탭하면 내 관심 대상을 변경합니다.',
                en: 'Double tap to update your followed subjects.',
                ja: 'タップして関心対象を更新します。',
              ),
              onPressed: loadedSubscriptions == null
                  ? null
                  : () => _setSubscribed(
                      subject: subject,
                      selected: !isSubscribed,
                    ),
            ),
          ),
          if (subscriptionError != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: GBTResponsiveSpacing.pageHorizontal(context),
              ),
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(myFanSubjectsControllerProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.l10n(
                    ko: '관심 상태 다시 불러오기',
                    en: 'Reload follow status',
                    ja: '関心状態を再読み込み',
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              GBTResponsiveSpacing.pageHorizontal(context),
              GBTSpacing.xl,
              GBTResponsiveSpacing.pageHorizontal(context),
              0,
            ),
            child: const _SubjectScopeNote(),
          ),
        ],
      ),
    );
  }

  Future<void> _setSubscribed({
    required FanSubject subject,
    required bool selected,
  }) async {
    setState(() => _isUpdating = true);
    final result = await ref
        .read(myFanSubjectsControllerProvider.notifier)
        .setSelected(subjectId: subject.id, selected: selected);
    if (!mounted) return;
    setState(() => _isUpdating = false);
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }
}

class _FanSubjectHero extends StatelessWidget {
  const _FanSubjectHero({required this.subject});

  final FanSubject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typeLabel = _subjectTypeLabel(context, subject.kind);
    final description = subject.description?.trim();

    return Semantics(
      container: true,
      header: true,
      label: [
        typeLabel,
        subject.name,
        if (description != null && description.isNotEmpty) description,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            GBTResponsiveSpacing.pageHorizontal(context),
            GBTSpacing.lg,
            GBTResponsiveSpacing.pageHorizontal(context),
            GBTSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.38),
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
            ),
          ),
          child: Column(
            children: [
              _SubjectArtwork(subject: subject),
              const SizedBox(height: GBTSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.md,
                    vertical: GBTSpacing.xs2,
                  ),
                  child: Text(
                    typeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                subject.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: GBTSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectArtwork extends StatelessWidget {
  const _SubjectArtwork({required this.subject});

  final FanSubject subject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = subject.imageUrl?.trim();
    const size = 136.0;
    final borderRadius = BorderRadius.circular(GBTSpacing.radiusXl);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return GBTImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: borderRadius,
        semanticLabel: '${subject.name} 이미지',
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Icon(
        _subjectTypeIcon(subject.kind),
        size: GBTSpacing.iconXl,
        color: colors.primary,
      ),
    );
  }
}

class _SubjectScopeNote extends StatelessWidget {
  const _SubjectScopeNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: context.l10n(
        ko:
            '관심 대상 안내. 프로젝트, 밴드와 유닛, 성우, 아티스트, '
            '애니메이션을 같은 방식으로 연결합니다.',
        en:
            'Projects, bands and units, voice actors, artists, and anime '
            'share one follow system.',
        ja:
            'プロジェクト・バンド／ユニット・声優・アーティスト・アニメを'
            '同じ仕組みでつなぎます。',
      ),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: GBTSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(ko: '관심 대상', en: 'FAN SUBJECT', ja: '関心対象'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko:
                        '프로젝트·밴드/유닛·성우·아티스트·애니메이션을 '
                        '같은 방식으로 연결해요.',
                    en:
                        'Projects, bands/units, voice actors, artists, and '
                        'anime share one follow system.',
                    ja:
                        'プロジェクト・バンド／ユニット・声優・アーティスト・'
                        'アニメを同じ仕組みでつなぎます。',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _subjectTypeLabel(BuildContext context, FanSubjectKind kind) {
  return switch (kind) {
    FanSubjectKind.project => context.l10n(
      ko: '프로젝트',
      en: 'Project',
      ja: 'プロジェクト',
    ),
    FanSubjectKind.unit => context.l10n(
      ko: '밴드/유닛',
      en: 'Band / unit',
      ja: 'バンド／ユニット',
    ),
    FanSubjectKind.voiceActor => context.l10n(
      ko: '성우',
      en: 'Voice actor',
      ja: '声優',
    ),
    FanSubjectKind.artist => context.l10n(
      ko: '아티스트',
      en: 'Artist',
      ja: 'アーティスト',
    ),
    FanSubjectKind.anime => context.l10n(ko: '애니메이션', en: 'Anime', ja: 'アニメ'),
    FanSubjectKind.unknown => context.l10n(
      ko: '관심 대상',
      en: 'Fan subject',
      ja: '関心対象',
    ),
  };
}

IconData _subjectTypeIcon(FanSubjectKind kind) {
  return switch (kind) {
    FanSubjectKind.project => Icons.auto_awesome_mosaic_rounded,
    FanSubjectKind.unit => Icons.groups_rounded,
    FanSubjectKind.voiceActor => Icons.record_voice_over_rounded,
    FanSubjectKind.artist => Icons.mic_external_on_rounded,
    FanSubjectKind.anime => Icons.movie_filter_rounded,
    FanSubjectKind.unknown => Icons.interests_rounded,
  };
}
