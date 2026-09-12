/// EN: Community post edit page.
/// KO: 커뮤니티 게시글 수정 페이지.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/core_providers.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/image_url_extractor.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/feed_controller.dart';
import '../../domain/entities/feed_entities.dart';
import '../../../projects/presentation/widgets/project_selector.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../uploads/application/uploads_controller.dart';
import '../../../uploads/domain/entities/upload_entity.dart';
import '../../../uploads/utils/webp_image_converter.dart';
import '../widgets/post_compose_components.dart';

/// EN: Community post edit page widget.
/// KO: 커뮤니티 게시글 수정 페이지 위젯.
class PostEditPage extends ConsumerStatefulWidget {
  const PostEditPage({super.key, required this.post});

  final PostDetail post;

  @override
  ConsumerState<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends ConsumerState<PostEditPage> {
  static const int _maxTitleLength = 60;
  static const int _maxContentLength = 3000;
  static const int _maxImageCount = 6;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  final List<String> _existingImageUrls = [];
  final List<String> _selectedTags = [];
  final List<String> _topicOptions = <String>[];
  final List<String> _tagSuggestions = <String>[];
  late final PostComposeAutosaveConfig _autosaveConfig;
  late final PostComposeAutosaveController _autosaveController;
  late final String _initialTitle;
  late final String _initialContent;
  late final List<String> _initialImageUrls;
  late final String _editProjectCode;
  late final String? _initialTopic;
  late final List<String> _initialTags;
  bool _isSubmitting = false;
  bool _isTaxonomyLoading = false;
  bool _taxonomyLoadFailed = false;
  Failure? _taxonomyFailure;
  String? _errorMessage;
  String? _selectedTopic;
  bool _lastCanSubmit = false;
  bool _lastHasDraft = false;

  String get _draftStorageKey => 'feed_post_edit_draft_v1_${widget.post.id}';

  bool get _hasDraft => _isDirty;

  bool get _isDirty {
    return _titleController.text.trim() != _initialTitle ||
        _contentController.text.trim() != _initialContent ||
        !_sameImageList(_existingImageUrls, _initialImageUrls) ||
        _selectedTopic != _initialTopic ||
        !_sameImageList(_selectedTags, _initialTags) ||
        _images.isNotEmpty;
  }

  bool get _canSubmit {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        _isDirty &&
        !_isSubmitting;
  }

  int get _remainingImageSlots =>
      (_maxImageCount - (_existingImageUrls.length + _images.length)).clamp(
        0,
        _maxImageCount,
      );

  PostComposeAutosaveState get _autosaveState {
    return ref.read(postComposeAutosaveControllerProvider(_autosaveConfig));
  }

  @override
  void initState() {
    super.initState();
    final selectedProjectCode = ref.read(selectedProjectKeyProvider);
    _editProjectCode =
        (selectedProjectCode != null && selectedProjectCode.trim().isNotEmpty)
        ? selectedProjectCode.trim()
        : widget.post.projectId.trim();
    _autosaveConfig = PostComposeAutosaveConfig(storageKey: _draftStorageKey);
    _autosaveController = ref.read(
      postComposeAutosaveControllerProvider(_autosaveConfig).notifier,
    );
    final rawContent = (widget.post.content ?? '').trim();
    final extractedUrls = extractImageUrls(rawContent);
    final mergedInitialUrls = _normalizeImageUrls([
      ...widget.post.imageUrls,
      ...extractedUrls,
    ]);
    _initialTitle = widget.post.title.trim();
    _initialContent = stripImageMarkdown(rawContent).trim();
    _initialImageUrls = List.unmodifiable(mergedInitialUrls);
    _initialTopic = widget.post.topic?.trim().isNotEmpty == true
        ? widget.post.topic!.trim()
        : null;
    _initialTags = List.unmodifiable(sanitizePostTags(widget.post.tags));
    _existingImageUrls
      ..clear()
      ..addAll(_initialImageUrls);
    _selectedTopic = _initialTopic;
    _selectedTags
      ..clear()
      ..addAll(_initialTags);
    _titleController.text = _initialTitle;
    _contentController.text = _initialContent;
    _titleController.addListener(_onFormChanged);
    _contentController.addListener(_onFormChanged);
    _lastCanSubmit = _canSubmit;
    _lastHasDraft = _hasDraft;

    unawaited(_autosaveController.loadRecoverableDraft());
    unawaited(_loadPostComposeOptions(forceRefresh: true));
  }

  @override
  void dispose() {
    if (!_isSubmitting) {
      unawaited(
        _autosaveController.saveSnapshot(
          title: _titleController.text,
          content: _contentController.text,
          imagePaths: _images
              .map((image) => image.path)
              .toList(growable: false),
          topic: _selectedTopic,
          tags: _selectedTags,
          hasData: _isDirty,
          silent: true,
        ),
      );
    }
    _titleController.removeListener(_onFormChanged);
    _contentController.removeListener(_onFormChanged);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!mounted) {
      return;
    }
    _scheduleDraftSave();
    final nextCanSubmit = _canSubmit;
    final nextHasDraft = _hasDraft;
    if (nextCanSubmit == _lastCanSubmit && nextHasDraft == _lastHasDraft) {
      return;
    }
    setState(() {
      _lastCanSubmit = nextCanSubmit;
      _lastHasDraft = nextHasDraft;
    });
  }

  void _scheduleDraftSave() {
    if (_isSubmitting) {
      return;
    }
    _autosaveController.scheduleSave(
      title: _titleController.text,
      content: _contentController.text,
      imagePaths: _images.map((image) => image.path).toList(growable: false),
      topic: _selectedTopic,
      tags: _selectedTags,
      hasData: _isDirty,
    );
  }

  void _restoreDraft() {
    final draft = _autosaveState.recoverableDraft;
    if (draft == null) {
      return;
    }

    final existingImagePaths = draft.imagePaths
        .where((path) => File(path).existsSync())
        .take(_remainingImageSlots)
        .toList(growable: false);

    setState(() {
      _titleController.text = draft.title;
      _contentController.text = draft.content;
      _images
        ..clear()
        ..addAll(existingImagePaths.map((path) => XFile(path)));
      _selectedTopic = draft.topic;
      _selectedTags
        ..clear()
        ..addAll(sanitizePostTags(draft.tags));
    });
    _autosaveController.consumeRecoverableDraft(message: '임시 저장 글을 복구했어요');

    _scheduleDraftSave();
    _showMessage('임시 저장 글을 복구했어요.');
  }

  Future<void> _discardRecoverableDraft() async {
    await _autosaveController.clearSavedDraft(silent: true);
    _showMessage('임시 저장 글을 삭제했어요.');
  }

  Future<bool> _handleWillPop() async {
    if (_isSubmitting) {
      return false;
    }
    if (!_hasDraft) {
      return true;
    }

    final shouldDiscard = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '작성 중인 내용을 나갈까요?',
      message: '현재 입력 내용은 임시 저장되어 다음에 복구할 수 있어요.',
      confirmLabel: '나가기',
      cancelLabel: '계속 작성',
    );

    return shouldDiscard ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _orderedOptionNames(List<PostTaxonomyOption> options) {
    return options
        .map((option) => option.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadPostComposeOptions({bool forceRefresh = false}) async {
    if (!ref.read(isAuthenticatedProvider)) {
      return;
    }

    setState(() {
      _isTaxonomyLoading = true;
    });

    Result<PostComposeOptions> result;
    try {
      final repository = await ref.read(feedRepositoryProvider.future);
      result = await repository.getPostComposeOptions(
        forceRefresh: forceRefresh,
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTaxonomyLoading = false;
        _taxonomyLoadFailed = true;
        _taxonomyFailure = ErrorHandler.mapException(error, stackTrace);
      });
      return;
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<PostComposeOptions>(:final data):
        final topics = _orderedOptionNames(data.topics);
        final tags = _orderedOptionNames(data.tags);
        setState(() {
          _topicOptions
            ..clear()
            ..addAll(topics);
          _tagSuggestions
            ..clear()
            ..addAll(tags);
          _isTaxonomyLoading = false;
          _taxonomyLoadFailed = false;
          _taxonomyFailure = null;
        });
      case Err<PostComposeOptions>(:final failure):
        setState(() {
          _isTaxonomyLoading = false;
          _taxonomyLoadFailed = true;
          _taxonomyFailure = failure;
        });
    }
  }

  bool get _shouldShowTaxonomyLoginAction {
    final failure = _taxonomyFailure;
    if (failure is! AuthFailure) {
      return false;
    }
    return failure.code == '401' || failure.code == 'auth_required';
  }

  bool get _canOpenTopicPicker {
    if (_isSubmitting || _isTaxonomyLoading) {
      return false;
    }
    return _topicOptions.isNotEmpty;
  }

  bool get _canOpenTagPicker {
    if (_isSubmitting || _isTaxonomyLoading) {
      return false;
    }
    return _tagSuggestions.isNotEmpty;
  }

  String? get _taxonomyStatusMessage {
    if (_isTaxonomyLoading) {
      return '토픽/태그 목록을 불러오는 중입니다.';
    }

    if (_taxonomyLoadFailed) {
      final failure = _taxonomyFailure;
      if (failure is AuthFailure) {
        switch (failure.code) {
          case '401':
          case 'auth_required':
            return '로그인이 만료되었습니다. 다시 로그인해주세요.';
          case '403':
            return '토픽/태그 목록 조회 권한이 없습니다.';
        }
      }
      return '토픽/태그 목록을 불러오지 못했습니다.';
    }

    if (_topicOptions.isEmpty && _tagSuggestions.isEmpty) {
      return '현재 선택 가능한 토픽/태그가 없습니다.';
    }

    if (_topicOptions.isEmpty) {
      return '현재 선택 가능한 토픽이 없습니다.';
    }

    if (_tagSuggestions.isEmpty) {
      return '현재 선택 가능한 태그가 없습니다.';
    }

    return null;
  }

  Future<void> _handleCancelPressed() async {
    if (_isSubmitting) return;
    final shouldPop = await _handleWillPop();
    if (!mounted || !shouldPop) return;
    Navigator.of(context).pop();
  }

  Future<void> _openDraftShelf(PostComposeAutosaveState autosaveState) async {
    final recoverableDraft = autosaveState.recoverableDraft;
    if (recoverableDraft == null) {
      _showMessage('복구 가능한 임시 저장 글이 없습니다.');
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('임시 저장 글 복구'),
                subtitle: Text(
                  '${recoverableDraft.savedAt.toLocal()}',
                  style: GBTTypography.labelSmall,
                ),
                onTap: () => Navigator.of(sheetContext).pop('restore'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('임시 저장 글 삭제'),
                onTap: () => Navigator.of(sheetContext).pop('discard'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'restore') {
      _restoreDraft();
      return;
    }
    if (action == 'discard') {
      await _discardRecoverableDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final autosaveState = ref.watch(
      postComposeAutosaveControllerProvider(_autosaveConfig),
    );

    return PopScope<Object?>(
      canPop: !_isSubmitting && !_hasDraft,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _handleWillPop();
        if (!mounted || !shouldPop) {
          return;
        }
        Navigator.of(this.context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: gbtStandardAppBar(
          context,
          title: '수정',
          leading: IconButton(
            onPressed: _isSubmitting ? null : _handleCancelPressed,
            icon: const Icon(Icons.close_rounded),
            tooltip: '수정 취소',
          ),
          actions: [
            IconButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _openDraftShelf(autosaveState),
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: '임시 보관함',
            ),
            Padding(
              padding: const EdgeInsets.only(right: GBTSpacing.xs),
              child: FilledButton(
                key: const ValueKey('post-compose-submit'),
                onPressed: _canSubmit ? () => _submit(context) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(56, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                  ),
                ),
                child: Text(
                  _isSubmitting ? '수정 중' : '저장',
                  style: GBTTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: isAuthenticated
            ? _buildForm(context, autosaveState: autosaveState)
            : const PostComposeLoginRequiredMessage(),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required PostComposeAutosaveState autosaveState,
  }) {
    // EN: Use theme-aware colors for improved dark mode readability.
    // KO: 다크 모드 가독성을 위해 테마 기반 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final profile = ref.watch(userProfileControllerProvider).valueOrNull;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    GBTSpacing.md,
                    GBTSpacing.md,
                    GBTSpacing.md,
                  ),
                  children: [
                    const GBTPageHeader(
                      title: '여행 기록 수정',
                      description: '이미 공유한 여정의 맥락은 유지하고 내용을 더 정확하게 다듬어보세요.',
                      padding: EdgeInsets.only(bottom: GBTSpacing.md),
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    if (autosaveState.recoverableDraft != null) ...[
                      PostComposeDraftRecoveryBanner(
                        savedAt: autosaveState.recoverableDraft!.savedAt,
                        projectCode:
                            autosaveState.recoverableDraft!.projectCode,
                        onRestore: _restoreDraft,
                        onDiscard: _discardRecoverableDraft,
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                    ],
                    if (autosaveState.autosaveMessage != null) ...[
                      Text(
                        autosaveState.autosaveMessage!,
                        style: GBTTypography.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ComposerAvatar(url: profile?.avatarUrl),
                        const SizedBox(width: GBTSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: GBTSpacing.touchTarget,
                                child: Stack(
                                  children: [
                                    const Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: IgnorePointer(
                                          child: ProjectAudienceSelectorCompact(
                                            dense: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              GBTSpacing.radiusFull,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: GBTSpacing.xs,
                                            ),
                                            child: Icon(
                                              Icons.lock_outline_rounded,
                                              size: 14,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '수정 시 프로젝트는 변경할 수 없어요',
                                style: GBTTypography.labelSmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: GBTSpacing.xs),
                              PostTopicTagSelector(
                                selectedTopic: _selectedTopic,
                                selectedTags: _selectedTags,
                                onTapTopic: _canOpenTopicPicker
                                    ? _handleTopicTap
                                    : null,
                                onTapAddTag: _canOpenTagPicker
                                    ? _handleTagAddTap
                                    : null,
                                onRemoveTag: _isSubmitting ? null : _removeTag,
                              ),
                              if (_taxonomyStatusMessage != null) ...[
                                const SizedBox(height: GBTSpacing.xs),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _taxonomyStatusMessage!,
                                        style: GBTTypography.labelSmall
                                            .copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    if (_taxonomyLoadFailed)
                                      TextButton(
                                        onPressed: _isTaxonomyLoading
                                            ? null
                                            : () => unawaited(
                                                _loadPostComposeOptions(
                                                  forceRefresh: true,
                                                ),
                                              ),
                                        child: const Text('다시 시도'),
                                      ),
                                    if (_taxonomyLoadFailed &&
                                        _shouldShowTaxonomyLoginAction)
                                      TextButton(
                                        onPressed: () => context.go('/login'),
                                        child: const Text('로그인'),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: GBTSpacing.xs),
                              PostComposeDocumentEditor(
                                titleController: _titleController,
                                contentController: _contentController,
                                titleFocusNode: _titleFocusNode,
                                contentFocusNode: _contentFocusNode,
                                enabled: !_isSubmitting,
                                maxTitleLength: _maxTitleLength,
                                maxContentLength: _maxContentLength,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_existingImageUrls.isNotEmpty ||
                        _images.isNotEmpty) ...[
                      const SizedBox(height: GBTSpacing.sm),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length + _images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: GBTSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index < _existingImageUrls.length) {
                              final imageUrl = _existingImageUrls[index];
                              return _ComposerRemoteImageTile(
                                imageUrl: imageUrl,
                                onPreview: () => _previewRemoteImage(imageUrl),
                                onRemove: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() {
                                          _existingImageUrls.removeAt(index);
                                        });
                                        _scheduleDraftSave();
                                      },
                              );
                            }
                            final image =
                                _images[index - _existingImageUrls.length];
                            return _ComposerLocalImageTile(
                              imagePath: image.path,
                              onPreview: () => _previewImage(image),
                              onRemove: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _images.remove(image);
                                      });
                                      _scheduleDraftSave();
                                    },
                            );
                          },
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: GBTSpacing.sm),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(GBTSpacing.sm),
                          decoration: BoxDecoration(
                            color: GBTColors.errorLight,
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GBTTypography.bodySmall.copyWith(
                              color: GBTColors.errorDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: GBTSpacing.lg),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? GBTColors.darkBorderSubtle
                            : GBTColors.border,
                        width: 0.8,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    GBTSpacing.xs,
                    GBTSpacing.md,
                    GBTSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      _ComposerToolbarIconButton(
                        icon: Icons.image_outlined,
                        onTap: _isSubmitting ? null : _pickFromGallery,
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      _ComposerToolbarIconButton(
                        icon: Icons.camera_alt_outlined,
                        onTap: _isSubmitting ? null : _pickFromCamera,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black.withValues(alpha: 0.22),
            child: const Center(child: GBTLoading(message: '게시글을 수정하는 중...')),
          ),
      ],
    );
  }

  void _previewRemoteImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(GBTSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: GBTImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      errorWidget: const Center(
                        child: Text(
                          '이미지를 표시할 수 없습니다',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: GBTSpacing.xs,
                  top: GBTSpacing.xs,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _previewImage(XFile image) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(GBTSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          '이미지를 표시할 수 없습니다',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: GBTSpacing.xs,
                  top: GBTSpacing.xs,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTopicTap() async {
    if (_isTaxonomyLoading) {
      _showMessage('토픽/태그 목록을 불러오는 중입니다.');
      return;
    }
    if (_topicOptions.isEmpty) {
      _showMessage('선택 가능한 토픽이 없습니다.');
      return;
    }

    final selected = await showPostTopicPickerSheet(
      context,
      selectedTopic: _selectedTopic,
      options: _topicOptions,
    );
    if (!mounted || selected == null) {
      return;
    }
    final normalized = selected.trim().isEmpty ? null : selected.trim();
    if (normalized == _selectedTopic) {
      return;
    }
    setState(() {
      _selectedTopic = normalized;
    });
    _scheduleDraftSave();
  }

  Future<void> _handleTagAddTap() async {
    if (_selectedTags.length >= kPostMaxTagCount) {
      _showMessage('태그는 최대 $kPostMaxTagCount개까지 추가할 수 있어요.');
      return;
    }
    if (_isTaxonomyLoading) {
      _showMessage('토픽/태그 목록을 불러오는 중입니다.');
      return;
    }
    if (_tagSuggestions.isEmpty) {
      _showMessage('선택 가능한 태그가 없습니다.');
      return;
    }
    final selected = await showPostTagPickerSheet(
      context,
      selectedTags: _selectedTags,
      suggestions: _tagSuggestions,
    );
    if (!mounted || selected == null) {
      return;
    }
    final normalized = normalizePostTag(selected);
    if (normalized.isEmpty) {
      return;
    }
    final exists = _selectedTags.any(
      (tag) => tag.toLowerCase() == normalized.toLowerCase(),
    );
    if (exists) {
      _showMessage('이미 선택된 태그예요.');
      return;
    }
    setState(() {
      _selectedTags.add(normalized);
    });
    _scheduleDraftSave();
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    _scheduleDraftSave();
  }

  Future<void> _submit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요')));
      return;
    }

    if (_editProjectCode.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('프로젝트를 먼저 선택해주세요')));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    List<String> imageUrls = const [];
    if (_images.isNotEmpty) {
      try {
        imageUrls = await _uploadImages();
      } on Failure catch (failure) {
        setState(() {
          _errorMessage = failure.userMessage;
          _isSubmitting = false;
        });
        return;
      } catch (_) {
        setState(() {
          _errorMessage = '이미지 업로드에 실패했습니다.';
          _isSubmitting = false;
        });
        return;
      }
    }
    final mergedImageUrls = _normalizeImageUrls([
      ..._existingImageUrls,
      ...imageUrls,
    ]);
    final contentWithImages = appendImageMarkdownContent(
      content,
      mergedImageUrls,
    );

    final repository = await ref.read(feedRepositoryProvider.future);
    final normalizedTags = sanitizePostTags(_selectedTags);
    final result = await repository.updatePost(
      projectCode: _editProjectCode,
      postId: widget.post.id,
      title: title,
      content: contentWithImages,
      topic: _selectedTopic,
      tags: normalizedTags,
    );

    if (!mounted) {
      return;
    }

    if (result case Success<PostDetail>()) {
      await Future.wait([
        ref
            .read(postDetailControllerProvider(widget.post.id).notifier)
            .load(forceRefresh: true),
        ref.read(postListControllerProvider.notifier).load(forceRefresh: true),
      ]);
      await _autosaveController.clearSavedDraft(silent: true);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('게시글을 수정했어요')));
      router.pop();
    } else if (result case Err<PostDetail>(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
  }

  Future<void> _pickFromGallery() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('이미지는 최대 $_maxImageCount장까지 첨부할 수 있어요.');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        maxHeight: 2160,
        maxWidth: 2160,
        imageQuality: 92,
      );

      if (picked.isEmpty || !mounted) {
        return;
      }

      _appendPickedImages(picked);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('갤러리를 열지 못했어요.');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('이미지는 최대 $_maxImageCount장까지 첨부할 수 있어요.');
      return;
    }

    if (!_picker.supportsImageSource(ImageSource.camera)) {
      _showMessage('이 기기에서는 카메라를 사용할 수 없어요.');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 2160,
        maxWidth: 2160,
        imageQuality: 92,
      );

      if (picked == null || !mounted) {
        return;
      }

      _appendPickedImages([picked]);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('카메라를 열지 못했어요.');
    }
  }

  void _appendPickedImages(List<XFile> picked) {
    final existingPaths = _images.map((image) => image.path).toSet();
    final uniquePicked = <XFile>[];
    for (final image in picked) {
      if (existingPaths.add(image.path)) {
        uniquePicked.add(image);
      }
    }

    if (uniquePicked.isEmpty) {
      _showMessage('이미 추가된 사진입니다.');
      return;
    }

    final addable = uniquePicked.take(_remainingImageSlots).toList();
    final droppedCount = uniquePicked.length - addable.length;

    setState(() {
      _images.addAll(addable);
    });
    _scheduleDraftSave();

    if (droppedCount > 0) {
      _showMessage('$_maxImageCount장까지만 첨부할 수 있어요.');
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_images.isEmpty) {
      return const [];
    }

    final uploadController = ref.read(uploadsControllerProvider.notifier);
    final uploads = <UploadInfo>[];

    for (final image in _images) {
      final payload = await convertToWebp(
        path: image.path,
        originalFilename: p.basename(image.path),
        // EN: Force JPEG on Android to keep feed thumbnail generation stable.
        // KO: 안드로이드에서는 피드 썸네일 생성 안정화를 위해 JPEG로 강제합니다.
        forceJpeg: Platform.isAndroid,
      );

      final uploadResult = await uploadController.uploadImageBytes(
        bytes: payload.bytes,
        filename: payload.filename,
        contentType: payload.contentType,
      );

      if (uploadResult case Err(:final failure)) {
        throw failure;
      }

      final upload = switch (uploadResult) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };

      if (upload.uploadId.isNotEmpty) {
        uploads.add(upload);
      }
    }

    final hydratedUploads = await _hydrateUploadUrlsFromMyUploads(
      uploads,
      uploadController,
    );
    return hydratedUploads
        .map((upload) => upload.url)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<UploadInfo>> _hydrateUploadUrlsFromMyUploads(
    List<UploadInfo> uploads,
    UploadsController uploadController,
  ) async {
    if (uploads.isEmpty) {
      return const [];
    }

    var resolved = List<UploadInfo>.from(uploads);
    if (resolved.every((upload) => upload.url.isNotEmpty)) {
      return resolved;
    }

    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt += 1) {
      if (resolved.every((upload) => upload.url.isNotEmpty)) {
        break;
      }
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }

      await uploadController.load(forceRefresh: true);
      final latestUploads = ref.read(uploadsControllerProvider).valueOrNull;
      if (latestUploads == null || latestUploads.isEmpty) {
        continue;
      }

      final latestById = <String, UploadInfo>{
        for (final item in latestUploads)
          if (item.uploadId.isNotEmpty) item.uploadId: item,
      };
      resolved = resolved
          .map((upload) {
            if (upload.url.isNotEmpty || upload.uploadId.isEmpty) {
              return upload;
            }
            final latest = latestById[upload.uploadId];
            if (latest == null || latest.url.isEmpty) {
              return upload;
            }
            return UploadInfo(
              uploadId: upload.uploadId,
              url: latest.url,
              filename: latest.filename.isNotEmpty
                  ? latest.filename
                  : upload.filename,
              isApproved: latest.isApproved,
            );
          })
          .toList(growable: false);
    }

    final unresolved = resolved.where((upload) => upload.url.isEmpty).length;
    if (unresolved > 0) {
      AppLogger.warning(
        'Some uploaded image URLs are unresolved after retries',
        tag: 'PostEditPage',
        data: {'total': resolved.length, 'unresolved': unresolved},
      );
    }
    return resolved;
  }

  List<String> _normalizeImageUrls(Iterable<String> rawUrls) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final rawUrl in rawUrls) {
      final resolved = resolveMediaUrl(rawUrl.trim());
      if (resolved.isEmpty) continue;
      if (seen.add(resolved)) {
        normalized.add(resolved);
      }
    }

    return normalized;
  }

  bool _sameImageList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i += 1) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }
}

/// EN: Composer avatar shown at the beginning of create/edit text area.
/// KO: 작성/수정 입력 영역 시작점에 표시되는 작성자 아바타입니다.
class _ComposerAvatar extends StatelessWidget {
  const _ComposerAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedUrl = (url == null || url!.isEmpty)
        ? null
        : resolveMediaUrl(url!);
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: resolvedUrl == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? GBTColors.darkSurfaceVariant
                      : GBTColors.surfaceVariant,
                ),
                child: Icon(
                  Icons.person,
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
              )
            : GBTImage(imageUrl: resolvedUrl, fit: BoxFit.cover),
      ),
    );
  }
}

/// EN: Compact icon button used in the composer toolbar.
/// KO: 작성 툴바에서 사용하는 컴팩트 아이콘 버튼입니다.
class _ComposerToolbarIconButton extends StatelessWidget {
  const _ComposerToolbarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return SizedBox(
      width: GBTSpacing.touchTarget,
      height: GBTSpacing.touchTarget,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 22,
          color: iconColor.withValues(alpha: onTap == null ? 0.42 : 1),
        ),
      ),
    );
  }
}

/// EN: Horizontal local-image preview tile for compose timeline style.
/// KO: 타임라인 스타일 작성 화면의 가로형 로컬 이미지 미리보기 타일입니다.
class _ComposerLocalImageTile extends StatelessWidget {
  const _ComposerLocalImageTile({
    required this.imagePath,
    required this.onPreview,
    this.onRemove,
  });

  final String imagePath;
  final VoidCallback onPreview;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? GBTColors.darkSurfaceVariant
                            : GBTColors.surfaceVariant,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: GBTSpacing.touchTarget,
                height: GBTSpacing.touchTarget,
                child: IconButton.filled(
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.56),
                  ),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white,
                  tooltip: '삭제',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// EN: Horizontal remote-image preview tile for compose timeline style.
/// KO: 타임라인 스타일 작성 화면의 가로형 원격 이미지 미리보기 타일입니다.
class _ComposerRemoteImageTile extends StatelessWidget {
  const _ComposerRemoteImageTile({
    required this.imageUrl,
    required this.onPreview,
    this.onRemove,
  });

  final String imageUrl;
  final VoidCallback onPreview;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GBTImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? GBTColors.darkSurfaceVariant
                            : GBTColors.surfaceVariant,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: GBTSpacing.touchTarget,
                height: GBTSpacing.touchTarget,
                child: IconButton.filled(
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.56),
                  ),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white,
                  tooltip: '삭제',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
