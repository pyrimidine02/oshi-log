/// EN: Read-only provider adapters for the Field Guide artist sections.
/// KO: Field Guide 아티스트 섹션을 위한 읽기 전용 프로바이더 어댑터.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_context.dart';
import 'projects_controller.dart';
import '../domain/entities/project_entities.dart';

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
