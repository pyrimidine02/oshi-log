/// EN: Community post detail page with comments.
/// KO: 댓글을 포함한 커뮤니티 게시글 상세 페이지.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/security/user_access_level.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/utils/image_url_extractor.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/common/gbt_action_icons.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../../core/widgets/sheets/gbt_bottom_sheet.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/community_moderation_controller.dart';
import '../../application/feed_controller.dart';
import '../../application/local_post_bookmarks_controller.dart';
import '../../application/report_rate_limiter.dart';
import '../../application/user_follow_controller.dart';
import '../../domain/entities/community_moderation.dart';
import '../../domain/entities/feed_entities.dart';
import '../widgets/community_translation_panel.dart';
import '../widgets/community_report_sheet.dart';
import '../../../titles/application/titles_controller.dart';
import '../../../titles/presentation/widgets/active_title_badge.dart';

/// EN: Post detail page widget.
/// KO: 게시글 상세 페이지 위젯.
enum _PostAction { edit, delete }

enum _CommentAction { edit, delete }

enum _PostOtherAction { report, blockToggle }

enum _CommentOtherAction { report }

enum _CommentSort { latest, oldest }

const int _maxCommentReplyDepth = 10;
const String _deletedCommentPlaceholder = '[Deleted comment]';
const String _deletedCommentPlaceholderLegacy = '삭제된 댓글입니다';

bool _isDeletedCommentPlaceholder(String content) {
  final normalized = content.trim();
  return normalized == _deletedCommentPlaceholder ||
      normalized == _deletedCommentPlaceholderLegacy;
}

String _displayCommentContent(String content) {
  if (_isDeletedCommentPlaceholder(content)) {
    return _deletedCommentPlaceholderLegacy;
  }
  return content;
}

int _resolveCommentDepth(PostComment comment) {
  if (comment.depth != null && comment.depth! >= 0) {
    return comment.depth!;
  }
  return comment.parentCommentId == null ? 0 : 1;
}

bool _canReplyToComment(PostComment comment) {
  if (_isDeletedCommentPlaceholder(comment.content)) {
    return false;
  }
  return _resolveCommentDepth(comment) < _maxCommentReplyDepth;
}

class _CommentThread {
  const _CommentThread({
    required this.id,
    required this.sortAnchor,
    required this.replies,
    this.rootComment,
  });

  final String id;
  final DateTime sortAnchor;
  final PostComment? rootComment;
  final List<PostComment> replies;

  bool get isDeletedPlaceholder => rootComment == null;
}

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.projectCodeHint});

  final String postId;
  final String? projectCodeHint;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();
  bool _isSubmitting = false;
  // EN: Currently targeted comment when composing a reply.
  // KO: 답글 작성 중인 대상 댓글.
  PostComment? _replyTarget;

  PostRouteTarget _routeTargetFor(String postId) {
    return PostRouteTarget(
      postId: postId,
      projectCodeHint: widget.projectCodeHint,
    );
  }

  void _setReplyTarget(PostComment comment) {
    if (!_canReplyToComment(comment)) {
      if (_isDeletedCommentPlaceholder(comment.content)) {
        _showSnackBar(context, '삭제된 댓글에는 답글을 작성할 수 없어요');
      } else {
        _showSnackBar(context, '답글은 최대 $_maxCommentReplyDepth단계까지만 작성할 수 있어요');
      }
      return;
    }
    setState(() => _replyTarget = comment);
    _commentFocusNode.requestFocus();
  }

  void _clearReplyTarget() {
    setState(() => _replyTarget = null);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _focusCommentComposer() async {
    if (_contentScrollController.hasClients) {
      await _contentScrollController.animateTo(
        _contentScrollController.position.maxScrollExtent,
        duration: GBTAnimations.normal,
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) {
      return;
    }
    _commentFocusNode.requestFocus();
  }

  Future<void> _refreshFeedAfterWrite() async {
    await ref
        .read(communityFeedControllerProvider.notifier)
        .reload(forceRefresh: true);
    await ref
        .read(postListControllerProvider.notifier)
        .load(forceRefresh: true);
  }

  Future<void> _onRefresh() async {
    final routeTarget = _routeTargetFor(widget.postId);
    ref.invalidate(postDetailRouteControllerProvider(routeTarget));
    ref.invalidate(postCommentsRouteControllerProvider(routeTarget));
    // optionally wait for a short duration or until provider emits data
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final routeTarget = _routeTargetFor(widget.postId);
    final state = ref.watch(postDetailRouteControllerProvider(routeTarget));
    final commentsState = ref.watch(
      postCommentsRouteControllerProvider(routeTarget),
    );
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final selectedProjectKey = ref.watch(selectedProjectKeyProvider);
    final profileState = ref.watch(userProfileControllerProvider);
    final currentUserId = profileState.maybeWhen(
      data: (profile) => profile?.id,
      orElse: () => null,
    );
    final currentPost = state.maybeWhen(
      data: (post) => post,
      orElse: () => null,
    );
    final isAdmin = profileState.maybeWhen(
      data: (profile) => _isAdminRole(
        effectiveAccessLevel: profile?.effectiveAccessLevel,
        accountRole: profile?.accountRole,
        projectRolesByProject: profile?.projectRolesByProject,
        projectId: currentPost?.projectId ?? selectedProjectId,
        projectCode: currentPost?.projectId ?? selectedProjectKey,
      ),
      orElse: () => false,
    );
    final likeState = currentPost == null
        ? const AsyncLoading<PostLikeStatus>()
        : ref.watch(
            postLikeControllerProvider(
              PostReactionTarget(
                postId: currentPost.id,
                projectCodeOverride: currentPost.projectId,
              ),
            ),
          );
    final bookmarkState = currentPost == null
        ? const AsyncLoading<PostBookmarkStatus>()
        : ref.watch(
            postBookmarkControllerProvider(
              PostReactionTarget(
                postId: currentPost.id,
                projectCodeOverride: currentPost.projectId,
              ),
            ),
          );
    final canManagePost =
        currentPost != null && currentUserId == currentPost.authorId;
    final blockStatusState =
        !canManagePost && currentPost != null && isAuthenticated
        ? ref.watch(blockStatusControllerProvider(currentPost.authorId))
        : null;
    final blockStatus = blockStatusState?.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final authorFollowState =
        !canManagePost && currentPost != null && isAuthenticated
        ? ref.watch(userFollowControllerProvider(currentPost.authorId))
        : null;
    final blockLabel = blockStatus?.blockedByMe == true ? '차단 해제' : '차단';

    final actions = !isAuthenticated || currentPost == null
        ? null
        : canManagePost
        ? [
            IconButton(
              tooltip: '게시글 관리',
              icon: const Icon(Icons.more_horiz),
              onPressed: () async {
                final action = await showGBTActionSheet<_PostAction>(
                  context: context,
                  actions: [
                    const GBTActionSheetItem(
                      label: '수정',
                      value: _PostAction.edit,
                      icon: Icons.edit_outlined,
                    ),
                    const GBTActionSheetItem(
                      label: '삭제',
                      value: _PostAction.delete,
                      icon: Icons.delete_outline,
                      isDestructive: true,
                    ),
                  ],
                  cancelLabel: '취소',
                );
                if (action != null && context.mounted) {
                  _handlePostAction(context, action, currentPost);
                }
              },
            ),
          ]
        : [
            IconButton(
              tooltip: '게시글 옵션',
              icon: const Icon(Icons.more_horiz),
              onPressed: () async {
                final action = await showGBTActionSheet<_PostOtherAction>(
                  context: context,
                  actions: [
                    const GBTActionSheetItem(
                      label: '신고',
                      value: _PostOtherAction.report,
                      icon: Icons.flag_outlined,
                    ),
                    GBTActionSheetItem(
                      label: blockLabel,
                      value: _PostOtherAction.blockToggle,
                      icon: Icons.person_off_outlined,
                    ),
                  ],
                  cancelLabel: '취소',
                );
                if (action != null && context.mounted) {
                  _handlePostOtherAction(context, action, currentPost);
                }
              },
            ),
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(context, title: '커뮤니티 기록', actions: actions),
      body: state.when(
        loading: () => const _PostDetailSkeleton(),
        error: (error, _) {
          final message = error is Failure
              ? error.userMessage
              : '게시글을 불러오지 못했어요';
          return GBTErrorState(
            message: message,
            onRetry: () => ref
                .read(postDetailRouteControllerProvider(routeTarget).notifier)
                .load(forceRefresh: true),
          );
        },
        data: (post) => PostDetailDocumentView(
          post: post,
          commentsState: commentsState,
          likeState: likeState,
          bookmarkState: bookmarkState,
          currentUserId: currentUserId,
          isAdmin: isAdmin,
          isAuthenticated: isAuthenticated,
          isSubmitting: _isSubmitting,
          scrollController: _contentScrollController,
          commentController: _commentController,
          commentFocusNode: _commentFocusNode,
          onToggleLike: () async {
            final reactionTarget = PostReactionTarget(
              postId: post.id,
              projectCodeOverride: post.projectId,
            );
            final result = await ref
                .read(postLikeControllerProvider(reactionTarget).notifier)
                .toggleLike();
            if (result is Err<PostLikeStatus> && context.mounted) {
              _showSnackBar(context, '좋아요 상태를 반영하지 못했어요');
            }
          },
          onToggleBookmark: () async {
            final reactionTarget = PostReactionTarget(
              postId: post.id,
              projectCodeOverride: post.projectId,
            );
            final result = await ref
                .read(postBookmarkControllerProvider(reactionTarget).notifier)
                .toggleBookmark();
            if (result is Success<PostBookmarkStatus>) {
              final bookmarksNotifier = ref.read(
                localPostBookmarksControllerProvider.notifier,
              );
              if (result.data.isBookmarked) {
                unawaited(
                  bookmarksNotifier.addBookmark(
                    LocalBookmarkedPost(
                      postId: post.id,
                      projectCode: post.projectId,
                      title: post.title,
                      thumbnailUrl: post.imageUrls.isNotEmpty
                          ? post.imageUrls.first
                          : null,
                      bookmarkedAt: result.data.bookmarkedAt ?? DateTime.now(),
                    ),
                  ),
                );
              } else {
                unawaited(bookmarksNotifier.removeBookmark(post.id));
              }
            }
            if (result is Err<PostBookmarkStatus> && context.mounted) {
              _showSnackBar(context, '북마크 상태를 반영하지 못했어요');
            }
          },
          onSubmitComment: () async {
            final content = _commentController.text.trim();
            if (content.isEmpty || _isSubmitting) return;
            setState(() => _isSubmitting = true);
            // EN: Use the reply target's own ID so reply-of-reply depth is preserved.
            // KO: 답글 대상의 ID를 직접 사용하여 대댓글 깊이를 유지합니다.
            final parentId = _replyTarget?.id;
            _clearReplyTarget();
            final result = await ref
                .read(
                  postCommentsRouteControllerProvider(
                    _routeTargetFor(post.id),
                  ).notifier,
                )
                .addComment(content, parentCommentId: parentId);
            if (result is Err<PostComment> && context.mounted) {
              _showSnackBar(
                context,
                parentId != null ? '답글을 등록하지 못했어요' : '댓글을 등록하지 못했어요',
              );
            }
            if (result is Success<PostComment>) {
              _commentController.clear();
              unawaited(_refreshFeedAfterWrite());
              if (context.mounted) {
                _showSnackBar(
                  context,
                  parentId != null ? '답글이 등록되었어요' : '댓글이 등록되었어요',
                );
              }
            }
            if (mounted) {
              setState(() => _isSubmitting = false);
            }
          },
          onEditComment: (comment) => _showEditCommentDialog(
            context,
            postId: post.id,
            comment: comment,
          ),
          onDeleteComment: (comment) => _confirmDeleteComment(
            context,
            postId: post.id,
            comment: comment,
            useModeration:
                isAdmin &&
                currentUserId != null &&
                currentUserId != comment.authorId,
          ),
          onReportComment: (comment) => _showReportFlow(
            context,
            CommunityReportTargetType.comment,
            comment.id,
          ),
          onOpenCommentThread: (comment) =>
              _showCommentThread(context, postId: post.id, comment: comment),
          onAppealPost: () =>
              _showAppealFlow(context, CommunityReportTargetType.post, post.id),
          onTapAuthor: (authorId) => context.goToUserProfile(authorId),
          onFocusComment: _focusCommentComposer,
          replyTarget: _replyTarget,
          onReplyToComment: _setReplyTarget,
          onCancelReply: _clearReplyTarget,
          authorBlockStatus: blockStatus,
          authorFollowState: authorFollowState,
          onToggleFollowAuthor:
              !isAuthenticated || currentPost == null || canManagePost
              ? null
              : () async {
                  final result = await ref
                      .read(
                        userFollowControllerProvider(
                          currentPost.authorId,
                        ).notifier,
                      )
                      .toggleFollow();
                  if (!context.mounted) {
                    return;
                  }
                  if (result is Success<bool>) {
                    _showSnackBar(
                      context,
                      result.data ? '작성자를 팔로우했어요' : '팔로우를 취소했어요',
                    );
                  } else {
                    _showSnackBar(context, '팔로우 상태를 변경하지 못했어요');
                  }
                },
          onRefresh: _onRefresh,
        ),
      ),
    );
  }

  Future<void> _handlePostAction(
    BuildContext context,
    _PostAction action,
    PostDetail post,
  ) async {
    if (action == _PostAction.edit) {
      context.goToPostEdit(post);
      return;
    }
    if (action == _PostAction.delete) {
      await _confirmDeletePost(context, post);
    }
  }

  Future<void> _handlePostOtherAction(
    BuildContext context,
    _PostOtherAction action,
    PostDetail post,
  ) async {
    if (action == _PostOtherAction.report) {
      await _showReportFlow(context, CommunityReportTargetType.post, post.id);
      return;
    }
    if (action == _PostOtherAction.blockToggle) {
      await _toggleBlockUser(context, post.authorId);
    }
  }

  Future<void> _confirmDeletePost(BuildContext context, PostDetail post) async {
    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로젝트를 먼저 선택해주세요')));
      return;
    }
    final confirm = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '게시글 삭제',
      message: '정말로 이 게시글을 삭제할까요?',
      cancelLabel: '취소',
      confirmLabel: '삭제',
      isDestructive: true,
    );

    if (confirm != true) return;
    final repository = await ref.read(feedRepositoryProvider.future);
    final result = await repository.deletePost(
      projectCode: projectCode,
      postId: post.id,
    );

    if (!context.mounted) return;
    if (result is Success<void>) {
      await ref
          .read(postListControllerProvider.notifier)
          .load(forceRefresh: true);
      if (context.mounted) {
        _showSnackBar(context, '게시글을 삭제했어요');
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.community);
        }
      }
    } else if (result is Err<void> && context.mounted) {
      _showSnackBar(context, '게시글을 삭제하지 못했어요');
    }
  }

  Future<void> _showEditCommentDialog(
    BuildContext context, {
    required String postId,
    required PostComment comment,
  }) async {
    final controller = TextEditingController(text: comment.content);
    final newContent = await showGBTBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      title: '댓글 수정',
      child: Builder(
        builder: (sheetContext) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.sm,
              GBTSpacing.md,
              bottomInset + GBTSpacing.md,
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final trimmed = value.text.trim();
                final canSave =
                    trimmed.isNotEmpty && trimmed != comment.content;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: '댓글 내용을 입력하세요',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            GBTSpacing.radiusMd,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(GBTSpacing.md),
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: GBTSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: canSave
                                ? () => Navigator.of(sheetContext).pop(trimmed)
                                : null,
                            child: const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
    controller.dispose();

    if (newContent == null || newContent == comment.content) return;

    final result = await ref
        .read(
          postCommentsRouteControllerProvider(_routeTargetFor(postId)).notifier,
        )
        .updateComment(comment.id, newContent);
    if (result is Err<PostComment> && context.mounted) {
      _showSnackBar(context, '댓글을 수정하지 못했어요');
      return;
    }
    if (result is Success<PostComment> && context.mounted) {
      _showSnackBar(context, '댓글을 수정했어요');
    }
  }

  Future<void> _confirmDeleteComment(
    BuildContext context, {
    required String postId,
    required PostComment comment,
    required bool useModeration,
  }) async {
    final confirm = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '댓글 삭제',
      message: '댓글을 삭제할까요?',
      cancelLabel: '취소',
      confirmLabel: '삭제',
      isDestructive: true,
    );

    if (confirm != true) return;

    final Result<void> result;
    if (useModeration) {
      final projectCode = ref.read(selectedProjectKeyProvider);
      if (projectCode == null || projectCode.isEmpty) {
        if (context.mounted) {
          _showSnackBar(context, '프로젝트를 먼저 선택해주세요');
        }
        return;
      }
      final repository = await ref.read(communityRepositoryProvider.future);
      result = await repository.moderateDeletePostComment(
        projectCode: projectCode,
        postId: postId,
        commentId: comment.id,
      );
      if (result is Success<void>) {
        await ref
            .read(
              postCommentsRouteControllerProvider(
                _routeTargetFor(postId),
              ).notifier,
            )
            .load(forceRefresh: true);
      }
    } else {
      result = await ref
          .read(
            postCommentsRouteControllerProvider(
              _routeTargetFor(postId),
            ).notifier,
          )
          .deleteComment(comment.id);
    }
    if (result is Err<void> && context.mounted) {
      _showSnackBar(context, '댓글을 삭제하지 못했어요');
      return;
    }
    if (result is Success<void> && context.mounted) {
      _showSnackBar(context, '댓글을 삭제했어요');
    }
  }

  Future<void> _showCommentThread(
    BuildContext context, {
    required String postId,
    required PostComment comment,
  }) async {
    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      if (context.mounted) {
        _showSnackBar(context, '프로젝트를 먼저 선택해주세요');
      }
      return;
    }

    final repository = await ref.read(feedRepositoryProvider.future);
    final result = await repository.getPostCommentThread(
      projectCode: projectCode,
      postId: postId,
      parentCommentId: comment.id,
      maxDepth: _maxCommentReplyDepth,
      size: 50,
    );

    if (!context.mounted) return;
    if (result is Err<List<CommentThreadNode>>) {
      _showSnackBar(context, '답글 스레드를 불러오지 못했어요');
      return;
    }

    final thread = result is Success<List<CommentThreadNode>>
        ? result.data
        : <CommentThreadNode>[];
    await showGBTBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      title: '답글 스레드',
      child: Builder(
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(GBTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: thread.isEmpty
                        ? const Center(child: Text('표시할 답글이 없습니다'))
                        : ListView(
                            children: thread
                                .map(
                                  (node) => _CommentThreadNodeView(node: node),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showReportFlow(
    BuildContext context,
    CommunityReportTargetType targetType,
    String targetId,
  ) async {
    // EN: Check cooldown before opening report flow.
    // KO: 신고 플로우 시작 전 쿨다운을 확인합니다.
    final rateLimiter = ref.read(reportRateLimiterProvider);
    if (!rateLimiter.canReport(targetId)) {
      final remaining = rateLimiter.remainingCooldown(targetId);
      final minutes = remaining.inMinutes + 1;
      if (!context.mounted) return;
      _showSnackBar(context, '$minutes분 후 다시 신고할 수 있어요');
      return;
    }

    final payload = await showGBTBottomSheet<CommunityReportPayload>(
      context: context,
      isScrollControlled: true,
      title: '신고',
      child: const CommunityReportSheet(),
    );
    if (payload == null) return;

    if (!context.mounted) return;
    final confirmed = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '신고 접수',
      message:
          '${targetType.label}을(를) "${payload.reason.label}" 사유로 신고합니다.\n접수하시겠어요?',
      cancelLabel: '취소',
      confirmLabel: '신고 접수',
    );
    if (confirmed != true) return;

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.createReport(
      targetType: targetType,
      targetId: targetId,
      reason: payload.reason,
      description: payload.description,
    );

    if (result is Err<void> && context.mounted) {
      _showSnackBar(context, '신고를 접수하지 못했어요');
      return;
    }
    if (result is Success<void>) {
      rateLimiter.recordReport(targetId);
      if (context.mounted) {
        _showSnackBar(context, '신고가 접수되었어요. 검토 후 조치할게요');
      }
    }
  }

  Future<void> _showAppealFlow(
    BuildContext context,
    CommunityReportTargetType targetType,
    String targetId,
  ) async {
    final controller = TextEditingController();
    final reason = await showGBTBottomSheet<String>(
      context: context,
      title: '이의제기',
      child: Builder(
        builder: (dialogContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.xs,
            GBTSpacing.md,
            MediaQuery.of(dialogContext).viewInsets.bottom + GBTSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이의제기 사유를 입력해주세요.'),
              const SizedBox(height: GBTSpacing.md),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '사유를 입력하세요'),
              ),
              const SizedBox(height: GBTSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        Navigator.of(dialogContext).pop(text);
                      },
                      child: const Text('제출'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();

    if (reason == null || !context.mounted) return;

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.submitAppeal(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
    );

    if (!context.mounted) return;
    if (result is Success<void>) {
      _showSnackBar(context, '이의제기가 접수되었어요');
      return;
    }
    if (result is Err<void>) {
      _showSnackBar(context, '이의제기 접수에 실패했어요');
    }
  }

  Future<void> _toggleBlockUser(BuildContext context, String userId) async {
    final controller = ref.read(blockStatusControllerProvider(userId).notifier);
    final result = await controller.toggleBlock();

    if (result is Err<void> && context.mounted) {
      _showSnackBar(context, '차단 상태를 변경하지 못했어요');
      return;
    }

    if (!context.mounted) return;
    final state = ref.read(blockStatusControllerProvider(userId));
    final blockedByMe = state.maybeWhen(
      data: (value) => value.blockedByMe,
      orElse: () => false,
    );
    _showSnackBar(context, blockedByMe ? '사용자를 차단했어요' : '차단을 해제했어요');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// EN: Displays a post, its actions, and its comment log as one field note.
/// KO: 게시글, 액션, 댓글 기록을 하나의 현장 기록 문서로 표시합니다.
class PostDetailDocumentView extends ConsumerWidget {
  const PostDetailDocumentView({
    super.key,
    required this.post,
    required this.commentsState,
    required this.likeState,
    required this.bookmarkState,
    required this.currentUserId,
    required this.isAdmin,
    required this.isAuthenticated,
    required this.isSubmitting,
    required this.scrollController,
    required this.commentController,
    required this.commentFocusNode,
    required this.onToggleLike,
    required this.onToggleBookmark,
    required this.onSubmitComment,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onReportComment,
    required this.onOpenCommentThread,
    required this.onAppealPost,
    required this.onTapAuthor,
    required this.onFocusComment,
    required this.authorBlockStatus,
    required this.authorFollowState,
    required this.onToggleFollowAuthor,
    required this.replyTarget,
    required this.onReplyToComment,
    required this.onCancelReply,
    required this.onRefresh,
  });

  final PostDetail post;
  final AsyncValue<List<PostComment>> commentsState;
  final AsyncValue<PostLikeStatus> likeState;
  final AsyncValue<PostBookmarkStatus> bookmarkState;
  final String? currentUserId;
  final bool isAdmin;
  final bool isAuthenticated;
  final bool isSubmitting;
  final ScrollController scrollController;
  final TextEditingController commentController;
  final FocusNode commentFocusNode;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final VoidCallback onSubmitComment;
  final ValueChanged<PostComment> onEditComment;
  final ValueChanged<PostComment> onDeleteComment;
  final ValueChanged<PostComment> onReportComment;
  final ValueChanged<PostComment> onOpenCommentThread;
  final VoidCallback onAppealPost;
  final ValueChanged<String> onTapAuthor;
  final VoidCallback onFocusComment;
  final BlockStatus? authorBlockStatus;
  final AsyncValue<UserFollowStatus>? authorFollowState;
  final Future<void> Function()? onToggleFollowAuthor;
  final PostComment? replyTarget;
  final ValueChanged<PostComment> onReplyToComment;
  final VoidCallback onCancelReply;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorLabel = post.authorName?.isNotEmpty == true
        ? post.authorName!
        : '익명';
    final authorAvatarUrl = post.authorAvatarUrl?.isNotEmpty == true
        ? post.authorAvatarUrl
        : null;
    final authorTitleItem = ref
        .watch(userActiveTitleProvider(post.authorId))
        .valueOrNull;
    final likeStatus = likeState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final likeCount = likeStatus?.likeCount ?? post.likeCount ?? 0;
    final isLiked = likeStatus?.isLiked ?? false;
    final bookmarkStatus = bookmarkState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final isBookmarked = bookmarkStatus?.isBookmarked ?? false;
    final commentCountLabel = _commentCountLabel(
      commentsState,
      fallback: post.commentCount,
    );
    final contentText = stripImageMarkdown(post.content ?? '');
    // EN: Use API imageUrls as primary source. Only fall back to embedded
    //     extraction when the API returns no images, to avoid duplicates.
    // KO: API imageUrls를 우선 사용. 중복 방지를 위해 API에 이미지가 없을 때만
    //     콘텐츠에서 추출합니다.
    // EN: Normalize and de-duplicate URLs to avoid showing the same image twice.
    // KO: 동일 이미지가 중복 표시되지 않도록 URL을 정규화하고 중복 제거합니다.
    final List<String> mergedImageUrls = post.imageUrls.isNotEmpty
        ? _normalizeImageUrls(post.imageUrls)
        : _normalizeImageUrls(extractImageUrls(post.content));
    final isOwnPost = currentUserId != null && currentUserId == post.authorId;
    final followStatus = authorFollowState?.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final isFollowLoading = authorFollowState?.isLoading ?? false;
    final isAuthorBlocked =
        authorBlockStatus?.blockedByMe == true ||
        authorBlockStatus?.blockedMe == true ||
        authorBlockStatus?.blockedByAdmin == true;

    // EN: Use theme-aware colors for dark mode compatibility.
    // KO: 다크 모드 호환성을 위해 테마 인식 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final commentActionColor = isDark
        ? GBTColors.darkPrimary
        : GBTColors.accentBlue;

    return Column(
      key: const ValueKey<String>('field-note-document'),
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(
                top: GBTSpacing.pageTop,
                bottom: GBTSpacing.pageBottom,
              ),
              children: [
                // EN: Post content with horizontal page padding.
                // KO: 게시글 본문 영역 — 수평 페이지 패딩 적용.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.pageHorizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key: const ValueKey<String>('field-note-header'),
                        post.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: GBTSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(
                            url: authorAvatarUrl,
                            radius: 26,
                            semanticLabel: '$authorLabel 프로필 사진',
                            onTap: () => onTapAuthor(post.authorId),
                          ),
                          const SizedBox(width: GBTSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: GBTSpacing.xs,
                                  runSpacing: GBTSpacing.xs2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      authorLabel,
                                      style: GBTTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (authorTitleItem?.hasTitle == true)
                                      ActiveTitleBadge.fromActiveItem(
                                        authorTitleItem!,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: GBTSpacing.xs2),
                                Text(
                                  '${post.timeAgoLabel}'
                                  '${post.updatedAt != null && post.updatedAt!.isAfter(post.createdAt) ? ' · 수정됨' : ''}',
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: tertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isOwnPost && isAuthenticated)
                        Padding(
                          padding: const EdgeInsets.only(left: 64),
                          child: TextButton.icon(
                            onPressed: (isFollowLoading || isAuthorBlocked)
                                ? null
                                : onToggleFollowAuthor,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: GBTSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GBTSpacing.radiusSm,
                                ),
                              ),
                            ),
                            icon: Icon(
                              (followStatus?.following ?? false)
                                  ? Icons.check_rounded
                                  : Icons.person_add_alt_1_outlined,
                              size: 18,
                            ),
                            label: Text(
                              isAuthorBlocked
                                  ? '차단됨'
                                  : (followStatus?.following ?? false)
                                  ? '팔로잉'
                                  : '팔로우',
                              style: GBTTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: GBTSpacing.sm),
                      Divider(color: borderColor),
                      const SizedBox(height: GBTSpacing.md),
                      if (post.moderationStatus ==
                          ContentModerationStatus.quarantined)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(GBTSpacing.md),
                          decoration: BoxDecoration(
                            color: GBTColors.warningLight,
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: GBTColors.warningDark,
                                size: GBTSpacing.iconSm,
                              ),
                              const SizedBox(width: GBTSpacing.sm),
                              Expanded(
                                child: Text(
                                  '이 콘텐츠는 현재 검토 중입니다.',
                                  style: GBTTypography.bodySmall.copyWith(
                                    color: GBTColors.warningDark,
                                  ),
                                ),
                              ),
                              if (isOwnPost)
                                TextButton(
                                  onPressed: onAppealPost,
                                  child: const Text('이의제기'),
                                ),
                            ],
                          ),
                        ),
                      if (post.moderationStatus ==
                          ContentModerationStatus.quarantined)
                        const SizedBox(height: GBTSpacing.md),
                      if (contentText.isNotEmpty)
                        Column(
                          key: const ValueKey<String>('field-note-body'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GBTLinkifiedText(
                              contentText,
                              style: GBTTypography.bodyLarge.copyWith(
                                height: 1.65,
                                color: secondaryColor,
                              ),
                              selectable: true,
                            ),
                            CommunityTranslationPanel(
                              contentId: 'post:${post.id}',
                              text: contentText,
                              textStyle: GBTTypography.bodyLarge.copyWith(
                                height: 1.65,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      if (mergedImageUrls.isNotEmpty) ...[
                        const SizedBox(height: GBTSpacing.md),
                        // EN: Horizontal swipeable image carousel (Twitter-style).
                        // KO: 가로로 넘기는 이미지 캐러셀 (트위터 스타일).
                        _ImageCarousel(
                          imageUrls: mergedImageUrls,
                          onTapImage: (index) => _showFullScreenImage(
                            context,
                            mergedImageUrls,
                            index,
                          ),
                        ),
                      ],
                      const SizedBox(height: GBTSpacing.md),
                      // EN: Stats bar — social proof context (like count) before actions
                      // KO: 액션 버튼 전에 소셜 증거(좋아요 수)를 보여주는 통계 바
                      if (likeCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 13,
                                color: GBTColors.favorite.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '좋아요 $likeCount명이 공감했어요',
                                style: GBTTypography.labelSmall.copyWith(
                                  color: secondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // EN: Borderless document actions wrap on narrow screens.
                      // KO: 보더리스 문서 액션은 좁은 화면에서 줄바꿈합니다.
                      Semantics(
                        key: const ValueKey<String>('field-note-actions'),
                        label:
                            '좋아요 $likeCount개, '
                            '${isLiked ? "좋아요 누른 상태" : "좋아요 안 누른 상태"}, '
                            '댓글 $commentCountLabel개, '
                            '${isBookmarked ? "북마크됨" : "북마크 안 됨"}',
                        child: Wrap(
                          spacing: GBTSpacing.sm,
                          runSpacing: GBTSpacing.xs,
                          children: [
                            _TimelineActionButton(
                              icon: GBTActionIcons.comment,
                              label: '댓글 $commentCountLabel',
                              color: commentActionColor,
                              onTap: onFocusComment,
                            ),
                            _TimelineActionButton(
                              icon: isLiked
                                  ? GBTActionIcons.likeActive
                                  : GBTActionIcons.like,
                              label: '좋아요 ${_compactCountLabel(likeCount)}',
                              color: isLiked
                                  ? GBTColors.favorite
                                  : tertiaryColor,
                              isSelected: isLiked,
                              onTap: onToggleLike,
                            ),
                            _TimelineActionButton(
                              icon: isBookmarked
                                  ? GBTActionIcons.bookmarkActive
                                  : GBTActionIcons.bookmark,
                              label: isBookmarked ? '저장됨' : '저장',
                              color: isBookmarked
                                  ? (isDark
                                        ? GBTColors.darkPrimary
                                        : GBTColors.primary)
                                  : tertiaryColor,
                              isSelected: isBookmarked,
                              onTap: onToggleBookmark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.md),
                      const Divider(),
                      const SizedBox(height: GBTSpacing.md),
                    ], // Column children
                  ), // Column
                ), // Padding (post content)
                // EN: Comment section header — aligned to page horizontal margin.
                // KO: 댓글 헤더 — 페이지 수평 마진에 맞춤.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.pageHorizontal,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: isDark
                            ? GBTColors.darkTextSecondary
                            : GBTColors.textSecondary,
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      Text(
                        '댓글 $commentCountLabel개',
                        style: GBTTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                // EN: Comment list — full width, no horizontal padding.
                // KO: 댓글 목록 — 좌우 패딩 없이 전체 너비.
                _PostCommentsSection(
                  key: const ValueKey<String>('field-note-comment-log'),
                  state: commentsState,
                  postAuthorId: post.authorId,
                  onTapAuthor: onTapAuthor,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  isAuthenticated: isAuthenticated,
                  onEditComment: onEditComment,
                  onDeleteComment: onDeleteComment,
                  onReportComment: onReportComment,
                  onOpenCommentThread: onOpenCommentThread,
                  onReplyToComment: onReplyToComment,
                ),
              ],
            ),
          ),
        ),
        // EN: Comment composer bar with optional reply context banner.
        // KO: 답글 컨텍스트 배너가 포함된 댓글 작성 바.
        if (isAuthenticated)
          _CommentComposerBar(
            key: const ValueKey<String>('field-note-composer'),
            commentController: commentController,
            commentFocusNode: commentFocusNode,
            isSubmitting: isSubmitting,
            replyTarget: replyTarget,
            onCancelReply: onCancelReply,
            onSubmit: onSubmitComment,
            isDark: isDark,
            borderColor: borderColor,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: secondaryColor),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: Text(
                      '댓글을 작성하려면 로그인하세요.',
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PostCommentsSection extends StatefulWidget {
  const _PostCommentsSection({
    super.key,
    required this.state,
    required this.postAuthorId,
    required this.onTapAuthor,
    required this.currentUserId,
    required this.isAdmin,
    required this.isAuthenticated,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onReportComment,
    required this.onOpenCommentThread,
    required this.onReplyToComment,
  });

  final AsyncValue<List<PostComment>> state;
  final String postAuthorId;
  final ValueChanged<String> onTapAuthor;
  final String? currentUserId;
  final bool isAdmin;
  final bool isAuthenticated;
  final ValueChanged<PostComment> onEditComment;
  final ValueChanged<PostComment> onDeleteComment;
  final ValueChanged<PostComment> onReportComment;
  final ValueChanged<PostComment> onOpenCommentThread;
  final ValueChanged<PostComment> onReplyToComment;

  @override
  State<_PostCommentsSection> createState() => _PostCommentsSectionState();
}

class _PostCommentsSectionState extends State<_PostCommentsSection> {
  _CommentSort _sort = _CommentSort.latest;

  // EN: Memoization fields to avoid rebuilding the thread tree on every repaint.
  // KO: 매 리페인트 시 스레드 트리 재구성을 방지하는 메모이제이션 필드.
  List<PostComment>? _cachedComments;
  _CommentSort? _cachedSort;
  List<_CommentThread> _cachedThreads = const [];

  bool _isDeletedRootComment(PostComment comment) {
    return _isDeletedCommentPlaceholder(comment.content);
  }

  List<_CommentThread> _buildThreads(List<PostComment> comments) {
    // EN: Return cached result if inputs are unchanged.
    // KO: 입력값이 동일하면 캐시된 결과를 반환합니다.
    if (identical(comments, _cachedComments) && _sort == _cachedSort) {
      return _cachedThreads;
    }
    // EN: Build id→comment lookup for ancestor traversal.
    // KO: 조상 탐색을 위한 id→댓글 조회 맵 구성.
    final lookup = <String, PostComment>{for (final c in comments) c.id: c};
    final roots = <String, PostComment>{
      for (final comment in comments)
        if (comment.parentCommentId == null) comment.id: comment,
    };

    // EN: Resolve a reply thread id; if parent is missing, use missing parent id.
    // KO: 답글 스레드 id를 계산하고, 부모가 없으면 누락된 부모 id를 사용합니다.
    String resolveThreadId(PostComment comment) {
      var cursor = comment;
      final visited = <String>{comment.id};
      while (cursor.parentCommentId != null) {
        final parentId = cursor.parentCommentId!;
        final parent = lookup[parentId];
        if (parent == null) {
          return parentId;
        }
        if (!visited.add(parent.id)) {
          return parent.id;
        }
        cursor = parent;
      }
      return cursor.id;
    }

    // EN: Group replies by thread and track sort anchors for deleted-root placeholders.
    // KO: 답글을 스레드별로 묶고 삭제된 루트 플레이스홀더 정렬 기준 시각을 계산합니다.
    final repliesByThread = <String, List<PostComment>>{};
    final deletedRootAnchor = <String, DateTime>{};
    for (final comment in comments) {
      if (comment.parentCommentId != null) {
        final threadId = resolveThreadId(comment);
        repliesByThread.putIfAbsent(threadId, () => []).add(comment);
        if (!roots.containsKey(threadId)) {
          final currentAnchor = deletedRootAnchor[threadId];
          if (currentAnchor == null ||
              comment.createdAt.isBefore(currentAnchor)) {
            deletedRootAnchor[threadId] = comment.createdAt;
          }
        }
      }
    }

    for (final replies in repliesByThread.values) {
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final threads = <_CommentThread>[
      for (final root in roots.values) ...[
        if (_isDeletedRootComment(root) &&
            (repliesByThread[root.id] ?? const <PostComment>[]).isEmpty)
          // EN: Hide deleted root traces once all child replies are gone.
          // KO: 모든 하위 답글이 사라지면 삭제 루트 흔적도 숨깁니다.
          ...[]
        else
          _CommentThread(
            id: root.id,
            sortAnchor: root.createdAt,
            rootComment: _isDeletedRootComment(root) ? null : root,
            replies: repliesByThread[root.id] ?? const <PostComment>[],
          ),
      ],
      for (final entry in repliesByThread.entries)
        if (!roots.containsKey(entry.key) && entry.value.isNotEmpty)
          _CommentThread(
            id: entry.key,
            sortAnchor:
                deletedRootAnchor[entry.key] ?? entry.value.first.createdAt,
            replies: entry.value,
          ),
    ];

    threads.sort((a, b) {
      if (_sort == _CommentSort.latest) {
        return b.sortAnchor.compareTo(a.sortAnchor);
      }
      return a.sortAnchor.compareTo(b.sortAnchor);
    });

    // EN: Store computed result for memoization.
    // KO: 메모이제이션을 위해 계산된 결과를 저장합니다.
    _cachedComments = comments;
    _cachedSort = _sort;
    _cachedThreads = threads;

    return threads;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;

    return widget.state.when(
      loading: () => const GBTLoading(message: '댓글을 불러오는 중...'),
      error: (error, _) {
        final message = error is Failure ? error.userMessage : '댓글을 불러오지 못했어요';
        return GBTErrorState(message: message);
      },
      data: (comments) {
        if (comments.isEmpty) {
          // EN: Motivational empty state CTA to encourage first comment.
          // KO: 첫 댓글을 유도하는 동기부여 빈 상태 CTA.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? GBTColors.darkSurfaceVariant
                          : GBTColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 26,
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.md),
                  Text(
                    '아직 댓글이 없어요',
                    style: GBTTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? GBTColors.darkTextPrimary
                          : GBTColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    '첫 번째로 생각을 남겨보세요!',
                    style: GBTTypography.bodySmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final threads = _buildThreads(comments);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EN: Header row — sort pill buttons, right-aligned.
            // KO: 헤더 행 — 정렬 필 버튼, 오른쪽 정렬.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                0,
                GBTSpacing.pageHorizontal,
                GBTSpacing.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SegmentedButton<_CommentSort>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _CommentSort.latest,
                      label: Text('최신순'),
                    ),
                    ButtonSegment(
                      value: _CommentSort.oldest,
                      label: Text('등록순'),
                    ),
                  ],
                  selected: {_sort},
                  onSelectionChanged: (selection) => setState(() {
                    _sort = selection.single;
                  }),
                ),
              ),
            ),
            // EN: Comment list separated by dividers.
            // KO: 구분선으로 구분된 댓글 목록.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < threads.length; i++) ...[
                    if (threads[i].isDeletedPlaceholder)
                      _DeletedRootCommentItem(
                        key: ValueKey<String>(
                          'deleted-thread-${threads[i].id}',
                        ),
                        threadId: threads[i].id,
                        replies: threads[i].replies,
                        postAuthorId: widget.postAuthorId,
                        onTapAuthor: widget.onTapAuthor,
                        currentUserId: widget.currentUserId,
                        isAdmin: widget.isAdmin,
                        canReport: widget.isAuthenticated,
                        onEdit: widget.onEditComment,
                        onDelete: widget.onDeleteComment,
                        onReport: widget.onReportComment,
                        onReply: widget.onReplyToComment,
                      )
                    else
                      _CommentItem(
                        comment: threads[i].rootComment!,
                        replies: threads[i].replies,
                        postAuthorId: widget.postAuthorId,
                        onTapAuthor: widget.onTapAuthor,
                        canEdit:
                            widget.currentUserId ==
                            threads[i].rootComment!.authorId,
                        canDelete:
                            widget.currentUserId ==
                                threads[i].rootComment!.authorId ||
                            (widget.isAdmin && widget.currentUserId != null),
                        canReport: widget.isAuthenticated,
                        currentUserId: widget.currentUserId,
                        isAdmin: widget.isAdmin,
                        onEdit: widget.onEditComment,
                        onDelete: widget.onDeleteComment,
                        onReport: widget.onReportComment,
                        onReply: widget.onReplyToComment,
                      ),
                    if (i < threads.length - 1)
                      Divider(height: 1, thickness: 1, color: borderColor),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeletedRootCommentItem extends StatefulWidget {
  const _DeletedRootCommentItem({
    super.key,
    required this.threadId,
    required this.replies,
    required this.postAuthorId,
    required this.onTapAuthor,
    required this.currentUserId,
    required this.isAdmin,
    required this.canReport,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onReply,
  });

  final String threadId;
  final List<PostComment> replies;
  final String postAuthorId;
  final ValueChanged<String> onTapAuthor;
  final String? currentUserId;
  final bool isAdmin;
  final bool canReport;
  final ValueChanged<PostComment> onEdit;
  final ValueChanged<PostComment> onDelete;
  final ValueChanged<PostComment> onReport;
  final ValueChanged<PostComment> onReply;

  @override
  State<_DeletedRootCommentItem> createState() =>
      _DeletedRootCommentItemState();
}

class _DeletedRootCommentItemState extends State<_DeletedRootCommentItem> {
  bool _repliesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final replyBgColor = isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.5)
        : GBTColors.surfaceVariant.withValues(alpha: 0.6);
    final parentLookup = <String, PostComment>{
      for (final reply in widget.replies) reply.id: reply,
    };
    final replyCount = widget.replies.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // EN: Placeholder row for a deleted root comment.
        // KO: 삭제된 최상위 댓글 자리 표시 행입니다.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.sm2,
            GBTSpacing.md,
            GBTSpacing.sm2,
          ),
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 16, color: tertiaryColor),
              const SizedBox(width: GBTSpacing.xs),
              Text(
                '삭제된 댓글입니다',
                style: GBTTypography.bodySmall.copyWith(color: tertiaryColor),
              ),
            ],
          ),
        ),
        if (replyCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md + 24,
              0,
              GBTSpacing.md,
              GBTSpacing.xs,
            ),
            child: _ReplyActionButton(
              label: _repliesExpanded ? '답글 숨기기' : '답글 $replyCount개 보기',
              color: primaryColor,
              icon: _repliesExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              onTap: () => setState(() => _repliesExpanded = !_repliesExpanded),
            ),
          ),
        if (_repliesExpanded && widget.replies.isNotEmpty)
          Container(
            color: replyBgColor,
            child: Column(
              children: [
                for (var i = 0; i < widget.replies.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: GBTSpacing.xl + GBTSpacing.sm,
                      color: borderColor.withValues(alpha: 0.6),
                    ),
                  _ReplyItem(
                    reply: widget.replies[i],
                    postAuthorId: widget.postAuthorId,
                    rootCommentId: widget.threadId,
                    rootAuthorName: null,
                    parentLookup: parentLookup,
                    onTapAuthor: widget.onTapAuthor,
                    canEdit: widget.currentUserId == widget.replies[i].authorId,
                    canDelete:
                        widget.currentUserId == widget.replies[i].authorId ||
                        (widget.isAdmin && widget.currentUserId != null),
                    canReport: widget.canReport,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                    onReport: widget.onReport,
                    onReply: widget.onReply,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ================================================
// EN: Comment item with inline expandable replies.
// KO: 인라인 확장 대댓글을 지원하는 댓글 아이템.
// ================================================
class _CommentItem extends ConsumerStatefulWidget {
  const _CommentItem({
    required this.comment,
    required this.replies,
    required this.postAuthorId,
    required this.onTapAuthor,
    required this.canEdit,
    required this.canDelete,
    required this.canReport,
    required this.currentUserId,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onReply,
  });

  final PostComment comment;
  final List<PostComment> replies;
  final String postAuthorId;
  final ValueChanged<String> onTapAuthor;
  final bool canEdit;
  final bool canDelete;
  final bool canReport;
  final String? currentUserId;
  final bool isAdmin;
  final ValueChanged<PostComment> onEdit;
  final ValueChanged<PostComment> onDelete;
  final ValueChanged<PostComment> onReport;
  final ValueChanged<PostComment> onReply;

  @override
  ConsumerState<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<_CommentItem> {
  bool _repliesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final contentColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final replyBgColor = isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.5)
        : GBTColors.surfaceVariant.withValues(alpha: 0.6);

    final comment = widget.comment;
    final authorLabel = comment.authorName?.isNotEmpty == true
        ? comment.authorName!
        : '익명';
    final avatarUrl = comment.authorAvatarUrl?.isNotEmpty == true
        ? comment.authorAvatarUrl
        : null;
    final commentAuthorTitleItem = ref
        .watch(userActiveTitleProvider(comment.authorId))
        .valueOrNull;
    final isEdited =
        comment.updatedAt != null &&
        comment.updatedAt!.isAfter(comment.createdAt);
    final isPostAuthor = comment.authorId == widget.postAuthorId;
    // EN: Prefer live replies from the flat list; fall back to replyCount from API.
    // KO: 플랫 목록의 실제 답글을 우선 사용하고, 없으면 API의 replyCount를 사용합니다.
    final liveReplyCount = widget.replies.length;
    final apiReplyCount = comment.replyCount ?? 0;
    final replyCount = liveReplyCount > 0 ? liveReplyCount : apiReplyCount;
    final canReply = _canReplyToComment(comment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // EN: Root comment body.
        // KO: 최상위 댓글 본문.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.sm2,
            GBTSpacing.xs,
            GBTSpacing.sm2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                url: avatarUrl,
                radius: 15,
                semanticLabel: '$authorLabel 프로필 사진',
                onTap: () => widget.onTapAuthor(comment.authorId),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EN: Author row with name, badges, time, menu — always right-aligned.
                    // KO: 이름, 뱃지, 시간, 메뉴 행 — 메뉴 버튼 항상 오른쪽 끝.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: GBTSpacing.xs,
                            runSpacing: 0,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    widget.onTapAuthor(comment.authorId),
                                child: Text(
                                  authorLabel,
                                  style: GBTTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: contentColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (commentAuthorTitleItem?.hasTitle == true)
                                ActiveTitleBadge.fromActiveItem(
                                  commentAuthorTitleItem!,
                                ),
                              if (isPostAuthor)
                                _AuthorBadge(color: primaryColor),
                              Text(
                                comment.timeAgoLabel,
                                style: GBTTypography.labelSmall.copyWith(
                                  color: tertiaryColor,
                                ),
                              ),
                              if (isEdited)
                                Text(
                                  '(수정)',
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: tertiaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _CommentMenuButton(
                          canEdit: widget.canEdit,
                          canDelete: widget.canDelete,
                          canReport: widget.canReport,
                          tertiaryColor: tertiaryColor,
                          onEdit: () => widget.onEdit(comment),
                          onDelete: () => widget.onDelete(comment),
                          onReport: () => widget.onReport(comment),
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.xxs),
                    // EN: Comment content.
                    // KO: 댓글 내용.
                    GBTLinkifiedText(
                      _displayCommentContent(comment.content),
                      style: GBTTypography.bodyMedium.copyWith(
                        color: contentColor,
                        height: 1.46,
                      ),
                    ),
                    if (!_isDeletedCommentPlaceholder(comment.content))
                      CommunityTranslationPanel(
                        contentId: 'comment:${comment.id}',
                        text: comment.content,
                        textStyle: GBTTypography.bodyMedium.copyWith(
                          color: contentColor,
                          height: 1.46,
                        ),
                        compact: true,
                      ),
                    const SizedBox(height: GBTSpacing.sm),
                    // EN: Action row — reply button + expand-replies toggle.
                    // KO: 액션 행 — 답글 버튼 + 답글 펼치기 토글.
                    Wrap(
                      spacing: GBTSpacing.sm,
                      runSpacing: GBTSpacing.xs,
                      children: [
                        if (canReply)
                          _ReplyActionButton(
                            label: '답글',
                            color: secondaryColor,
                            onTap: () => widget.onReply(comment),
                          ),
                        if (replyCount > 0) ...[
                          _ReplyActionButton(
                            label: _repliesExpanded
                                ? '답글 숨기기'
                                : '답글 $replyCount개 보기',
                            color: primaryColor,
                            icon: _repliesExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            onTap: () => setState(
                              () => _repliesExpanded = !_repliesExpanded,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // EN: Inline replies, shown when expanded.
        // KO: 펼쳐졌을 때 표시되는 인라인 대댓글.
        if (_repliesExpanded && widget.replies.isNotEmpty)
          Container(
            color: replyBgColor,
            child: Column(
              children: [
                for (var i = 0; i < widget.replies.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: GBTSpacing.xl + GBTSpacing.sm,
                      color: borderColor.withValues(alpha: 0.6),
                    ),
                  _ReplyItem(
                    reply: widget.replies[i],
                    postAuthorId: widget.postAuthorId,
                    rootCommentId: widget.comment.id,
                    rootAuthorName: authorLabel,
                    parentLookup: {for (final r in widget.replies) r.id: r},
                    onTapAuthor: widget.onTapAuthor,
                    canEdit: widget.currentUserId == widget.replies[i].authorId,
                    canDelete:
                        widget.currentUserId == widget.replies[i].authorId ||
                        (widget.isAdmin && widget.currentUserId != null),
                    canReport: widget.canReport,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                    onReport: widget.onReport,
                    onReply: widget.onReply,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ================================================
// EN: Reply item (대댓글) — indented, left accent bar.
// KO: 대댓글 아이템 — 들여쓰기, 왼쪽 강조 바.
// ================================================
class _ReplyItem extends StatelessWidget {
  const _ReplyItem({
    required this.reply,
    required this.postAuthorId,
    required this.rootCommentId,
    required this.rootAuthorName,
    required this.parentLookup,
    required this.onTapAuthor,
    required this.canEdit,
    required this.canDelete,
    required this.canReport,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onReply,
  });

  final PostComment reply;
  final String postAuthorId;
  // EN: ID of the root comment that this reply thread belongs to.
  // KO: 이 답글 스레드가 속한 최상위 댓글의 ID.
  final String rootCommentId;
  // EN: Root author name for direct replies to the root comment.
  // KO: 최상위 댓글 직접 답글의 @멘션 표시를 위한 루트 작성자 이름.
  final String? rootAuthorName;
  // EN: Lookup map of id→PostComment for replies in this thread.
  // KO: 이 스레드 내 답글의 id→PostComment 조회 맵.
  final Map<String, PostComment> parentLookup;
  final ValueChanged<String> onTapAuthor;
  final bool canEdit;
  final bool canDelete;
  final bool canReport;
  final ValueChanged<PostComment> onEdit;
  final ValueChanged<PostComment> onDelete;
  final ValueChanged<PostComment> onReport;
  final ValueChanged<PostComment> onReply;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final contentColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    // EN: Reply hierarchy indent uses a quiet border color, not a brand accent.
    // KO: 답글 계층 들여쓰기는 브랜드 강조색이 아닌 조용한 보더 컬러를 사용합니다.
    final accentBarColor = isDark ? GBTColors.darkBorder : GBTColors.border;

    final authorLabel = _isDeletedCommentPlaceholder(reply.content)
        ? _deletedCommentPlaceholderLegacy
        : (reply.authorName?.isNotEmpty == true ? reply.authorName! : '익명');
    final avatarUrl = reply.authorAvatarUrl?.isNotEmpty == true
        ? reply.authorAvatarUrl
        : null;
    final isEdited =
        reply.updatedAt != null && reply.updatedAt!.isAfter(reply.createdAt);
    final isPostAuthor = reply.authorId == postAuthorId;
    final isDeletedPlaceholder = _isDeletedCommentPlaceholder(reply.content);
    final effectiveCanEdit = canEdit && !isDeletedPlaceholder;
    final effectiveCanDelete = canDelete && !isDeletedPlaceholder;
    final effectiveCanReport = canReport && !isDeletedPlaceholder;
    final canReply = _canReplyToComment(reply);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // EN: Left indent spacer aligned with parent avatar.
          // KO: 부모 아바타에 맞춘 왼쪽 들여쓰기 스페이서.
          const SizedBox(width: GBTSpacing.md),
          // EN: Vertical accent bar indicating reply hierarchy.
          // KO: 답글 계층을 나타내는 수직 강조 바.
          Container(
            width: 2,
            margin: const EdgeInsets.symmetric(vertical: GBTSpacing.sm2),
            decoration: BoxDecoration(
              color: accentBarColor,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: GBTSpacing.xs,
                top: GBTSpacing.sm2,
                bottom: GBTSpacing.sm2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(
                    url: avatarUrl,
                    radius: 12,
                    semanticLabel: '$authorLabel 프로필 사진',
                    onTap: isDeletedPlaceholder
                        ? null
                        : () => onTapAuthor(reply.authorId),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: GBTSpacing.xs,
                                runSpacing: 0,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: isDeletedPlaceholder
                                        ? null
                                        : () => onTapAuthor(reply.authorId),
                                    child: Text(
                                      authorLabel,
                                      style: GBTTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: contentColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPostAuthor)
                                    _AuthorBadge(
                                      color: primaryColor,
                                      small: true,
                                    ),
                                  Text(
                                    reply.timeAgoLabel,
                                    style: GBTTypography.labelSmall.copyWith(
                                      color: tertiaryColor,
                                    ),
                                  ),
                                  if (isEdited && !isDeletedPlaceholder)
                                    Text(
                                      '(수정)',
                                      style: GBTTypography.labelSmall.copyWith(
                                        color: tertiaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _CommentMenuButton(
                              canEdit: effectiveCanEdit,
                              canDelete: effectiveCanDelete,
                              canReport: effectiveCanReport,
                              tertiaryColor: tertiaryColor,
                              iconSize: 16,
                              onEdit: () => onEdit(reply),
                              onDelete: () => onDelete(reply),
                              onReport: () => onReport(reply),
                            ),
                          ],
                        ),
                        const SizedBox(height: GBTSpacing.xxs),
                        // EN: Show @mention when this is a reply-of-reply (parent is not the root).
                        // KO: 대댓글인 경우(부모가 루트 아님) @멘션을 표시합니다.
                        Builder(
                          builder: (context) {
                            final directParentId = reply.parentCommentId;
                            if (isDeletedPlaceholder) {
                              return Text(
                                _deletedCommentPlaceholderLegacy,
                                style: GBTTypography.bodySmall.copyWith(
                                  color: tertiaryColor,
                                  height: 1.45,
                                ),
                              );
                            }
                            String? parentAuthor;
                            if (directParentId != null) {
                              if (directParentId == rootCommentId) {
                                parentAuthor =
                                    rootAuthorName?.trim().isNotEmpty == true
                                    ? rootAuthorName
                                    : null;
                              } else {
                                final resolvedAuthor =
                                    parentLookup[directParentId]?.authorName;
                                parentAuthor =
                                    resolvedAuthor?.trim().isNotEmpty == true
                                    ? resolvedAuthor
                                    : null;
                              }
                            }
                            if (parentAuthor != null) {
                              return GBTLinkifiedText(
                                _displayCommentContent(reply.content),
                                leadingText: '@$parentAuthor ',
                                leadingStyle: GBTTypography.bodySmall.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                                style: GBTTypography.bodySmall.copyWith(
                                  color: contentColor,
                                  height: 1.45,
                                ),
                              );
                            }
                            return GBTLinkifiedText(
                              _displayCommentContent(reply.content),
                              style: GBTTypography.bodySmall.copyWith(
                                color: contentColor,
                                height: 1.45,
                              ),
                            );
                          },
                        ),
                        if (!isDeletedPlaceholder)
                          CommunityTranslationPanel(
                            contentId: 'comment:${reply.id}',
                            text: reply.content,
                            textStyle: GBTTypography.bodySmall.copyWith(
                              color: contentColor,
                              height: 1.45,
                            ),
                            compact: true,
                          ),
                        if (canReply) ...[
                          const SizedBox(height: GBTSpacing.xs),
                          _ReplyActionButton(
                            label: '답글',
                            color: secondaryColor,
                            onTap: () => onReply(reply),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================
// EN: Shared helper widgets for comment UI.
// KO: 댓글 UI 공통 헬퍼 위젯.
// ================================================

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge({required this.color, this.small = false});
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : GBTSpacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Text(
        '글쓴이',
        style: GBTTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: small ? 10 : null,
        ),
      ),
    );
  }
}

class _ReplyActionButton extends StatelessWidget {
  const _ReplyActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
    );
    return icon == null
        ? TextButton(onPressed: onTap, style: style, child: Text(label))
        : TextButton.icon(
            onPressed: onTap,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

class _CommentMenuButton extends StatelessWidget {
  const _CommentMenuButton({
    required this.canEdit,
    required this.canDelete,
    required this.canReport,
    required this.tertiaryColor,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    this.iconSize = 18,
  });
  final bool canEdit;
  final bool canDelete;
  final bool canReport;
  final Color tertiaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (!canEdit && !canDelete && !canReport) return const SizedBox.shrink();

    if (canEdit || canDelete) {
      return IconButton(
        tooltip: '댓글 관리',
        icon: Icon(Icons.more_horiz, size: iconSize, color: tertiaryColor),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        splashRadius: 20,
        onPressed: () async {
          final action = await showGBTActionSheet<_CommentAction>(
            context: context,
            actions: [
              if (canEdit)
                const GBTActionSheetItem(
                  label: '수정',
                  value: _CommentAction.edit,
                  icon: Icons.edit_outlined,
                ),
              if (canDelete)
                GBTActionSheetItem(
                  label: canEdit ? '삭제' : '관리 삭제',
                  value: _CommentAction.delete,
                  icon: Icons.delete_outline,
                  isDestructive: true,
                ),
            ],
            cancelLabel: '취소',
          );
          if (action != null) {
            if (action == _CommentAction.edit) {
              onEdit();
            } else {
              onDelete();
            }
          }
        },
      );
    }

    return IconButton(
      tooltip: '댓글 옵션',
      icon: Icon(Icons.more_horiz, size: iconSize, color: tertiaryColor),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      splashRadius: 20,
      onPressed: () async {
        final action = await showGBTActionSheet<_CommentOtherAction>(
          context: context,
          actions: const [
            GBTActionSheetItem(
              label: '신고',
              value: _CommentOtherAction.report,
              icon: Icons.flag_outlined,
            ),
          ],
          cancelLabel: '취소',
        );
        if (action != null) {
          onReport();
        }
      },
    );
  }
}

// ================================================
// EN: Comment composer bar with reply context banner.
// KO: 답글 컨텍스트 배너가 포함된 댓글 작성 바.
// ================================================
class _CommentComposerBar extends StatefulWidget {
  const _CommentComposerBar({
    super.key,
    required this.commentController,
    required this.commentFocusNode,
    required this.isSubmitting,
    required this.replyTarget,
    required this.onCancelReply,
    required this.onSubmit,
    required this.isDark,
    required this.borderColor,
  });

  final TextEditingController commentController;
  final FocusNode commentFocusNode;
  final bool isSubmitting;
  final PostComment? replyTarget;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;
  final bool isDark;
  final Color borderColor;

  @override
  State<_CommentComposerBar> createState() => _CommentComposerBarState();
}

class _CommentComposerBarState extends State<_CommentComposerBar> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.commentFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.commentFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.commentFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isDark
        ? GBTColors.darkSurface
        : GBTColors.surface;
    final variantColor = widget.isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.6)
        : GBTColors.surfaceVariant;
    final primaryColor = widget.isDark
        ? GBTColors.darkPrimary
        : GBTColors.primary;
    final tertiaryColor = widget.isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final secondaryColor = widget.isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final focusColor = widget.isDark
        ? GBTColors.darkPrimary.withValues(alpha: 0.16)
        : GBTColors.primaryLight.withValues(alpha: 0.6);
    final bgColor = _isFocused ? focusColor : variantColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: widget.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EN: Reply context banner — slides in when replying.
            // KO: 답글 작성 시 슬라이드인되는 답글 컨텍스트 배너.
            AnimatedSize(
              duration: GBTAnimations.normal,
              curve: Curves.easeOutCubic,
              child: widget.replyTarget != null
                  ? Container(
                      color: variantColor,
                      padding: const EdgeInsets.fromLTRB(
                        GBTSpacing.md,
                        GBTSpacing.sm,
                        GBTSpacing.sm,
                        GBTSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(
                                GBTSpacing.radiusFull,
                              ),
                            ),
                          ),
                          const SizedBox(width: GBTSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.replyTarget!.authorName ?? '익명'}에게 답글',
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.replyTarget!.content,
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: secondaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onCancelReply,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: tertiaryColor,
                            ),
                            tooltip: '답글 취소',
                            padding: const EdgeInsets.all(GBTSpacing.xs),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // EN: Text input row.
            // KO: 텍스트 입력 행.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.commentController,
              builder: (context, value, _) {
                final canSubmit =
                    value.text.trim().isNotEmpty && !widget.isSubmitting;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                    vertical: GBTSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: GBTAnimations.fast,
                          curve: GBTAnimations.defaultCurve,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusLg,
                            ),
                            border: _isFocused
                                ? Border.all(
                                    color: primaryColor.withValues(alpha: 0.5),
                                    width: 1,
                                  )
                                : Border.all(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                          ),
                          child: TextField(
                            controller: widget.commentController,
                            focusNode: widget.commentFocusNode,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            style: GBTTypography.bodyMedium,
                            decoration: InputDecoration(
                              hintText: widget.replyTarget != null
                                  ? '답글 작성...'
                                  : '댓글 작성...',
                              hintStyle: GBTTypography.bodyMedium.copyWith(
                                color: tertiaryColor,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: GBTSpacing.md,
                                vertical: GBTSpacing.sm2,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      // EN: Send button — active when text is non-empty.
                      // KO: 텍스트 입력 시 활성화되는 전송 버튼.
                      AnimatedContainer(
                        duration: GBTAnimations.fast,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: canSubmit
                              ? primaryColor
                              : (widget.isDark
                                    ? GBTColors.darkSurfaceVariant
                                    : GBTColors.surfaceVariant),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: canSubmit ? widget.onSubmit : null,
                          padding: EdgeInsets.zero,
                          icon: widget.isSubmitting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: canSubmit
                                        ? Colors.white
                                        : tertiaryColor,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                  color: canSubmit
                                      ? Colors.white
                                      : tertiaryColor,
                                ),
                          tooltip: widget.replyTarget != null
                              ? '답글 등록'
                              : '댓글 등록',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineActionButton extends StatelessWidget {
  const _TimelineActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// EN: Whether this document action is currently active.
  /// KO: 현재 활성화된 문서 액션인지를 나타냅니다.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

String _compactCountLabel(int count) {
  if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}천';
  return count.toString();
}

class _CommentThreadNodeView extends StatelessWidget {
  const _CommentThreadNodeView({required this.node, this.depth = 0});

  final CommentThreadNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final comment = node.comment;
    final isDeletedPlaceholder = _isDeletedCommentPlaceholder(comment.content);
    final author = isDeletedPlaceholder
        ? _deletedCommentPlaceholderLegacy
        : (comment.authorName?.isNotEmpty == true ? comment.authorName! : '익명');
    final avatarUrl = comment.authorAvatarUrl?.isNotEmpty == true
        ? comment.authorAvatarUrl
        : null;
    final contentColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final accentColor = isDark
        ? GBTColors.darkPrimary.withValues(alpha: 0.4)
        : GBTColors.primary.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (depth > 0) ...[
            SizedBox(width: (depth * 16.0).clamp(0, 32)),
            Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(
                    url: avatarUrl,
                    radius: depth > 0 ? 11 : 13,
                    semanticLabel: '$author 프로필 사진',
                    onTap: null,
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              author,
                              style: GBTTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: contentColor,
                              ),
                            ),
                            const SizedBox(width: GBTSpacing.xs),
                            Text(
                              comment.timeAgoLabel,
                              style: GBTTypography.labelSmall.copyWith(
                                color: tertiaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        GBTLinkifiedText(
                          _displayCommentContent(comment.content),
                          style: GBTTypography.bodySmall.copyWith(
                            color: isDeletedPlaceholder
                                ? tertiaryColor
                                : contentColor,
                            height: 1.5,
                          ),
                        ),
                        if (!isDeletedPlaceholder)
                          CommunityTranslationPanel(
                            contentId: 'comment:${comment.id}',
                            text: comment.content,
                            textStyle: GBTTypography.bodySmall.copyWith(
                              color: contentColor,
                              height: 1.5,
                            ),
                            compact: true,
                          ),
                        if (node.replies.isNotEmpty) ...[
                          const SizedBox(height: GBTSpacing.sm),
                          ...node.replies.map(
                            (reply) => _CommentThreadNodeView(
                              node: reply,
                              depth: depth + 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isAdminRole({
  String? effectiveAccessLevel,
  String? accountRole,
  Map<String, List<String>>? projectRolesByProject,
  String? projectId,
  String? projectCode,
}) {
  return canModerateProjectCommunity(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
    projectRolesByProject: projectRolesByProject,
    projectId: projectId,
    projectCode: projectCode,
  );
}

// ========================================
// EN: Post detail skeleton loading state
// KO: 게시글 상세 스켈레톤 로딩 상태
// ========================================

/// EN: Skeleton placeholder for post detail while data loads.
/// KO: 데이터 로딩 중 게시글 상세의 스켈레톤 플레이스홀더.
class _PostDetailSkeleton extends StatelessWidget {
  const _PostDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: GBTSpacing.paddingPage,
      children: [
        // EN: Author row — avatar + name + timestamp
        // KO: 작성자 행 — 아바타 + 이름 + 타임스탬프
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GBTShimmerContainer(
              width: 44,
              height: 44,
              borderRadius: GBTSpacing.radiusFull,
            ),
            const SizedBox(width: GBTSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GBTShimmerContainer(width: 100, height: 13),
                const SizedBox(height: GBTSpacing.xs),
                GBTShimmerContainer(width: 200, height: 20),
              ],
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.md),
        // EN: Body text skeleton
        // KO: 본문 텍스트 스켈레톤
        GBTShimmerContainer(width: double.infinity, height: 15),
        const SizedBox(height: GBTSpacing.xs),
        GBTShimmerContainer(width: double.infinity, height: 15),
        const SizedBox(height: GBTSpacing.xs),
        GBTShimmerContainer(width: 260, height: 15),
        const SizedBox(height: GBTSpacing.xs),
        GBTShimmerContainer(width: double.infinity, height: 15),
        const SizedBox(height: GBTSpacing.xs),
        GBTShimmerContainer(width: 180, height: 15),
        const SizedBox(height: GBTSpacing.md),
        // EN: Image placeholder skeleton (16:9)
        // KO: 이미지 플레이스홀더 스켈레톤 (16:9)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GBTShimmerContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: GBTSpacing.radiusMd,
          ),
        ),
        const SizedBox(height: GBTSpacing.md),
        // EN: Action bar skeleton
        // KO: 액션 바 스켈레톤
        Row(
          children: [
            Expanded(
              child: GBTShimmerContainer(width: double.infinity, height: 36),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: GBTShimmerContainer(width: double.infinity, height: 36),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: GBTShimmerContainer(width: double.infinity, height: 36),
            ),
          ],
        ),
      ],
    );
  }
}

/// EN: Twitter-style horizontal swipeable image carousel with dot indicator.
/// KO: 점 인디케이터가 있는 트위터 스타일 가로 스와이프 이미지 캐러셀.
/// EN: Vertical image gallery — each image at its natural aspect ratio.
/// KO: 각 이미지를 원본 비율로 세로 나열하는 갤러리입니다.
class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.imageUrls, required this.onTapImage});

  final List<String> imageUrls;
  final ValueChanged<int> onTapImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(imageUrls.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < imageUrls.length - 1 ? GBTSpacing.sm : 0,
          ),
          child: Semantics(
            label: '첨부 이미지 ${index + 1}/${imageUrls.length}',
            hint: '탭하면 확대합니다',
            button: true,
            child: GestureDetector(
              onTap: () => onTapImage(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                child: ConstrainedBox(
                  // EN: Cap extreme portrait images (e.g. 9:16+) at 600px.
                  // KO: 극단적인 세로 이미지(9:16 이상)를 600px로 제한합니다.
                  constraints: const BoxConstraints(
                    minHeight: 60,
                    maxHeight: 600,
                  ),
                  child: GBTImage(
                    imageUrl: imageUrls[index],
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    semanticLabel: '첨부 이미지 ${index + 1}',
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// EN: Opens a full-screen zoomable image viewer.
/// KO: 풀스크린 확대 가능한 이미지 뷰어를 엽니다.
void _showFullScreenImage(
  BuildContext context,
  List<String> imageUrls,
  int initialIndex,
) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// EN: Download the currently displayed image to the device photo library.
  /// KO: 현재 표시 중인 이미지를 기기 사진 보관함에 저장합니다.
  Future<void> _downloadCurrentImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final url = resolveMediaUrl(widget.imageUrls[_currentIndex]);
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('사진 저장 권한이 필요합니다')));
          }
          return;
        }
      }

      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data!);
      await Gal.putImageBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지가 저장되었어요')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 저장에 실패했어요')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.imageUrls.length > 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: hasMultiple
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: GBTTypography.bodyLarge.copyWith(color: Colors.white),
              )
            : null,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: '이미지 저장',
              onPressed: _downloadCurrentImage,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: GBTImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.contain,
                  semanticLabel: '이미지 ${index + 1}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// EN: Normalize image URLs and remove duplicates while preserving order.
/// KO: 이미지 URL을 정규화하고 순서를 유지하며 중복을 제거합니다.
List<String> _normalizeImageUrls(Iterable<String> rawUrls) {
  final normalized = <String>[];
  final seen = <String>{};

  for (final rawUrl in rawUrls) {
    final url = resolveMediaUrl(rawUrl.trim());
    if (url.isEmpty) continue;
    if (seen.add(url)) {
      normalized.add(url);
    }
  }

  return normalized;
}

String _commentCountLabel(
  AsyncValue<List<PostComment>> state, {
  int? fallback,
}) {
  return state.maybeWhen(
    data: (comments) => comments.length.toString(),
    orElse: () => (fallback ?? 0).toString(),
  );
}

/// EN: Avatar widget with accessible touch targets.
/// KO: 접근 가능한 터치 타겟을 가진 아바타 위젯.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.radius,
    this.onTap,
    this.semanticLabel,
  });

  final String? url;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // EN: Use theme-aware placeholder colors.
    // KO: 테마 인식 플레이스홀더 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final iconColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(Icons.person, size: radius, color: iconColor),
    );

    final content = (url == null || url!.isEmpty)
        ? fallback
        : ClipOval(
            child: GBTImage(
              imageUrl: url!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel ?? '프로필 사진',
            ),
          );

    if (onTap == null) return content;

    // EN: Ensure minimum 48x48 touch target for accessibility.
    // KO: 접근성을 위해 최소 48x48 터치 타겟을 보장합니다.
    return Semantics(
      button: true,
      label: semanticLabel ?? '프로필 보기',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: GBTSpacing.touchTarget,
            minHeight: GBTSpacing.touchTarget,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
