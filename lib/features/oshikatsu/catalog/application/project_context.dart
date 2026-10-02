/// EN: Project/unit selection state owned by the projects feature.
/// KO: projects 기능이 소유하는 프로젝트/유닛 선택 상태.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// EN: Selected project key provider (slug/code)
/// KO: 선택된 프로젝트 키 프로바이더 (slug/code)
final selectedProjectKeyProvider = StateProvider<String?>((ref) {
  return null;
});

/// EN: Selected project ID provider (UUID when available).
/// KO: 선택된 프로젝트 ID 프로바이더 (가능하면 UUID).
final selectedProjectIdProvider = StateProvider<String?>((ref) {
  return null;
});

/// EN: Selected unit IDs provider
/// KO: 선택된 유닛 ID 목록 프로바이더
final selectedUnitIdsProvider = StateProvider<List<String>>((ref) {
  return [];
});
