import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/feed/application/feed_repository_provider.dart';
import 'package:oshi_log/features/feed/application/news_controller.dart';
import 'package:oshi_log/features/feed/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/feed/domain/repositories/feed_repository.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  group('News controllers dispose safety', () {
    test(
      'NewsListController.load ignores async completion after dispose',
      () async {
        final repository = _MockFeedRepository();
        final completer = Completer<Result<List<NewsSummary>>>();
        when(
          () => repository.getNews(
            projectId: any(named: 'projectId'),
            size: any(named: 'size'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) => completer.future);

        final provider =
            StateNotifierProvider<
              NewsListController,
              AsyncValue<List<NewsSummary>>
            >((ref) => NewsListController(ref));
        final container = ProviderContainer(
          overrides: [
            selectedProjectKeyProvider.overrideWith((ref) => 'project-1'),
            currentNavIndexProvider.overrideWith((ref) => 2),
            feedRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );

        final notifier = container.read(provider.notifier);
        final loadFuture = notifier.load(forceRefresh: true);
        await Future<void>.delayed(Duration.zero);

        container.dispose();

        completer.complete(
          Result.success([
            NewsSummary(
              id: 'news-1',
              title: 'Test News',
              publishedAt: DateTime.utc(2026, 3, 30),
            ),
          ]),
        );

        await expectLater(loadFuture, completes);
        verify(
          () => repository.getNews(
            projectId: 'project-1',
            size: 200,
            forceRefresh: true,
          ),
        ).called(1);
      },
    );

    test(
      'NewsDetailController.load ignores async completion after dispose',
      () async {
        final repository = _MockFeedRepository();
        final completer = Completer<Result<NewsDetail>>();
        when(
          () => repository.getNewsDetail(
            projectId: any(named: 'projectId'),
            newsId: any(named: 'newsId'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) => completer.future);

        final provider =
            StateNotifierProvider<NewsDetailController, AsyncValue<NewsDetail>>(
              (ref) => NewsDetailController(ref, 'news-1'),
            );
        final container = ProviderContainer(
          overrides: [
            selectedProjectKeyProvider.overrideWith((ref) => 'project-1'),
            feedRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );

        final notifier = container.read(provider.notifier);
        final loadFuture = notifier.load(forceRefresh: true);
        await Future<void>.delayed(Duration.zero);

        container.dispose();

        completer.complete(
          Result.success(
            NewsDetail(
              id: 'news-1',
              title: 'Detail',
              body: 'Body',
              status: 'PUBLISHED',
              publishedAt: DateTime.utc(2026, 3, 30),
            ),
          ),
        );

        await expectLater(loadFuture, completes);
        verify(
          () => repository.getNewsDetail(
            projectId: 'project-1',
            newsId: 'news-1',
            forceRefresh: true,
          ),
        ).called(1);
      },
    );
  });
}
