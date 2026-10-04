/// EN: Local draft store for post compose/edit forms.
/// KO: 게시글 작성/수정 폼용 로컬 임시저장 스토어입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';

/// EN: Provider for the post compose draft store.
/// KO: 게시글 임시저장 스토어 프로바이더입니다.
final postComposeDraftStoreProvider = FutureProvider<PostComposeDraftStore>((
  ref,
) async {
  final localStorage = await ref.read(localStorageProvider.future);
  return PostComposeDraftStore(localStorage);
});

/// EN: Draft payload used by compose/edit flows.
/// KO: 작성/수정 흐름에서 사용하는 임시저장 페이로드입니다.
class PostComposeDraft {
  const PostComposeDraft({
    required this.title,
    required this.content,
    required this.imagePaths,
    required this.savedAt,
    this.projectCode,
    this.topic,
    this.tags = const [],
  });

  final String title;
  final String content;
  final List<String> imagePaths;
  final DateTime savedAt;
  final String? projectCode;
  final String? topic;
  final List<String> tags;

  /// EN: Returns true when draft has no meaningful user input.
  /// KO: 사용자 입력이 실질적으로 비어있으면 true를 반환합니다.
  bool get isEmpty {
    return title.trim().isEmpty &&
        content.trim().isEmpty &&
        imagePaths.isEmpty &&
        (topic == null || topic!.trim().isEmpty) &&
        tags.isEmpty;
  }

  /// EN: Serializes draft data for local storage.
  /// KO: 로컬 저장을 위한 임시저장 데이터를 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imagePaths': imagePaths,
      'savedAt': savedAt.toIso8601String(),
      'projectCode': projectCode,
      'topic': topic,
      'tags': tags,
    };
  }

  /// EN: Restores draft data from local storage JSON.
  /// KO: 로컬 저장 JSON에서 임시저장 데이터를 복원합니다.
  static PostComposeDraft? fromJson(Map<String, dynamic> json) {
    final savedAtRaw = json['savedAt'];
    final savedAt = savedAtRaw is String ? DateTime.tryParse(savedAtRaw) : null;
    if (savedAt == null) {
      return null;
    }

    final title = json['title'] as String? ?? '';
    final content = json['content'] as String? ?? '';
    final imagePaths = (json['imagePaths'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false);
    final projectCodeRaw = json['projectCode'];
    final projectCode = projectCodeRaw is String && projectCodeRaw.isNotEmpty
        ? projectCodeRaw
        : null;
    final topicRaw = json['topic'];
    final topic = topicRaw is String && topicRaw.trim().isNotEmpty
        ? topicRaw.trim()
        : null;
    final tags = (json['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);

    return PostComposeDraft(
      title: title,
      content: content,
      imagePaths: imagePaths,
      savedAt: savedAt,
      projectCode: projectCode,
      topic: topic,
      tags: tags,
    );
  }
}

/// EN: Handles read/write/delete operations for compose drafts.
/// KO: 작성 임시저장 데이터의 조회/저장/삭제를 담당합니다.
class PostComposeDraftStore {
  PostComposeDraftStore(
    this._localStorage, {
    DateTime Function()? now,
    Duration retention = const Duration(days: 30),
  }) : _now = now ?? DateTime.now,
       _retention = retention;

  final LocalStorage _localStorage;
  final DateTime Function() _now;
  final Duration _retention;

  /// EN: Reads a draft from storage by key.
  /// KO: 키를 기준으로 임시저장 데이터를 읽습니다.
  Future<PostComposeDraft?> read(String key) async {
    final json = _localStorage.getJson(key);
    if (json == null) {
      return null;
    }
    final draft = PostComposeDraft.fromJson(json);
    if (draft == null) {
      return null;
    }

    if (_isExpired(draft.savedAt)) {
      await delete(key);
      return null;
    }

    return draft;
  }

  /// EN: Writes a draft snapshot to storage.
  /// KO: 임시저장 스냅샷을 저장소에 기록합니다.
  Future<void> write(String key, PostComposeDraft draft) async {
    await _localStorage.setJson(key, draft.toJson());
  }

  /// EN: Deletes a draft from storage.
  /// KO: 저장된 임시저장 데이터를 삭제합니다.
  Future<void> delete(String key) async {
    await _localStorage.remove(key);
  }

  bool _isExpired(DateTime savedAt) {
    return _now().isAfter(savedAt.add(_retention));
  }
}
