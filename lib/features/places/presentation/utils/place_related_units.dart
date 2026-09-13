/// EN: Helpers for resolving the bands explicitly related to a place.
/// KO: 장소에 명시적으로 연결된 밴드를 찾는 헬퍼입니다.
library;

import '../../../projects/domain/entities/project_entities.dart';
import '../../domain/entities/place_entities.dart';

/// EN: Returns only loaded project units referenced by the place contract.
/// KO: 장소 계약에 명시된 유닛 중 현재 로드된 프로젝트 유닛만 반환합니다.
List<Unit> unitsForPlace(PlaceDetail place, List<Unit> projectUnits) {
  if (place.unitIds.isEmpty || projectUnits.isEmpty) {
    return const <Unit>[];
  }

  final relatedUnitIds = place.unitIds.toSet();
  return List.unmodifiable(
    projectUnits.where((unit) => relatedUnitIds.contains(unit.id)),
  );
}
