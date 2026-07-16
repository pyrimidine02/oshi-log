/// EN: Read-only provider adapters for the Field Guide presentation layer.
/// KO: Field Guide 프레젠테이션 계층을 위한 읽기 전용 프로바이더 어댑터.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../application/news_controller.dart';
import '../../domain/entities/feed_entities.dart';

/// EN: Updates exposed to the guide without duplicating repository state.
/// KO: 저장소 상태를 복제하지 않고 가이드에 노출하는 업데이트 목록입니다.
final fieldGuideUpdatesProvider =
    Provider.autoDispose<AsyncValue<List<NewsSummary>>>((ref) {
      return ref.watch(newsListControllerProvider);
    });

/// EN: Currently selected project key used by artist and archive sections.
/// KO: 아티스트와 아카이브 섹션이 사용하는 현재 프로젝트 키입니다.
final fieldGuideProjectKeyProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(selectedProjectKeyProvider);
});

/// EN: Artists are backed by the existing project-unit contract.
/// KO: 아티스트는 기존 프로젝트 유닛 계약을 그대로 사용합니다.
final fieldGuideArtistsProvider = Provider.autoDispose<AsyncValue<List<Unit>>>((
  ref,
) {
  final projectKey = ref.watch(fieldGuideProjectKeyProvider);
  if (projectKey == null || projectKey.trim().isEmpty) {
    return const AsyncData(<Unit>[]);
  }
  return ref.watch(projectUnitsControllerProvider(projectKey));
});
