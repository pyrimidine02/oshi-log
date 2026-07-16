/// EN: Immutable presentation enrichment for place visit status.
/// KO: 장소 방문 상태를 위한 불변 프레젠테이션 보강 유틸리티.
library;

import '../entities/place_entities.dart';

/// EN: Marks places whose IDs occur in visit history without mutating the
///     repository-owned entities. Existing verified states remain true when
///     cached visit history is partial.
/// KO: 리포지토리 소유 엔티티를 변경하지 않고 방문 기록에 포함된 장소를
///     표시합니다. 캐시된 방문 기록이 일부뿐이어도 기존 인증 상태는 유지합니다.
List<PlaceSummary> applyVisitedPlaceIds(
  Iterable<PlaceSummary> places,
  Set<String> visitedPlaceIds,
) {
  return List<PlaceSummary>.unmodifiable(
    places.map(
      (place) => place.copyWith(
        isVerified: place.isVerified || visitedPlaceIds.contains(place.id),
      ),
    ),
  );
}
