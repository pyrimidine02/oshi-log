/// EN: Voice actor detail page with members/credits tabs.
/// KO: 담당 멤버/크레딧 탭이 있는 성우 상세 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_segmented_tab_bar.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';

class VoiceActorDetailPage extends ConsumerStatefulWidget {
  const VoiceActorDetailPage({
    super.key,
    required this.projectId,
    required this.voiceActorId,
    this.fallbackName,
  });

  final String projectId;
  final String voiceActorId;
  final String? fallbackName;

  @override
  ConsumerState<VoiceActorDetailPage> createState() =>
      _VoiceActorDetailPageState();
}

class _VoiceActorDetailPageState extends ConsumerState<VoiceActorDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookupArgs = (
      projectId: widget.projectId,
      voiceActorId: widget.voiceActorId,
    );
    final detailState = ref.watch(voiceActorDetailProvider(lookupArgs));
    final membersState = ref.watch(voiceActorMembersProvider(lookupArgs));
    final creditsState = ref.watch(voiceActorCreditsProvider(lookupArgs));
    final title =
        detailState.valueOrNull?.displayName ??
        widget.fallbackName ??
        context.l10n(ko: '성우', en: 'Voice actor', ja: '声優');

    return Scaffold(
      appBar: gbtStandardAppBar(context, title: title),
      body: detailState.when(
        loading: () => const Center(child: GBTLoading()),
        error: (error, _) => _ErrorView(
          message: error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '성우 정보를 불러오지 못했어요',
                  en: 'Failed to load voice actor',
                  ja: '声優情報を読み込めませんでした',
                ),
          onRetry: () {
            ref.invalidate(voiceActorDetailProvider(lookupArgs));
            ref.invalidate(voiceActorMembersProvider(lookupArgs));
            ref.invalidate(voiceActorCreditsProvider(lookupArgs));
          },
        ),
        data: (detail) {
          return Column(
            children: [
              VoiceActorProfileHeader(detail: detail),
              const SizedBox(height: GBTSpacing.sm),
              GBTSegmentedTabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(
                    text: context.l10n(
                      ko: '담당 캐릭터',
                      en: 'Members',
                      ja: '担当キャラ',
                    ),
                  ),
                  Tab(
                    text: context.l10n(ko: '크레딧', en: 'Credits', ja: 'クレジット'),
                  ),
                  Tab(
                    text: context.l10n(
                      ko: '활동·소개',
                      en: 'Profile & activities',
                      ja: '活動・紹介',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.sm),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MembersTab(
                      state: membersState,
                      projectId: widget.projectId,
                      voiceActorId: widget.voiceActorId,
                    ),
                    _CreditsTab(
                      state: creditsState,
                      projectId: widget.projectId,
                      voiceActorId: widget.voiceActorId,
                    ),
                    VoiceActorActivityTab(detail: detail),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class VoiceActorProfileHeader extends StatelessWidget {
  const VoiceActorProfileHeader({super.key, required this.detail});

  final VoiceActorDetail detail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            child:
                detail.profileImageUrl != null &&
                    detail.profileImageUrl!.isNotEmpty
                ? GBTImage(
                    imageUrl: detail.profileImageUrl!,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    semanticLabel: context.l10n(
                      ko: '성우 프로필 이미지',
                      en: 'Voice actor profile',
                      ja: '声優プロフィール画像',
                    ),
                  )
                : Container(
                    width: 76,
                    height: 76,
                    color: isDark
                        ? GBTColors.darkSurfaceVariant
                        : GBTColors.surfaceVariant,
                    child: const Icon(Icons.mic_rounded),
                  ),
          ),
          const SizedBox(width: GBTSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOICE CAST',
                  style: GBTTypography.labelSmall.copyWith(
                    color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  detail.displayName,
                  style: GBTTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail.stageName != null &&
                    detail.stageName!.isNotEmpty &&
                    detail.stageName != detail.displayName)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail.stageName!,
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ),
                if (detail.agency != null && detail.agency!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: GBTSpacing.xs),
                    child: Text(
                      detail.agency!,
                      style: GBTTypography.labelSmall.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ),
                if (detail.bio != null && detail.bio!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: GBTSpacing.xs),
                    child: Text(
                      detail.bio!.trim(),
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryColor,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Displays a voice actor's full biography and supplied HTTPS website.
/// KO: 성우의 전체 소개와 제공된 HTTPS 웹사이트를 표시합니다.
class VoiceActorActivityTab extends StatelessWidget {
  const VoiceActorActivityTab({super.key, required this.detail});

  final VoiceActorDetail detail;

  @override
  Widget build(BuildContext context) {
    final bio = _nonEmpty(detail.bio);
    final officialWebsite = _validatedOfficialWebsite(detail.officialWebsite);
    final hasProfile = bio != null || officialWebsite != null;

    if (!hasProfile) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xxl),
        children: [
          GBTEmptyState(
            icon: Icons.badge_outlined,
            title: context.l10n(
              ko: '소개 정보가 없습니다',
              en: 'No profile information',
              ja: '紹介情報がありません',
            ),
          ),
        ],
      );
    }

    return ListView(
      key: const ValueKey('voice-actor-activity-scroll'),
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
      ),
      children: [
        if (bio != null)
          _VoiceActorProfileSection(
            title: context.l10n(ko: '소개', en: 'About', ja: '紹介'),
            child: GBTLinkifiedText(
              bio,
              selectable: true,
              style: GBTTypography.bodyMedium.copyWith(height: 1.55),
            ),
          ),
        if (officialWebsite != null) ...[
          if (bio != null) const SizedBox(height: GBTSpacing.md),
          _VoiceActorProfileSection(
            title: context.l10n(
              ko: '공식 사이트',
              en: 'Official website',
              ja: '公式サイト',
            ),
            child: GBTLinkifiedText(
              officialWebsite.toString(),
              selectable: true,
              style: GBTTypography.bodyMedium.copyWith(height: 1.55),
            ),
          ),
        ],
      ],
    );
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Uri? _validatedOfficialWebsite(String? value) {
    final normalized = _nonEmpty(value);
    if (normalized == null) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return null;
    if (uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }
}

class _VoiceActorProfileSection extends StatelessWidget {
  const _VoiceActorProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        border: Border.all(
          color: isDark ? GBTColors.darkBorder : GBTColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GBTTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({
    required this.state,
    required this.projectId,
    required this.voiceActorId,
  });

  final AsyncValue<List<VoiceActorMemberSummary>> state;
  final String projectId;
  final String voiceActorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const Center(child: GBTLoading()),
      error: (error, _) => _ErrorView(
        message: error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '담당 캐릭터를 불러오지 못했어요',
                en: 'Failed to load members',
                ja: '担当キャラを読み込めませんでした',
              ),
        onRetry: () => ref.invalidate(
          voiceActorMembersProvider((
            projectId: projectId,
            voiceActorId: voiceActorId,
          )),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return GBTEmptyState(
            icon: Icons.person_search_outlined,
            title: context.l10n(
              ko: '담당 캐릭터 정보가 없습니다',
              en: 'No member credits',
              ja: '担当キャラ情報がありません',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 84,
            endIndent: GBTSpacing.pageHorizontal,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _InfoCard(
              title: item.characterName,
              subtitle:
                  '${item.unitName}${item.roleType?.trim().isNotEmpty == true ? ' · ${item.roleType}' : ''}',
              imageUrl: item.characterImageUrl,
              trailing: item.position,
            );
          },
        );
      },
    );
  }
}

class _CreditsTab extends ConsumerWidget {
  const _CreditsTab({
    required this.state,
    required this.projectId,
    required this.voiceActorId,
  });

  final AsyncValue<List<VoiceActorCreditSummary>> state;
  final String projectId;
  final String voiceActorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const Center(child: GBTLoading()),
      error: (error, _) => _ErrorView(
        message: error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '크레딧을 불러오지 못했어요',
                en: 'Failed to load credits',
                ja: 'クレジットを読み込めませんでした',
              ),
        onRetry: () => ref.invalidate(
          voiceActorCreditsProvider((
            projectId: projectId,
            voiceActorId: voiceActorId,
          )),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return GBTEmptyState(
            icon: Icons.featured_play_list_outlined,
            title: context.l10n(
              ko: '크레딧 정보가 없습니다',
              en: 'No credits',
              ja: 'クレジット情報がありません',
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 84,
            endIndent: GBTSpacing.pageHorizontal,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final subtitle = [
              item.projectName,
              item.unitName,
              item.roleType,
            ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');
            return _InfoCard(
              title: item.characterName,
              subtitle: subtitle,
              imageUrl: item.characterImageUrl,
              trailing: item.position,
              notes: item.notes,
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.trailing,
    this.notes,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? trailing;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.sm2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? GBTImage(
                    imageUrl: imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: isDark
                        ? GBTColors.darkSurfaceVariant
                        : GBTColors.surfaceVariant,
                    child: const Icon(Icons.person_outline_rounded, size: 20),
                  ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GBTTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GBTTypography.labelSmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                ),
                if (notes != null && notes!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notes!.trim(),
                      style: GBTTypography.labelSmall.copyWith(
                        color: isDark
                            ? GBTColors.darkTextTertiary
                            : GBTColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null && trailing!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: GBTSpacing.xs),
              child: Text(
                trailing!,
                style: GBTTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GBTEmptyState(
      icon: Icons.cloud_off_outlined,
      title: message,
      actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
      onAction: onRetry,
    );
  }
}
