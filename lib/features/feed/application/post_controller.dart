/// EN: Post detail and comment controllers.
/// KO: 게시글 상세 및 댓글 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../../projects/application/projects_controller.dart';
import '../domain/entities/feed_entities.dart';
import '../domain/repositories/feed_repository.dart';
import 'feed_repository_provider.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

bool _isNotFoundLikeFailure(Failure failure) {
  if (failure is NotFoundFailure) {
    return true;
  }
  return failure.code?.trim() == '404';
}

String? _normalizeProjectCode(Ref ref, String? rawReference) {
  final reference = rawReference?.trim() ?? '';
  if (reference.isEmpty) {
    return null;
  }

  final projects = ref.read(projectsControllerProvider).valueOrNull;
  if (projects != null) {
    for (final project in projects) {
      if (project.code == reference || project.id == reference) {
        return project.code.isNotEmpty ? project.code : project.id;
      }
    }
  }

  final selectedProjectId = ref.read(selectedProjectIdProvider);
  final selectedProjectKey = ref.read(selectedProjectKeyProvider);
  if (selectedProjectId == reference &&
      selectedProjectKey != null &&
      selectedProjectKey.isNotEmpty) {
    return selectedProjectKey;
  }

  if (_uuidPattern.hasMatch(reference)) {
    return null;
  }

  return reference;
}

List<String> _buildProjectCodeCandidates(
  Ref ref, {
  String? resolvedProjectCode,
  String? hintReference,
  String? detailProjectReference,
}) {
  final candidates = <String>[];
  final seen = <String>{};

  void addReference(String? raw) {
    final normalized = _normalizeProjectCode(ref, raw);
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    if (seen.add(normalized)) {
      candidates.add(normalized);
    }
  }

  addReference(resolvedProjectCode);
  addReference(hintReference);
  addReference(detailProjectReference);
  addReference(ref.read(selectedProjectKeyProvider));
  addReference(ref.read(selectedProjectIdProvider));

  final projects = ref.read(projectsControllerProvider).valueOrNull;
  if (projects != null) {
    for (final project in projects) {
      addReference(project.code);
    }
  }

  return candidates;
}

class PostDetailController extends StateNotifier<AsyncValue<PostDetail>> {
  PostDetailController(this._ref, this.postId, {String? projectCodeHint})
    : _projectCodeHint = projectCodeHint,
      super(const AsyncLoading());

  final Ref _ref;
  final String postId;
  final String? _projectCodeHint;
  String? _resolvedProjectCode;

  String? get resolvedProjectCode => _resolvedProjectCode;

  Future<void> load({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(feedRepositoryProvider.future);

    if (!mounted) {
      return;
    }

    final candidates = _buildProjectCodeCandidates(
      _ref,
      resolvedProjectCode: _resolvedProjectCode,
      hintReference: _projectCodeHint,
    );
    if (candidates.isEmpty) {
      state = AsyncError(
        const AuthFailure(
          'Project selection required',
          code: 'project_required',
        ),
        StackTrace.current,
      );
      return;
    }

    Failure? lastFailure;
    for (final projectCode in candidates) {
      final result = await repository.getPostDetail(
        projectCode: projectCode,
        postId: postId,
        forceRefresh: forceRefresh,
      );

      if (!mounted) {
        return;
      }

      if (result is Success<PostDetail>) {
        _resolvedProjectCode = projectCode;
        state = AsyncData(result.data);
        return;
      }
      if (result is Err<PostDetail>) {
        lastFailure = result.failure;
        if (!_isNotFoundLikeFailure(result.failure)) {
          state = AsyncError(result.failure, StackTrace.current);
          return;
        }
      }
    }

    state = AsyncError(
      lastFailure ??
          const UnknownFailure(
            'Unable to resolve post detail project',
            code: 'post_detail_project_unresolved',
          ),
      StackTrace.current,
    );
  }
}

class PostCommentsController
    extends StateNotifier<AsyncValue<List<PostComment>>> {
  PostCommentsController(this._ref, this.postId, {String? projectCodeHint})
    : _projectCodeHint = projectCodeHint,
      super(const AsyncLoading());

  final Ref _ref;
  final String postId;
  final String? _projectCodeHint;
  String? _resolvedProjectCode;

  Future<Result<T>> _runWithResolvedProject<T>({
    required Future<Result<T>> Function(String projectCode) request,
  }) async {
    final detailState = _ref.read(postDetailControllerProvider(postId));
    final detailProjectReference = detailState.maybeWhen(
      data: (post) => post.projectId,
      orElse: () => null,
    );
    final detailController = _ref.read(
      postDetailControllerProvider(postId).notifier,
    );

    final candidates = _buildProjectCodeCandidates(
      _ref,
      resolvedProjectCode:
          _resolvedProjectCode ?? detailController.resolvedProjectCode,
      hintReference: _projectCodeHint,
      detailProjectReference: detailProjectReference,
    );
    if (candidates.isEmpty) {
      return const Result.failure(
        AuthFailure('Project selection required', code: 'project_required'),
      );
    }

    Err<T>? lastError;
    for (final projectCode in candidates) {
      final result = await request(projectCode);
      if (result is Success<T>) {
        _resolvedProjectCode = projectCode;
        return result;
      }
      if (result is Err<T>) {
        lastError = result;
        if (!_isNotFoundLikeFailure(result.failure)) {
          return result;
        }
      }
    }

    if (lastError != null) {
      return Result.failure(lastError.failure);
    }

    return const Result.failure(
      UnknownFailure(
        'Unable to resolve post comments project',
        code: 'post_comments_project_unresolved',
      ),
    );
  }

  Future<void> _refreshCommentsFromServer(FeedRepository repository) async {
    final refreshed = await _runWithResolvedProject<List<PostComment>>(
      request: (projectCode) => repository.getPostComments(
        projectCode: projectCode,
        postId: postId,
        forceRefresh: true,
      ),
    );

    if (!mounted) {
      return;
    }
    if (refreshed is Success<List<PostComment>>) {
      state = AsyncData(refreshed.data);
    }
  }

  String? _projectRequiredMessageCode(Failure failure) {
    if (failure is AuthFailure && failure.code == 'project_required') {
      return failure.code;
    }
    return null;
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(feedRepositoryProvider.future);
    if (!mounted) {
      return;
    }
    final result = await _runWithResolvedProject<List<PostComment>>(
      request: (projectCode) => repository.getPostComments(
        projectCode: projectCode,
        postId: postId,
        forceRefresh: forceRefresh,
      ),
    );

    if (!mounted) {
      return;
    }
    if (result is Success<List<PostComment>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<PostComment>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  /// EN: Add a comment or reply. Pass [parentCommentId] to create a reply.
  /// KO: 댓글 또는 대댓글을 등록합니다. [parentCommentId]로 답글 대상 지정.
  Future<Result<PostComment>> addComment(
    String content, {
    String? parentCommentId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      const failure = ValidationFailure(
        'Comment content is empty',
        code: 'comment_content_empty',
      );
      if (mounted) {
        state = AsyncError(failure, StackTrace.current);
      }
      return const Result.failure(failure);
    }

    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await _runWithResolvedProject<PostComment>(
      request: (projectCode) => repository.createPostComment(
        projectCode: projectCode,
        postId: postId,
        content: trimmed,
        parentCommentId: parentCommentId,
      ),
    );

    if (!mounted) {
      return result;
    }
    if (result is Success<PostComment>) {
      final current = state.maybeWhen(
        data: (items) => items,
        orElse: () => <PostComment>[],
      );
      state = AsyncData([result.data, ...current]);
      await _refreshCommentsFromServer(repository);
    } else if (result is Err<PostComment>) {
      // EN: Keep existing data visible for project-required guard failures.
      // KO: 프로젝트 선택 가드 실패 시 기존 목록을 유지합니다.
      if (_projectRequiredMessageCode(result.failure) == null) {
        state = AsyncError(result.failure, StackTrace.current);
      }
    }

    return result;
  }

  Future<Result<PostComment>> updateComment(
    String commentId,
    String content,
  ) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      const failure = ValidationFailure(
        'Comment content is empty',
        code: 'comment_content_empty',
      );
      if (mounted) {
        state = AsyncError(failure, StackTrace.current);
      }
      return const Result.failure(failure);
    }

    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await _runWithResolvedProject<PostComment>(
      request: (projectCode) => repository.updatePostComment(
        projectCode: projectCode,
        postId: postId,
        commentId: commentId,
        content: trimmed,
      ),
    );

    if (!mounted) {
      return result;
    }
    if (result is Success<PostComment>) {
      final current = state.maybeWhen(
        data: (items) => items,
        orElse: () => <PostComment>[],
      );
      final updated = current
          .map((comment) => comment.id == commentId ? result.data : comment)
          .toList();
      state = AsyncData(updated);
    } else if (result is Err<PostComment>) {
      state = AsyncError(result.failure, StackTrace.current);
    }

    return result;
  }

  Future<Result<void>> deleteComment(String commentId) async {
    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await _runWithResolvedProject<void>(
      request: (projectCode) => repository.deletePostComment(
        projectCode: projectCode,
        postId: postId,
        commentId: commentId,
      ),
    );

    if (!mounted) {
      return result;
    }
    if (result is Success<void>) {
      final current = state.maybeWhen(
        data: (items) => items,
        orElse: () => <PostComment>[],
      );
      state = AsyncData(
        current.where((comment) => comment.id != commentId).toList(),
      );
      await _refreshCommentsFromServer(repository);
    } else if (result is Err<void>) {
      if (_projectRequiredMessageCode(result.failure) == null) {
        state = AsyncError(result.failure, StackTrace.current);
      }
    }

    return result;
  }
}

/// EN: Route-aware target for post detail/comments with optional project hint.
/// KO: 프로젝트 힌트를 포함할 수 있는 게시글 상세/댓글 라우트 타겟입니다.
class PostRouteTarget {
  const PostRouteTarget({required this.postId, this.projectCodeHint});

  final String postId;
  final String? projectCodeHint;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PostRouteTarget &&
            other.postId == postId &&
            other.projectCodeHint == projectCodeHint;
  }

  @override
  int get hashCode => Object.hash(postId, projectCodeHint);
}

/// EN: Route-aware post detail controller provider.
/// KO: 라우트 프로젝트 힌트를 반영하는 게시글 상세 컨트롤러 프로바이더.
final postDetailRouteControllerProvider = StateNotifierProvider.autoDispose
    .family<PostDetailController, AsyncValue<PostDetail>, PostRouteTarget>((
      ref,
      target,
    ) {
      return PostDetailController(
        ref,
        target.postId,
        projectCodeHint: target.projectCodeHint,
      )..load();
    });

/// EN: Route-aware post comments controller provider.
/// KO: 라우트 프로젝트 힌트를 반영하는 게시글 댓글 컨트롤러 프로바이더.
final postCommentsRouteControllerProvider = StateNotifierProvider.autoDispose
    .family<
      PostCommentsController,
      AsyncValue<List<PostComment>>,
      PostRouteTarget
    >((ref, target) {
      return PostCommentsController(
        ref,
        target.postId,
        projectCodeHint: target.projectCodeHint,
      )..load();
    });

/// EN: Post detail controller provider.
/// KO: 게시글 상세 컨트롤러 프로바이더.
final postDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<PostDetailController, AsyncValue<PostDetail>, String>((
      ref,
      postId,
    ) {
      return PostDetailController(ref, postId)..load();
    });

/// EN: Post comments controller provider.
/// KO: 게시글 댓글 컨트롤러 프로바이더.
final postCommentsControllerProvider = StateNotifierProvider.autoDispose
    .family<PostCommentsController, AsyncValue<List<PostComment>>, String>((
      ref,
      postId,
    ) {
      return PostCommentsController(ref, postId)..load();
    });
