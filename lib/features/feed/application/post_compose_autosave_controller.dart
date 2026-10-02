/// EN: Autosave controller for post compose/edit draft flows.
/// KO: 게시글 작성/수정 임시저장 흐름을 위한 오토세이브 컨트롤러입니다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/application/project_context.dart';
import 'post_compose_draft_store.dart';

/// EN: Configuration for a compose autosave session.
/// KO: 작성 오토세이브 세션 설정값입니다.
class PostComposeAutosaveConfig {
  const PostComposeAutosaveConfig({required this.storageKey});

  final String storageKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PostComposeAutosaveConfig && other.storageKey == storageKey;
  }

  @override
  int get hashCode => storageKey.hashCode;
}

/// EN: View state for compose autosave UX.
/// KO: 작성 오토세이브 UX를 위한 뷰 상태입니다.
class PostComposeAutosaveState {
  const PostComposeAutosaveState({this.recoverableDraft, this.autosaveMessage});

  final PostComposeDraft? recoverableDraft;
  final String? autosaveMessage;

  PostComposeAutosaveState copyWith({
    PostComposeDraft? recoverableDraft,
    bool clearRecoverableDraft = false,
    String? autosaveMessage,
    bool clearAutosaveMessage = false,
  }) {
    return PostComposeAutosaveState(
      recoverableDraft: clearRecoverableDraft
          ? null
          : (recoverableDraft ?? this.recoverableDraft),
      autosaveMessage: clearAutosaveMessage
          ? null
          : (autosaveMessage ?? this.autosaveMessage),
    );
  }
}

/// EN: Provider for page-scoped compose autosave controller.
/// KO: 페이지 범위 작성 오토세이브 컨트롤러 프로바이더입니다.
final postComposeAutosaveControllerProvider = StateNotifierProvider.autoDispose
    .family<
      PostComposeAutosaveController,
      PostComposeAutosaveState,
      PostComposeAutosaveConfig
    >((ref, config) {
      return PostComposeAutosaveController(ref, config);
    });

/// EN: Orchestrates recoverable draft load/save/delete with debounce.
/// KO: 디바운스 기반 임시저장 로드/저장/삭제를 조율합니다.
class PostComposeAutosaveController
    extends StateNotifier<PostComposeAutosaveState> {
  PostComposeAutosaveController(this._ref, this._config)
    : super(const PostComposeAutosaveState());

  static const Duration _debounceDuration = Duration(milliseconds: 1200);

  final Ref _ref;
  final PostComposeAutosaveConfig _config;
  Timer? _debounce;

  Future<void> loadRecoverableDraft() async {
    final store = await _readStore();
    final draft = await store.read(_config.storageKey);
    if (!mounted || draft == null || draft.isEmpty) {
      return;
    }
    state = state.copyWith(recoverableDraft: draft);
  }

  void scheduleSave({
    required String title,
    required String content,
    required List<String> imagePaths,
    required bool hasData,
    String? topic,
    List<String> tags = const [],
  }) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      unawaited(
        saveSnapshot(
          title: title,
          content: content,
          imagePaths: imagePaths,
          hasData: hasData,
          topic: topic,
          tags: tags,
        ),
      );
    });
  }

  Future<void> saveSnapshot({
    required String title,
    required String content,
    required List<String> imagePaths,
    required bool hasData,
    String? topic,
    List<String> tags = const [],
    bool silent = false,
  }) async {
    final normalizedImagePaths = imagePaths
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false);
    final normalizedTopic = topic?.trim();
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    final effectiveHasData =
        hasData ||
        title.trim().isNotEmpty ||
        content.trim().isNotEmpty ||
        normalizedImagePaths.isNotEmpty ||
        (normalizedTopic != null && normalizedTopic.isNotEmpty) ||
        normalizedTags.isNotEmpty;

    final store = await _readStore();
    if (!effectiveHasData) {
      await store.delete(_config.storageKey);
      if (!silent && mounted) {
        state = state.copyWith(clearAutosaveMessage: true);
      }
      return;
    }

    final draft = PostComposeDraft(
      title: title.trim(),
      content: content.trim(),
      imagePaths: normalizedImagePaths,
      savedAt: DateTime.now(),
      projectCode: _ref.read(selectedProjectKeyProvider),
      topic: normalizedTopic,
      tags: normalizedTags,
    );
    await store.write(_config.storageKey, draft);
    if (!silent && mounted) {
      state = state.copyWith(
        autosaveMessage: '임시 저장됨 · ${_formatTime(draft.savedAt)}',
      );
    }
  }

  Future<void> clearSavedDraft({bool silent = false}) async {
    _debounce?.cancel();
    final store = await _readStore();
    await store.delete(_config.storageKey);
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      clearRecoverableDraft: true,
      clearAutosaveMessage: !silent,
    );
  }

  void consumeRecoverableDraft({String? message}) {
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      clearRecoverableDraft: true,
      autosaveMessage: message,
      clearAutosaveMessage: message == null,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<PostComposeDraftStore> _readStore() async {
    return _ref.read(postComposeDraftStoreProvider.future);
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
