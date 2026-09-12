/// EN: User followers/following page with dense community-style list UX.
/// KO: 커뮤니티형 밀도 리스트 UX를 적용한 사용자 팔로워/팔로잉 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/inputs/gbt_search_bar.dart';
import '../../../../core/widgets/navigation/gbt_segmented_tab_bar.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/user_follow_list_controller.dart';
import '../../domain/entities/community_moderation.dart';

enum UserConnectionsTab { followers, following }

class UserConnectionsPage extends ConsumerStatefulWidget {
  const UserConnectionsPage({
    super.key,
    required this.userId,
    this.initialTab = UserConnectionsTab.followers,
    this.displayName,
  });

  final String userId;
  final UserConnectionsTab initialTab;
  final String? displayName;

  @override
  ConsumerState<UserConnectionsPage> createState() =>
      _UserConnectionsPageState();
}

class _UserConnectionsPageState extends ConsumerState<UserConnectionsPage> {
  String _followersQuery = '';
  String _followingQuery = '';

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName?.trim();
    final ownerName = displayName == null || displayName.isEmpty
        ? null
        : displayName;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab == UserConnectionsTab.followers ? 0 : 1,
      child: Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '연결', en: 'Connections', ja: 'つながり'),
        ),
        body: Column(
          children: [
            const SizedBox(height: GBTSpacing.sm),
            if (ownerName != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.pageHorizontal,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n(
                      ko: '$ownerName님의 연결',
                      en: '$ownerName\'s connections',
                      ja: '$ownerNameのつながり',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GBTTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
            ],
            GBTSegmentedTabBar(
              tabs: [
                Tab(
                  text: context.l10n(ko: '팔로워', en: 'Followers', ja: 'フォロワー'),
                ),
                Tab(
                  text: context.l10n(ko: '팔로잉', en: 'Following', ja: 'フォロー中'),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.sm),
            Expanded(
              child: TabBarView(
                children: [
                  _ConnectionsTabBody(
                    userId: widget.userId,
                    isFollowersTab: true,
                    query: _followersQuery,
                    onQueryChanged: (value) {
                      setState(() {
                        _followersQuery = value;
                      });
                    },
                    emptyMessage: context.l10n(
                      ko: '아직 팔로워가 없습니다',
                      en: 'No followers yet',
                      ja: 'まだフォロワーがいません',
                    ),
                  ),
                  _ConnectionsTabBody(
                    userId: widget.userId,
                    isFollowersTab: false,
                    query: _followingQuery,
                    onQueryChanged: (value) {
                      setState(() {
                        _followingQuery = value;
                      });
                    },
                    emptyMessage: context.l10n(
                      ko: '아직 팔로우한 사용자가 없습니다',
                      en: 'No followed users yet',
                      ja: 'まだフォローしたユーザーがいません',
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

class _ConnectionsTabBody extends ConsumerWidget {
  const _ConnectionsTabBody({
    required this.userId,
    required this.isFollowersTab,
    required this.query,
    required this.onQueryChanged,
    required this.emptyMessage,
  });

  final String userId;
  final bool isFollowersTab;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = isFollowersTab
        ? userFollowersProvider(userId)
        : userFollowingProvider(userId);
    final state = ref.watch(provider);
    return Column(
      children: [
        Padding(
          padding: GBTSpacing.paddingPage,
          child: GBTSearchBar(
            hint: context.l10n(
              ko: '닉네임 또는 소개 검색',
              en: 'Search nickname or bio',
              ja: 'ニックネームまたは紹介を検索',
            ),
            onChanged: onQueryChanged,
            onClear: () => onQueryChanged(''),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => GBTLoading(
              message: context.l10n(
                ko: '목록을 불러오는 중...',
                en: 'Loading list...',
                ja: '一覧を読み込み中...',
              ),
            ),
            error: (error, _) {
              final message = error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '목록을 불러오지 못했습니다',
                      en: 'Failed to load list',
                      ja: '一覧を読み込めませんでした',
                    );
              return GBTErrorState(
                message: message,
                onRetry: () => ref.invalidate(provider),
              );
            },
            data: (items) {
              final filtered = _filter(items, query);
              if (filtered.isEmpty) {
                return GBTEmptyState(
                  icon: query.isEmpty
                      ? Icons.people_outline
                      : Icons.search_off_rounded,
                  title: query.isEmpty
                      ? emptyMessage
                      : context.l10n(
                          ko: '검색 결과가 없습니다',
                          en: 'No search results',
                          ja: '検索結果がありません',
                        ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(provider);
                  await ref.read(provider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return UserConnectionRow(
                      item: item,
                      onTap: () => context.goToUserProfile(item.userId),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 74,
                    endIndent: GBTSpacing.pageHorizontal,
                  ),
                  itemCount: filtered.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<UserFollowSummary> _filter(
    List<UserFollowSummary> items,
    String rawQuery,
  ) {
    final queryLower = rawQuery.trim().toLowerCase();
    if (queryLower.isEmpty) {
      return items;
    }
    return items.where((item) {
      final name = item.displayName.toLowerCase();
      final bio = (item.bio ?? '').toLowerCase();
      return name.contains(queryLower) || bio.contains(queryLower);
    }).toList();
  }
}

/// EN: Borderless connection row with one clear navigation target.
/// KO: 하나의 명확한 이동 대상만 제공하는 보더리스 연결 행입니다.
class UserConnectionRow extends StatelessWidget {
  const UserConnectionRow({super.key, required this.item, required this.onTap});

  final UserFollowSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final joinedLabel = DateFormat(
      'yyyy.MM.dd',
    ).format(item.followedAt.toLocal());

    return Semantics(
      button: true,
      label: '${item.displayName}, $joinedLabel',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
            vertical: GBTSpacing.sm2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConnectionAvatar(url: item.avatarUrl),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: GBTTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xxs),
                    Text(
                      joinedLabel,
                      style: GBTTypography.labelSmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    if (item.bio?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      GBTLinkifiedText(
                        item.bio!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GBTTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionAvatar extends StatelessWidget {
  const _ConnectionAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundColor: isDark
            ? GBTColors.darkSurfaceVariant
            : GBTColors.surfaceVariant,
        child: Icon(
          Icons.person,
          size: 20,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        ),
      );
    }
    return ClipOval(
      child: GBTImage(
        imageUrl: url!,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        semanticLabel: context.l10n(
          ko: '프로필 이미지',
          en: 'Profile image',
          ja: 'プロフィール画像',
        ),
      ),
    );
  }
}
