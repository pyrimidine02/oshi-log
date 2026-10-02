/// EN: Community moderation repository provider.
/// KO: 커뮤니티 신고/제재 리포지토리 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../data/datasources/community_remote_data_source.dart';
import '../data/repositories/community_repository_impl.dart';
import '../domain/repositories/community_repository.dart';

/// EN: Community repository provider.
/// KO: 커뮤니티 리포지토리 프로바이더.
final communityRepositoryProvider = FutureProvider<CommunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepositoryImpl(
    remoteDataSource: CommunityRemoteDataSource(apiClient),
  );
});
