/// EN: Project-safe navigation coordination for visit ledger entries.
/// KO: 방문 원장 항목을 위한 프로젝트 안전 내비게이션 조정입니다.
library;

import '../../../projects/domain/entities/project_entities.dart';
import 'field_visit_ledger_view_data.dart';

enum FieldVisitNavigationResult { opened, missingProjectContext }

/// EN: Selects the entry's owning project before navigating to visit detail.
/// KO: 방문 상세로 이동하기 전에 항목 소유 프로젝트를 먼저 선택합니다.
Future<FieldVisitNavigationResult> openFieldVisitLedgerEntry({
  required FieldPlaceLedgerEntry entry,
  required List<Project> projects,
  required String? selectedProjectKey,
  required String? selectedProjectId,
  required Future<void> Function(String projectKey, String projectId)
  selectProject,
  required void Function() navigate,
}) async {
  final projectId = entry.metadata?.projectId.trim();
  if (projectId == null || projectId.isEmpty) {
    return FieldVisitNavigationResult.missingProjectContext;
  }

  Project? owningProject;
  for (final project in projects) {
    if (project.id == projectId) {
      owningProject = project;
      break;
    }
  }
  if (owningProject == null) {
    return FieldVisitNavigationResult.missingProjectContext;
  }

  final projectKey = owningProject.code.trim().isNotEmpty
      ? owningProject.code.trim()
      : owningProject.id;
  if (selectedProjectKey != projectKey || selectedProjectId != projectId) {
    await selectProject(projectKey, projectId);
  }
  navigate();
  return FieldVisitNavigationResult.opened;
}
