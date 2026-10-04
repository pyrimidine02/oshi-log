/// EN: News feed controllers.
/// KO: 뉴스 피드 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/router/app_router.dart' show NavIndex;
import 'package:oshi_log/platform/router/navigation_state.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import '../domain/entities/news_entities.dart';
import 'news_repository_provider.dart';

// EN: News now surfaces on the Home branch (PR9 IA); the old "info tab 2"
// EN: condition must not fire when the unrelated Live branch activates.
// KO: 뉴스는 이제 홈 분기에 노출됩니다(PR9 IA). 기존 "정보 탭 2" 조건이
// KO: 무관한 라이브 분기 활성화 시 발동하면 안 됩니다.
bool _isNewsConsumerTabActive(Ref ref) {
  return ref.read(currentNavIndexProvider) == NavIndex.home;
}

class NewsListController extends StateNotifier<AsyncValue<List<NewsSummary>>> {
  NewsListController(this._ref) : super(const AsyncLoading()) {
    _ref.listen<String?>(selectedProjectKeyProvider, (_, __) {
      if (!_isNewsConsumerTabActive(_ref)) {
        return;
      }
      load(forceRefresh: true);
    });
    _ref.listen<int>(currentNavIndexProvider, (previous, next) {
      if (next != NavIndex.home || next == previous) {
        return;
      }
      load(forceRefresh: true);
    });
  }

  final Ref _ref;

  Future<void> load({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }
    if (!_isNewsConsumerTabActive(_ref)) {
      return;
    }
    final projectKey = _ref.read(selectedProjectKeyProvider);
    if (projectKey == null || projectKey.isEmpty) {
      // EN: Wait for project selection before loading.
      // KO: 로드 전 프로젝트 선택을 기다립니다.
      return;
    }

    if (!mounted) {
      return;
    }
    state = const AsyncLoading();

    final repository = await _ref.read(newsRepositoryProvider.future);
    if (!mounted) {
      return;
    }
    final result = await repository.getNews(
      projectId: projectKey,
      // EN: News summaries are lightweight. Keep the local archive broad
      //     enough for title search, year filtering, and oldest-first access.
      // KO: 뉴스 요약은 가볍습니다. 제목 검색, 연도 필터, 오래된순 접근을
      //     위해 로컬 아카이브 범위를 충분히 넓게 유지합니다.
      size: 200,
      forceRefresh: forceRefresh,
    );

    if (!mounted) {
      return;
    }
    if (result is Success<List<NewsSummary>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<NewsSummary>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

class NewsDetailController extends StateNotifier<AsyncValue<NewsDetail>> {
  NewsDetailController(this._ref, this.newsId) : super(const AsyncLoading());

  final Ref _ref;
  final String newsId;

  Future<void> load({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }
    final projectKey = _ref.read(selectedProjectKeyProvider);
    if (projectKey == null || projectKey.isEmpty) {
      // EN: Wait for project selection before loading.
      // KO: 로드 전 프로젝트 선택을 기다립니다.
      return;
    }

    if (!mounted) {
      return;
    }
    state = const AsyncLoading();

    final repository = await _ref.read(newsRepositoryProvider.future);
    if (!mounted) {
      return;
    }
    final result = await repository.getNewsDetail(
      projectId: projectKey,
      newsId: newsId,
      forceRefresh: forceRefresh,
    );

    if (!mounted) {
      return;
    }
    if (result is Success<NewsDetail>) {
      state = AsyncData(result.data);
    } else if (result is Err<NewsDetail>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

/// EN: News list controller provider.
/// KO: 뉴스 리스트 컨트롤러 프로바이더.
final newsListControllerProvider =
    StateNotifierProvider.autoDispose<
      NewsListController,
      AsyncValue<List<NewsSummary>>
    >((ref) {
      return NewsListController(ref)..load();
    });

/// EN: News detail controller provider.
/// KO: 뉴스 상세 컨트롤러 프로바이더.
final newsDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<NewsDetailController, AsyncValue<NewsDetail>, String>((
      ref,
      newsId,
    ) {
      return NewsDetailController(ref, newsId)..load();
    });
