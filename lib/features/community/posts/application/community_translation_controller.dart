/// EN: On-demand community translation controller with in-memory cache.
/// KO: 메모리 캐시 기반 요청형 커뮤니티 번역 컨트롤러입니다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/community/posts/domain/entities/feed_entities.dart';
import 'feed_repository_provider.dart';

String normalizeTranslationLanguageCode(String? rawCode) {
  final normalized = rawCode?.trim().toLowerCase() ?? '';
  if (normalized == 'ko' || normalized == 'en' || normalized == 'ja') {
    return normalized;
  }
  return 'en';
}

String? detectLikelyTranslationLanguage(String text) {
  final normalizedText = text.trim();
  if (normalizedText.isEmpty) {
    return null;
  }
  if (RegExp(r'[\uac00-\ud7af]').hasMatch(normalizedText)) {
    return 'ko';
  }
  if (RegExp(r'[\u3040-\u30ff]').hasMatch(normalizedText)) {
    return 'ja';
  }
  if (RegExp(r'[A-Za-z]').hasMatch(normalizedText)) {
    return 'en';
  }
  return null;
}

/// EN: Cache key for translation lookup.
/// KO: 번역 조회용 캐시 키입니다.
class CommunityTranslationCacheKey {
  const CommunityTranslationCacheKey({
    required this.contentId,
    required this.targetLanguage,
  });

  final String contentId;
  final String targetLanguage;

  String get storageKey => '$contentId::$targetLanguage';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CommunityTranslationCacheKey &&
            other.contentId == contentId &&
            other.targetLanguage == targetLanguage;
  }

  @override
  int get hashCode => Object.hash(contentId, targetLanguage);
}

enum CommunityTranslationLoadStatus {
  idle,
  loading,
  translated,
  noResult,
  error,
}

/// EN: Per-content translation view state.
/// KO: 콘텐츠별 번역 뷰 상태입니다.
class CommunityTranslationEntry {
  const CommunityTranslationEntry({
    required this.status,
    this.translatedText,
    this.sourceLanguage,
    this.targetLanguage,
    this.failure,
  });

  const CommunityTranslationEntry.idle()
    : this(status: CommunityTranslationLoadStatus.idle);

  final CommunityTranslationLoadStatus status;
  final String? translatedText;
  final String? sourceLanguage;
  final String? targetLanguage;
  final Failure? failure;

  bool get isTerminal =>
      status == CommunityTranslationLoadStatus.translated ||
      status == CommunityTranslationLoadStatus.noResult;
}

class CommunityTranslationController
    extends StateNotifier<Map<String, CommunityTranslationEntry>> {
  CommunityTranslationController(this._ref) : super(const {});

  final Ref _ref;
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  Future<void> translate({
    required String contentId,
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final normalizedContentId = contentId.trim();
    final normalizedText = text.trim();
    final normalizedTarget = normalizeTranslationLanguageCode(targetLanguage);
    final normalizedSource = sourceLanguage?.trim().toLowerCase();

    if (normalizedContentId.isEmpty || normalizedText.isEmpty) {
      return;
    }

    final cacheKey = CommunityTranslationCacheKey(
      contentId: normalizedContentId,
      targetLanguage: normalizedTarget,
    ).storageKey;

    final existing = state[cacheKey];
    if (existing != null && existing.isTerminal) {
      return;
    }

    final currentTask = _inFlight[cacheKey];
    if (currentTask != null) {
      await currentTask;
      return;
    }

    state = {
      ...state,
      cacheKey: CommunityTranslationEntry(
        status: CommunityTranslationLoadStatus.loading,
        sourceLanguage: normalizedSource,
        targetLanguage: normalizedTarget,
      ),
    };

    final task = _runTranslation(
      cacheKey: cacheKey,
      text: normalizedText,
      targetLanguage: normalizedTarget,
      sourceLanguage: normalizedSource,
    );
    _inFlight[cacheKey] = task;
    try {
      await task;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  Future<void> _runTranslation({
    required String cacheKey,
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await repository.translateCommunityText(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );

    if (!mounted) {
      return;
    }

    if (result is Success<CommunityTranslation>) {
      final translation = result.data;
      if (translation.hasTranslatedText) {
        state = {
          ...state,
          cacheKey: CommunityTranslationEntry(
            status: CommunityTranslationLoadStatus.translated,
            translatedText: translation.translatedText,
            sourceLanguage: translation.sourceLanguage,
            targetLanguage: translation.targetLanguage,
          ),
        };
      } else {
        state = {
          ...state,
          cacheKey: CommunityTranslationEntry(
            status: CommunityTranslationLoadStatus.noResult,
            translatedText: translation.translatedText,
            sourceLanguage: translation.sourceLanguage,
            targetLanguage: translation.targetLanguage,
          ),
        };
      }
      return;
    }

    if (result is Err<CommunityTranslation>) {
      state = {
        ...state,
        cacheKey: CommunityTranslationEntry(
          status: CommunityTranslationLoadStatus.error,
          failure: result.failure,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
      };
    }
  }
}

final communityTranslationControllerProvider =
    StateNotifierProvider.autoDispose<
      CommunityTranslationController,
      Map<String, CommunityTranslationEntry>
    >((ref) {
      return CommunityTranslationController(ref);
    });

final communityTranslationEntryProvider = Provider.autoDispose
    .family<CommunityTranslationEntry, CommunityTranslationCacheKey>((
      ref,
      key,
    ) {
      final state = ref.watch(communityTranslationControllerProvider);
      return state[key.storageKey] ?? const CommunityTranslationEntry.idle();
    });
