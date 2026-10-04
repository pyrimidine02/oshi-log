/// EN: Account tools page for blocks, permission requests, and appeals.
/// KO: 차단/권한요청/이의제기를 관리하는 계정 도구 페이지.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/security/user_access_level.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_icon_chip.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_image.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_segmented_tab_bar.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/identity/account/application/settings_controller.dart';
import 'package:oshi_log/features/identity/account/domain/entities/account_tools.dart';
import 'package:oshi_log/features/identity/account/domain/entities/user_profile.dart';
import 'package:oshi_log/features/place/verification/application/failed_attempt_service.dart';
import 'package:oshi_log/features/place/verification/domain/entities/failed_verification_attempt.dart';

enum _AccountToolsTab { blocks, accessLevel, appeals }

class AccountToolsPage extends ConsumerStatefulWidget {
  const AccountToolsPage({super.key});

  @override
  ConsumerState<AccountToolsPage> createState() => _AccountToolsPageState();
}

class _AccountToolsPageState extends ConsumerState<AccountToolsPage>
    with SingleTickerProviderStateMixin {
  _AccountToolsTab _tab = _AccountToolsTab.blocks;
  late final TabController _tabController;
  final _appealDescriptionController = TextEditingController();
  String? _selectedAppealTargetId;
  String? _selectedAppealTargetLabel;

  String _appealTargetType = 'PLACE_VISIT';
  String _appealReason = 'FALSE_REJECTION';

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _AccountToolsTab.values.length, vsync: this)
          ..addListener(() {
            if (!mounted) return;
            final next = _AccountToolsTab.values[_tabController.index];
            if (next != _tab) {
              setState(() => _tab = next);
            }
          });
    unawaited(_refreshAuthorizationSnapshotOnEntry());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appealDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentTab() async {
    switch (_tab) {
      case _AccountToolsTab.blocks:
        await ref
            .read(userBlocksControllerProvider.notifier)
            .load(forceRefresh: true);
      case _AccountToolsTab.accessLevel:
        await Future.wait([
          ref
              .read(userProfileControllerProvider.notifier)
              .load(forceRefresh: true),
          ref
              .read(projectRoleRequestsControllerProvider.notifier)
              .load(forceRefresh: true),
        ]);
      case _AccountToolsTab.appeals:
        await ref
            .read(verificationAppealsControllerProvider.notifier)
            .load(forceRefresh: true);
    }
  }

  Future<void> _refreshAuthorizationSnapshotOnEntry() async {
    await Future.wait([
      ref.read(userProfileControllerProvider.notifier).load(forceRefresh: true),
      ref
          .read(projectRoleRequestsControllerProvider.notifier)
          .load(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blocksState = ref.watch(userBlocksControllerProvider);
    final profileState = ref.watch(userProfileControllerProvider);
    final roleRequestsState = ref.watch(projectRoleRequestsControllerProvider);
    final appealsState = ref.watch(verificationAppealsControllerProvider);

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '계정 도구', en: 'Account tools', ja: 'アカウントツール'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.l10n(ko: '새로고침', en: 'Refresh', ja: '更新する'),
            onPressed: _refreshCurrentTab,
          ),
        ],
      ),
      body: Column(
        children: [
          // EN: Tab selector
          // KO: 탭 선택기
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.sm,
              GBTSpacing.md,
              GBTSpacing.sm,
            ),
            child: GBTSegmentedTabBar(
              controller: _tabController,
              height: GBTSpacing.touchTarget,
              tabs: [
                Tab(
                  text: context.l10n(ko: '차단', en: 'Blocks', ja: 'ブロック'),
                ),
                Tab(
                  text: context.l10n(
                    ko: '권한 요청',
                    en: 'Permission requests',
                    ja: '権限リクエスト',
                  ),
                ),
                Tab(
                  text: context.l10n(ko: '이의제기', en: 'Appeals', ja: '異議申し立て'),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _AccountToolsTab.blocks => _BlocksTab(
                state: blocksState,
                onRefresh: _refreshCurrentTab,
                isDark: isDark,
                onUnblock: (targetUserId) async {
                  final result = await ref
                      .read(userBlocksControllerProvider.notifier)
                      .unblock(targetUserId);
                  if (!context.mounted) return;
                  if (result is Err<void>) {
                    _showErrorSnackBar(context, result.failure.userMessage);
                    return;
                  }
                  _showInfoSnackBar(
                    context,
                    context.l10n(
                      ko: '차단을 해제했습니다',
                      en: 'Block removed.',
                      ja: 'ブロックを解除しました。',
                    ),
                  );
                },
              ),
              _AccountToolsTab.accessLevel => _AccessLevelTab(
                profileState: profileState,
                roleRequestsState: roleRequestsState,
                isDark: isDark,
                onRefresh: _refreshCurrentTab,
                onSubmitRequest: (requestedRole, justification) async {
                  return ref
                      .read(projectRoleRequestsControllerProvider.notifier)
                      .create(
                        requestedRole: requestedRole,
                        justification: justification,
                      );
                },
                onCancelRequest: (requestId) async {
                  return ref
                      .read(projectRoleRequestsControllerProvider.notifier)
                      .cancel(requestId: requestId);
                },
              ),
              _AccountToolsTab.appeals => _AppealsTab(
                state: appealsState,
                targetType: _appealTargetType,
                reason: _appealReason,
                selectedTargetId: _selectedAppealTargetId,
                selectedTargetLabel: _selectedAppealTargetLabel,
                descriptionController: _appealDescriptionController,
                isDark: isDark,
                onTargetTypeChanged: (value) {
                  setState(() {
                    _appealTargetType = value;
                    _selectedAppealTargetId = null;
                    _selectedAppealTargetLabel = null;
                  });
                },
                onReasonChanged: (value) {
                  setState(() => _appealReason = value);
                },
                onTargetSelected: (id, label) {
                  setState(() {
                    _selectedAppealTargetId = id;
                    _selectedAppealTargetLabel = label;
                  });
                },
                onSubmit: () async {
                  final targetId = _selectedAppealTargetId;
                  if (targetId == null || targetId.isEmpty) {
                    _showErrorSnackBar(
                      context,
                      context.l10n(
                        ko: '대상 인증 기록을 선택해주세요',
                        en: 'Please select a target verification record.',
                        ja: '対象の認証記録を選択してください。',
                      ),
                    );
                    return;
                  }
                  final result = await ref
                      .read(verificationAppealsControllerProvider.notifier)
                      .create(
                        targetType: _appealTargetType,
                        targetId: targetId,
                        reason: _appealReason,
                        description: _appealDescriptionController.text.trim(),
                      );
                  if (!context.mounted) return;
                  if (result is Err<VerificationAppeal>) {
                    _showErrorSnackBar(context, result.failure.userMessage);
                    return;
                  }
                  setState(() {
                    _selectedAppealTargetId = null;
                    _selectedAppealTargetLabel = null;
                  });
                  _appealDescriptionController.clear();
                  _showInfoSnackBar(
                    context,
                    context.l10n(
                      ko: '이의제기를 접수했습니다',
                      en: 'Appeal submitted.',
                      ja: '異議申し立てを受け付けました。',
                    ),
                  );
                },
                onRefresh: _refreshCurrentTab,
              ),
            },
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Blocks Tab
// KO: 차단 탭
// ========================================

class _BlocksTab extends StatelessWidget {
  const _BlocksTab({
    required this.state,
    required this.onRefresh,
    required this.isDark,
    required this.onUnblock,
  });

  final AsyncValue<List<UserBlock>> state;
  final Future<void> Function() onRefresh;
  final bool isDark;
  final Future<void> Function(String targetUserId) onUnblock;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: state.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            GBTLoading(
              message: context.l10n(
                ko: '차단 목록을 불러오는 중...',
                en: 'Loading blocked users...',
                ja: 'ブロックリストを読み込んでいます...',
              ),
            ),
          ],
        ),
        error: (error, _) {
          final message = error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '차단 목록을 불러오지 못했어요',
                  en: 'Failed to load blocked users.',
                  ja: 'ブロックリストを読み込めませんでした。',
                );
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              GBTErrorState(message: message, onRetry: onRefresh),
            ],
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                GBTEmptyState(
                  message: context.l10n(
                    ko: '차단한 사용자가 없습니다',
                    en: 'No blocked users.',
                    ja: 'ブロックしたユーザーはいません。',
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.xs,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: GBTSpacing.xs),
            itemBuilder: (context, index) {
              final item = items[index];
              return _BlockItemRow(
                item: item,
                isDark: isDark,
                onUnblock: () => onUnblock(item.blockedUser.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockItemRow extends StatelessWidget {
  const _BlockItemRow({
    required this.item,
    required this.isDark,
    required this.onUnblock,
  });

  final UserBlock item;
  final bool isDark;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(GBTSpacing.md),
      color: surfaceColor,
      child: Row(
        children: [
          // EN: User avatar
          // KO: 사용자 아바타
          ClipOval(
            child: item.blockedUser.avatarUrl != null
                ? GBTImage(
                    imageUrl: item.blockedUser.avatarUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: isDark
                        ? GBTColors.darkSurfaceVariant
                        : GBTColors.surfaceVariant,
                    alignment: Alignment.center,
                    child: Text(
                      item.blockedUser.displayName.characters.first,
                      style: GBTTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textTertiary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: GBTSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.blockedUser.displayName,
                  style: GBTTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dateLabel(item.createdAt)}'
                  '${item.reason != null ? ' · ${item.reason}' : ''}',
                  style: GBTTypography.labelSmall.copyWith(color: textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          // EN: Unblock button
          // KO: 차단 해제 버튼
          OutlinedButton(
            onPressed: onUnblock,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, GBTSpacing.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
              side: BorderSide(color: GBTColors.error.withValues(alpha: 0.4)),
              foregroundColor: GBTColors.error,
            ),
            child: Text(context.l10n(ko: '해제', en: 'Unblock', ja: '解除する')),
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Permission requests tab
// KO: 권한 요청 탭
// ========================================

class _AccessLevelTab extends StatelessWidget {
  const _AccessLevelTab({
    required this.profileState,
    required this.roleRequestsState,
    required this.isDark,
    required this.onRefresh,
    required this.onSubmitRequest,
    required this.onCancelRequest,
  });

  final AsyncValue<UserProfile?> profileState;
  final AsyncValue<List<ProjectRoleRequest>> roleRequestsState;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final Future<Result<ProjectRoleRequest>> Function(
    String requestedRole,
    String justification,
  )
  onSubmitRequest;
  final Future<Result<void>> Function(String requestId) onCancelRequest;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.xs,
        ),
        children: [
          profileState.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.lg),
              child: GBTLoading(
                message: context.l10n(
                  ko: '권한 요청 정보를 불러오는 중...',
                  en: 'Loading permission request info...',
                  ja: '権限リクエスト情報を読み込んでいます...',
                ),
              ),
            ),
            error: (error, _) {
              final message = error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '권한 요청 정보를 불러오지 못했어요',
                      en: 'Failed to load permission request info.',
                      ja: '権限リクエスト情報を読み込めませんでした。',
                    );
              return GBTErrorState(message: message, onRetry: onRefresh);
            },
            data: (profile) {
              if (profile == null) {
                return GBTEmptyState(
                  message: context.l10n(
                    ko: '로그인이 필요합니다',
                    en: 'Sign-in required',
                    ja: 'ログインが必要です',
                  ),
                );
              }
              final resolvedLevel = UserAccessLevelX.resolve(
                effectiveAccessLevel: profile.effectiveAccessLevel,
                accountRole: profile.accountRole,
              );
              final canRequestEditor = !resolvedLevel.isAtLeast(
                UserAccessLevel.contentEditor,
              );
              final canRequestModerator = !resolvedLevel.isAtLeast(
                UserAccessLevel.communityModerator,
              );
              return Container(
                padding: const EdgeInsets.all(GBTSpacing.md),
                color: surfaceColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GBTIconChip(
                          icon: Icons.verified_user_rounded,
                          color: GBTColors.secondary,
                          size: 32,
                        ),
                        const SizedBox(width: GBTSpacing.sm),
                        Text(
                          context.l10n(
                            ko: '권한 요청',
                            en: 'Permission requests',
                            ja: '権限リクエスト',
                          ),
                          style: GBTTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    Text(
                      context.l10n(
                        ko: context.l10n(
                          ko: '내부 권한 레벨 상세는 노출하지 않고 필요한 권한 요청만 제공합니다.',
                          en: 'Internal permission level details are hidden; only the requests you need are shown.',
                          ja: '内部の権限レベル詳細は表示せず、必要な権限リクエストのみを提供します。',
                        ),
                        en: 'Internal permission level details are hidden; only the requests you need are shown.',
                        ja: '内部の権限レベル詳細は表示せず、必要な権限リクエストのみを提供します。',
                      ),
                      style: GBTTypography.bodySmall.copyWith(
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    _PermissionRequestCard(
                      title: context.l10n(
                        ko: '수정권한 요청',
                        en: 'Editor permission request',
                        ja: '編集権限リクエスト',
                      ),
                      description: context.l10n(
                        ko: '장소/라이브/뉴스 등 콘텐츠 정보 편집 권한 요청',
                        en: 'Request edit permission for places, live events, and news content',
                        ja: '場所・ライブ・ニュースなどのコンテンツ編集権限をリクエストします',
                      ),
                      isRequestable: canRequestEditor,
                      onRequest: () => _showPermissionRequestDialog(
                        context,
                        title: context.l10n(
                          ko: '수정권한 요청',
                          en: 'Editor permission request',
                          ja: '編集権限リクエスト',
                        ),
                        requestedRole: 'PLACE_EDITOR',
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    _PermissionRequestCard(
                      title: context.l10n(
                        ko: '관리권한 요청',
                        en: 'Moderator permission request',
                        ja: '管理権限リクエスト',
                      ),
                      description: context.l10n(
                        ko: '신고/제재 등 커뮤니티 운영 권한 요청',
                        en: 'Request community moderation permission for reports and sanctions',
                        ja: '通報・制裁などのコミュニティ運営権限をリクエストします',
                      ),
                      isRequestable: canRequestModerator,
                      onRequest: () => _showPermissionRequestDialog(
                        context,
                        title: context.l10n(
                          ko: '관리권한 요청',
                          en: 'Moderator permission request',
                          ja: '管理権限リクエスト',
                        ),
                        requestedRole: 'COMMUNITY_MODERATOR',
                      ),
                    ),
                    if (!canRequestEditor && !canRequestModerator) ...[
                      const SizedBox(height: GBTSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(GBTSpacing.sm),
                        decoration: BoxDecoration(
                          color: GBTColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            GBTSpacing.radiusSm,
                          ),
                        ),
                        child: Text(
                          context.l10n(
                            ko: context.l10n(
                              ko: '현재 계정은 이미 요청 가능한 권한 이상을 보유하고 있습니다.',
                              en: 'This account already holds permissions beyond what can be requested.',
                              ja: '現在のアカウントはリクエスト可能な権限以上をすでに保有しています。',
                            ),
                            en: 'This account already holds permissions beyond what can be requested.',
                            ja: '現在のアカウントはリクエスト可能な権限以上をすでに保有しています。',
                          ),
                          style: GBTTypography.bodySmall.copyWith(
                            color: GBTColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: GBTSpacing.sm),
                    Text(
                      context.l10n(
                        ko: context.l10n(
                          ko: '요청을 제출하면 운영자가 검토 후 승인/거절합니다.',
                          en: 'After you submit, an operator will review and approve or reject the request.',
                          ja: '送信すると運営者が確認のうえ承認または却下します。',
                        ),
                        en: 'After you submit, an operator will review and approve or reject the request.',
                        ja: '送信すると運営者が確認のうえ承認または却下します。',
                      ),
                      style: GBTTypography.bodySmall.copyWith(
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: GBTSpacing.sm),
          Text(
            context.l10n(
              ko: '내 권한 요청 내역',
              en: 'My permission requests',
              ja: '自分の権限リクエスト履歴',
            ),
            style: GBTTypography.labelMedium.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          roleRequestsState.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.lg),
              child: GBTLoading(
                message: context.l10n(
                  ko: '요청 내역을 불러오는 중...',
                  en: 'Loading request history...',
                  ja: 'リクエスト履歴を読み込んでいます...',
                ),
              ),
            ),
            error: (error, _) {
              final message = error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '요청 내역을 불러오지 못했어요',
                      en: 'Failed to load request history.',
                      ja: 'リクエスト履歴を読み込めませんでした。',
                    );
              return GBTErrorState(message: message, onRetry: onRefresh);
            },
            data: (items) {
              if (items.isEmpty) {
                return GBTEmptyState(
                  message: context.l10n(
                    ko: '아직 제출한 권한 요청이 없습니다',
                    en: 'No permission requests submitted yet.',
                    ja: 'まだ権限リクエストを送信していません。',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
                        child: _ProjectRoleRequestCard(
                          request: request,
                          isDark: isDark,
                          onCancel: request.isPending
                              ? () => _cancelRequest(context, request.id)
                              : null,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionRequestDialog(
    BuildContext context, {
    required String title,
    required String requestedRole,
  }) async {
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(
                  ko: '요청 사유를 20자 이상 작성해주세요.',
                  en: 'Please write a reason of at least 20 characters.',
                  ja: '理由を20文字以上入力してください。',
                ),
                style: GBTTypography.bodySmall,
              ),
              const SizedBox(height: GBTSpacing.sm),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n(
                    ko: '요청 사유',
                    en: 'Reason',
                    ja: 'リクエスト理由',
                  ),
                  hintText: context.l10n(
                    ko: '예: 운영 참여를 위해 권한이 필요합니다.',
                    en: 'e.g. I need this permission to help with moderation.',
                    ja: '例：運営業務に参加するため権限が必要です。',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
            ),
            FilledButton(
              onPressed: () async {
                final reason = reasonController.text.trim().isEmpty
                    ? '-'
                    : reasonController.text.trim();
                final result = await onSubmitRequest(requestedRole, reason);
                if (!dialogContext.mounted || !context.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                if (result is Success<ProjectRoleRequest>) {
                  _showSnackBar(
                    context,
                    context.l10n(
                      ko: '권한 요청을 제출했습니다',
                      en: 'Permission request submitted.',
                      ja: '権限リクエストを送信しました。',
                    ),
                  );
                  return;
                }
                if (result is Err<ProjectRoleRequest>) {
                  _showSnackBar(context, result.failure.userMessage);
                }
              },
              child: Text(
                context.l10n(
                  ko: '요청 제출',
                  en: 'Submit request',
                  ja: 'リクエストを送信する',
                ),
              ),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
  }

  Future<void> _cancelRequest(BuildContext context, String requestId) async {
    final result = await onCancelRequest(requestId);
    if (!context.mounted) return;
    if (result is Success<void>) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '요청을 취소했습니다',
          en: 'Request canceled.',
          ja: 'リクエストをキャンセルしました。',
        ),
      );
      return;
    }
    if (result is Err<void>) {
      _showSnackBar(context, result.failure.userMessage);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PermissionRequestCard extends StatelessWidget {
  const _PermissionRequestCard({
    required this.title,
    required this.description,
    required this.isRequestable,
    required this.onRequest,
  });

  final String title;
  final String description;
  final bool isRequestable;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GBTSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GBTTypography.bodyMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GBTTypography.bodySmall.copyWith(color: textSecondary),
          ),
          const SizedBox(height: GBTSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: isRequestable
                ? FilledButton.tonal(
                    onPressed: onRequest,
                    child: Text(
                      context.l10n(ko: '요청하기', en: 'Request', ja: 'リクエストする'),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: GBTColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        GBTSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      context.l10n(ko: '보유중', en: 'Granted', ja: '保有中'),
                      style: GBTTypography.labelSmall.copyWith(
                        color: GBTColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectRoleRequestCard extends StatelessWidget {
  const _ProjectRoleRequestCard({
    required this.request,
    required this.isDark,
    this.onCancel,
  });

  final ProjectRoleRequest request;
  final bool isDark;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final statusColor = _statusColor(request.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GBTSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.projectName ??
                      request.projectCode ??
                      request.projectId,
                  style: GBTTypography.bodyMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.xs,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
                child: Text(
                  request.statusLabel,
                  style: GBTTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            request.requestedRoleLabel,
            style: GBTTypography.bodySmall.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            request.justification,
            style: GBTTypography.bodySmall.copyWith(
              color: textSecondary,
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: GBTSpacing.xs),
          Row(
            children: [
              Text(
                _dateLabel(request.createdAt),
                style: GBTTypography.labelSmall.copyWith(color: textSecondary),
              ),
              const Spacer(),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, GBTSpacing.touchTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.sm,
                    ),
                  ),
                  child: Text(
                    context.l10n(
                      ko: '요청 취소',
                      en: 'Cancel request',
                      ja: 'リクエストを取り消す',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'GRANTED':
        return GBTColors.success;
      case 'REJECTED':
      case 'DENIED':
        return GBTColors.error;
      case 'CANCELED':
      case 'CANCELLED':
        return GBTColors.textTertiary;
      case 'PENDING':
      case 'OPEN':
      case 'REQUESTED':
      default:
        return GBTColors.info;
    }
  }
}

// ========================================
// EN: Appeals Tab
// KO: 이의제기 탭
// ========================================

class _AppealsTab extends StatelessWidget {
  const _AppealsTab({
    required this.state,
    required this.targetType,
    required this.reason,
    required this.selectedTargetId,
    required this.selectedTargetLabel,
    required this.descriptionController,
    required this.isDark,
    required this.onTargetTypeChanged,
    required this.onReasonChanged,
    required this.onTargetSelected,
    required this.onSubmit,
    required this.onRefresh,
  });

  final AsyncValue<List<VerificationAppeal>> state;
  final String targetType;
  final String reason;
  final String? selectedTargetId;
  final String? selectedTargetLabel;
  final TextEditingController descriptionController;
  final bool isDark;
  final ValueChanged<String> onTargetTypeChanged;
  final ValueChanged<String> onReasonChanged;
  final void Function(String id, String label) onTargetSelected;
  final VoidCallback onSubmit;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final targetTypeOptions = <_SelectionOption>[
      _SelectionOption(
        value: 'PLACE_VISIT',
        label: _appealTargetTypeLabel(context, 'PLACE_VISIT'),
      ),
      _SelectionOption(
        value: 'LIVE_EVENT',
        label: _appealTargetTypeLabel(context, 'LIVE_EVENT'),
      ),
    ];
    final reasonOptions = <_SelectionOption>[
      _SelectionOption(
        value: 'FALSE_REJECTION',
        label: _appealReasonLabel(context, 'FALSE_REJECTION'),
      ),
      _SelectionOption(
        value: 'GPS_INACCURACY',
        label: _appealReasonLabel(context, 'GPS_INACCURACY'),
      ),
      _SelectionOption(
        value: 'NETWORK_ISSUE',
        label: _appealReasonLabel(context, 'NETWORK_ISSUE'),
      ),
      _SelectionOption(
        value: 'DEVICE_ISSUE',
        label: _appealReasonLabel(context, 'DEVICE_ISSUE'),
      ),
      _SelectionOption(
        value: 'LOCATION_ERROR',
        label: _appealReasonLabel(context, 'LOCATION_ERROR'),
      ),
      _SelectionOption(
        value: 'OTHER',
        label: context.l10n(ko: '기타', en: 'Other', ja: 'その他'),
      ),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.xs,
        ),
        children: [
          // EN: Submit form card
          // KO: 제출 폼 카드
          Container(
            padding: const EdgeInsets.all(GBTSpacing.md),
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GBTIconChip(
                      icon: Icons.gavel_rounded,
                      color: GBTColors.warning,
                      size: 32,
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Text(
                      context.l10n(
                        ko: '인증 이의제기 제출',
                        en: 'Submit verification appeal',
                        ja: '認証の異議申し立てを送信',
                      ),
                      style: GBTTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GBTSpacing.md),
                _SelectionField(
                  label: context.l10n(
                    ko: '대상 유형',
                    en: 'Target type',
                    ja: '対象種別',
                  ),
                  isDark: isDark,
                  valueText: _appealTargetTypeLabel(context, targetType),
                  placeholder: context.l10n(
                    ko: '대상 유형 선택',
                    en: 'Select target type',
                    ja: '対象種別を選択',
                  ),
                  onTap: () async {
                    final selected = await _showSelectionPicker(
                      context,
                      title: context.l10n(
                        ko: '대상 유형 선택',
                        en: 'Select target type',
                        ja: '対象種別を選択',
                      ),
                      options: targetTypeOptions,
                      selectedValue: targetType,
                    );
                    if (selected != null && selected.isNotEmpty) {
                      onTargetTypeChanged(selected);
                    }
                  },
                ),
                const SizedBox(height: GBTSpacing.sm),
                _TargetSelectorRow(
                  targetType: targetType,
                  selectedLabel: selectedTargetLabel,
                  isDark: isDark,
                  onTap: () async {
                    final result =
                        await showModalBottomSheet<(String, String)?>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) =>
                              _TargetPickerSheet(targetType: targetType),
                        );
                    if (result != null) {
                      onTargetSelected(result.$1, result.$2);
                    }
                  },
                ),
                const SizedBox(height: GBTSpacing.sm),
                _SelectionField(
                  label: context.l10n(ko: '사유', en: 'Reason', ja: '理由'),
                  isDark: isDark,
                  valueText: _appealReasonLabel(context, reason),
                  placeholder: context.l10n(
                    ko: '사유 선택',
                    en: 'Select reason',
                    ja: '理由を選択',
                  ),
                  onTap: () async {
                    final selected = await _showSelectionPicker(
                      context,
                      title: context.l10n(
                        ko: '사유 선택',
                        en: 'Select reason',
                        ja: '理由を選択',
                      ),
                      options: reasonOptions,
                      selectedValue: reason,
                    );
                    if (selected != null && selected.isNotEmpty) {
                      onReasonChanged(selected);
                    }
                  },
                ),
                const SizedBox(height: GBTSpacing.sm),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.l10n(
                      ko: '상세 설명 (선택)',
                      en: 'Details (optional)',
                      ja: '詳細説明（任意）',
                    ),
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      context.l10n(
                        ko: '이의제기 제출',
                        en: 'Submit appeal',
                        ja: '異議申し立てを送信する',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GBTSpacing.lg),

          // EN: My appeals section header
          // KO: 내 이의제기 섹션 헤더
          Padding(
            padding: const EdgeInsets.only(
              left: GBTSpacing.xs,
              bottom: GBTSpacing.xs,
            ),
            child: Text(
              context.l10n(
                ko: '내 이의제기 내역',
                en: 'My appeals',
                ja: '自分の異議申し立て履歴',
              ),
              style: GBTTypography.labelSmall.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          state.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.lg),
              child: GBTLoading(
                message: context.l10n(
                  ko: '이의제기 내역을 불러오는 중...',
                  en: 'Loading appeal history...',
                  ja: '異議申し立て履歴を読み込んでいます...',
                ),
              ),
            ),
            error: (error, _) {
              final message = error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '이의제기 내역을 불러오지 못했어요',
                      en: 'Failed to load appeal history.',
                      ja: '異議申し立て履歴を読み込めませんでした。',
                    );
              return GBTErrorState(message: message, onRetry: onRefresh);
            },
            data: (items) {
              if (items.isEmpty) {
                return GBTEmptyState(
                  message: context.l10n(
                    ko: '등록된 이의제기가 없습니다',
                    en: 'No appeals submitted.',
                    ja: '登録された異議申し立てはありません。',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
                        child: _AppealItemRow(item: item, isDark: isDark),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: GBTSpacing.lg),
        ],
      ),
    );
  }
}

class _AppealItemRow extends StatelessWidget {
  const _AppealItemRow({required this.item, required this.isDark});

  final VerificationAppeal item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    final targetTypeLabel = _appealTargetTypeLabel(context, item.targetType);
    final reasonLabel = _appealReasonLabel(context, item.reason);

    return Container(
      padding: const EdgeInsets.all(GBTSpacing.md),
      color: surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetTypeLabel,
                  style: GBTTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      reasonLabel,
                      style: GBTTypography.labelSmall.copyWith(
                        color: textTertiary,
                      ),
                    ),
                    Text(
                      ' · ${_dateLabel(item.createdAt)}',
                      style: GBTTypography.labelSmall.copyWith(
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          _StatusBadge(status: item.status),
        ],
      ),
    );
  }
}

// ========================================
// EN: Status badge widget
// KO: 상태 배지 위젯
// ========================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final text = switch (normalized) {
      'PENDING' => context.l10n(ko: '대기', en: 'Pending', ja: '待ち'),
      'IN_REVIEW' => context.l10n(ko: '검토중', en: 'In review', ja: '確認中'),
      'APPROVED' => context.l10n(ko: '승인', en: 'Approved', ja: '承認'),
      'REJECTED' => context.l10n(ko: '반려', en: 'Rejected', ja: '却下'),
      _ => status,
    };

    final color = switch (normalized) {
      'APPROVED' => GBTColors.success,
      'REJECTED' => GBTColors.error,
      'IN_REVIEW' => GBTColors.accentBlue,
      _ => GBTColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Text(
        text,
        style: GBTTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectionOption {
  const _SelectionOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.isDark,
    required this.placeholder,
    this.valueText,
    this.onTap,
  });

  final String label;
  final bool isDark;
  final String placeholder;
  final String? valueText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.md,
            vertical: GBTSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? GBTColors.darkBorder : GBTColors.divider,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GBTTypography.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueText ?? placeholder,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: valueText != null && enabled
                            ? textPrimary
                            : textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: enabled
                    ? textSecondary
                    : textSecondary.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _showSelectionPicker(
  BuildContext context, {
  required String title,
  required List<_SelectionOption> options,
  String? selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _SelectionPickerSheet(
      title: title,
      options: options,
      selectedValue: selectedValue,
    ),
  );
}

class _SelectionPickerSheet extends StatelessWidget {
  const _SelectionPickerSheet({
    required this.title,
    required this.options,
    this.selectedValue,
  });

  final String title;
  final List<_SelectionOption> options;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? GBTColors.darkBorder : GBTColors.divider;
    final selectedColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.56,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.sm,
                GBTSpacing.md,
                GBTSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: GBTTypography.titleMedium),
              ),
            ),
            Divider(height: 1, color: dividerColor),
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: dividerColor),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option.value == selectedValue;
                  return ListTile(
                    dense: true,
                    title: Text(
                      option.label,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: selectedColor,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _appealTargetTypeLabel(BuildContext context, String value) =>
    switch (value.toUpperCase()) {
      'PLACE_VISIT' => context.l10n(
        ko: '장소 방문 인증',
        en: 'Place visit verification',
        ja: '場所訪問認証',
      ),
      'LIVE_EVENT' => context.l10n(
        ko: '이벤트 출석 인증',
        en: 'Event attendance verification',
        ja: 'イベント出席認証',
      ),
      _ => value,
    };

String _appealReasonLabel(BuildContext context, String value) => switch (value
    .toUpperCase()) {
  'FALSE_REJECTION' => context.l10n(
    ko: '오탐 거절',
    en: 'False rejection',
    ja: '誤検知による却下',
  ),
  'GPS_INACCURACY' => context.l10n(
    ko: 'GPS 오차',
    en: 'GPS inaccuracy',
    ja: 'GPS誤差',
  ),
  'NETWORK_ISSUE' => context.l10n(
    ko: '네트워크 문제',
    en: 'Network issue',
    ja: 'ネットワークの問題',
  ),
  'DEVICE_ISSUE' => context.l10n(ko: '기기 문제', en: 'Device issue', ja: '端末の問題'),
  'LOCATION_ERROR' => context.l10n(
    ko: '위치 오류',
    en: 'Location error',
    ja: '位置情報エラー',
  ),
  _ => context.l10n(ko: '기타', en: 'Other', ja: 'その他'),
};

// ========================================
// EN: Target selector row — tappable field showing selected verification record
// KO: 선택된 인증 기록을 보여주는 탭 가능한 선택 필드
// ========================================

class _TargetSelectorRow extends StatelessWidget {
  const _TargetSelectorRow({
    required this.targetType,
    required this.selectedLabel,
    required this.isDark,
    required this.onTap,
  });

  final String targetType;
  final String? selectedLabel;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = targetType == 'PLACE_VISIT'
        ? context.l10n(
            ko: '실패한 방문 인증 기록',
            en: 'Failed visit verification records',
            ja: '失敗した訪問認証記録',
          )
        : context.l10n(
            ko: '실패한 이벤트 출석 기록',
            en: 'Failed event attendance records',
            ja: '失敗したイベント出席記録',
          );

    return _SelectionField(
      label: label,
      valueText: selectedLabel,
      placeholder: context.l10n(
        ko: '탭하여 선택',
        en: 'Tap to select',
        ja: 'タップして選択',
      ),
      isDark: isDark,
      onTap: onTap,
    );
  }
}

// ========================================
// EN: Target picker bottom sheet — searchable list of failed verification attempts
// KO: 실패한 인증 기록을 검색하고 선택하는 바텀 시트
// ========================================

class _TargetPickerSheet extends ConsumerStatefulWidget {
  const _TargetPickerSheet({required this.targetType});

  final String targetType;

  @override
  ConsumerState<_TargetPickerSheet> createState() => _TargetPickerSheetState();
}

class _TargetPickerSheetState extends ConsumerState<_TargetPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final isPlaceVisit = widget.targetType == 'PLACE_VISIT';

    // EN: Watch the full list and filter by targetType in the UI.
    // KO: 전체 목록을 구독하고 UI에서 targetType으로 필터링합니다.
    final attemptsAsync = ref.watch(failedVerificationAttemptsProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        children: [
          // EN: Handle bar
          // KO: 핸들 바
          const SizedBox(height: GBTSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            ),
          ),

          // EN: Sheet title
          // KO: 시트 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.md,
              GBTSpacing.md,
              GBTSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isPlaceVisit
                    ? context.l10n(
                        ko: '실패한 방문 인증 기록 선택',
                        en: 'Select failed visit verification record',
                        ja: '失敗した訪問認証記録を選択',
                      )
                    : context.l10n(
                        ko: '실패한 이벤트 출석 기록 선택',
                        en: 'Select failed event attendance record',
                        ja: '失敗したイベント出席記録を選択',
                      ),
                style: GBTTypography.titleMedium,
              ),
            ),
          ),

          // EN: Search field
          // KO: 검색 필드
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              0,
              GBTSpacing.md,
              GBTSpacing.sm,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: isPlaceVisit
                    ? context.l10n(
                        ko: '장소 이름으로 검색',
                        en: 'Search by place name',
                        ja: '場所の名前で検索',
                      )
                    : context.l10n(
                        ko: '이벤트 이름으로 검색',
                        en: 'Search by event name',
                        ja: 'イベント名で検索',
                      ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
          ),

          // EN: Failed attempt list
          // KO: 실패 기록 목록
          Expanded(child: _buildAttemptList(attemptsAsync, isDark)),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildAttemptList(
    AsyncValue<List<FailedVerificationAttempt>> attemptsAsync,
    bool isDark,
  ) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return attemptsAsync.when(
      loading: () => Center(
        child: GBTLoading(
          message: context.l10n(
            ko: '기록을 불러오는 중...',
            en: 'Loading records...',
            ja: '記録を読み込んでいます...',
          ),
        ),
      ),
      error: (_, __) => Center(
        child: GBTErrorState(
          message: context.l10n(
            ko: '기록을 불러오지 못했어요',
            en: 'Failed to load records.',
            ja: '記録を読み込めませんでした。',
          ),
        ),
      ),
      data: (all) {
        // EN: Filter by targetType then apply search query.
        // KO: targetType으로 필터 후 검색어 적용.
        final forType = all
            .where((a) => a.targetType == widget.targetType)
            .toList(growable: false);

        final filtered = _query.isEmpty
            ? forType
            : forType
                  .where(
                    (a) =>
                        (a.targetName?.toLowerCase() ?? '').contains(_query) ||
                        a.targetId.toLowerCase().contains(_query),
                  )
                  .toList(growable: false);

        if (forType.isEmpty) {
          return Center(
            child: Padding(
              padding: GBTSpacing.paddingPage,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 48, color: textTertiary),
                  const SizedBox(height: GBTSpacing.md),
                  Text(
                    context.l10n(
                      ko: context.l10n(
                        ko: '최근 30일 내 실패한 인증 기록이 없습니다',
                        en: 'No failed verification records in the last 30 days.',
                        ja: '直近30日以内に失敗した認証記録はありません。',
                      ),
                      en: 'No failed verification records in the last 30 days.',
                      ja: '直近30日以内に失敗した認証記録はありません。',
                    ),
                    textAlign: TextAlign.center,
                    style: GBTTypography.bodyMedium.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (filtered.isEmpty) {
          return Center(
            child: GBTEmptyState(
              icon: Icons.search_off_rounded,
              message: context.l10n(
                ko: '검색 결과가 없습니다',
                en: 'No search results.',
                ja: '検索結果がありません。',
              ),
            ),
          );
        }

        return ListView.separated(
          physics: Theme.of(context).platform == TargetPlatform.android
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? GBTColors.darkBorder : GBTColors.divider,
          ),
          itemBuilder: (context, index) {
            final attempt = filtered[index];
            final name = attempt.targetName ?? attempt.targetId;
            final date = _dateLabel(attempt.attemptedAt);
            final failCode = _translateFailureCode(attempt.failureCode);
            final label = '$name · $date';

            return ListTile(
              dense: true,
              title: Text(
                name,
                style: GBTTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$date · $failCode',
                style: GBTTypography.labelSmall.copyWith(color: textTertiary),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textTertiary,
              ),
              onTap: () => Navigator.of(context).pop((attempt.targetId, label)),
            );
          },
        );
      },
    );
  }

  /// EN: Translate server/local failure codes to Korean labels.
  /// KO: 서버/로컬 실패 코드를 한국어 레이블로 변환합니다.
  String _translateFailureCode(String code) => switch (code.toUpperCase()) {
    'LOCATION_TOO_FAR' => context.l10n(
      ko: '위치 거리 초과',
      en: 'Location too far',
      ja: '位置の距離超過',
    ),
    'TIME_WINDOW_EXPIRED' => context.l10n(
      ko: '인증 시간 만료',
      en: 'Verification time expired',
      ja: '認証時間の期限切れ',
    ),
    'GPS_INACCURACY' || 'LOCATION_INACCURATE' => context.l10n(
      ko: 'GPS 오차',
      en: 'GPS inaccuracy',
      ja: 'GPS誤差',
    ),
    'INVALID_TOKEN' || 'JWS_INVALID' => context.l10n(
      ko: '토큰 오류',
      en: 'Token error',
      ja: 'トークンエラー',
    ),
    'NETWORK_ERROR' || 'TIMEOUT' => context.l10n(
      ko: '네트워크 오류',
      en: 'Network error',
      ja: 'ネットワークエラー',
    ),
    'ALREADY_VERIFIED' => context.l10n(
      ko: '이미 인증됨',
      en: 'Already verified',
      ja: '認証済み',
    ),
    _ => context.l10n(ko: '인증 실패', en: 'Verification failed', ja: '認証失敗'),
  };
}

void _showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    ),
  );
}

String _dateLabel(DateTime dateTime) {
  return dateTime.toLocal().toIso8601String().split('T').first;
}
