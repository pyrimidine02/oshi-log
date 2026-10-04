/// EN: News repository provider and data-source wiring.
/// KO: 뉴스 리포지토리 프로바이더 및 데이터소스 구성.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import '../data/datasources/news_remote_data_source.dart';
import '../data/repositories/news_repository_impl.dart';
import '../domain/repositories/news_repository.dart';

/// EN: News repository provider.
/// KO: 뉴스 리포지토리 프로바이더.
final newsRepositoryProvider = FutureProvider<NewsRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return NewsRepositoryImpl(
    remoteDataSource: NewsRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});
