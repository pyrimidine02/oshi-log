/// EN: Social repository provider.
/// KO: 소셜 리포지토리 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/core/providers/core_providers.dart';

import '../data/datasources/social_remote_data_source.dart';
import '../data/repositories/social_repository_impl.dart';
import '../domain/repositories/social_repository.dart';

final socialRepositoryProvider = FutureProvider<SocialRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialRepositoryImpl(
    remoteDataSource: SocialRemoteDataSource(apiClient),
  );
});
