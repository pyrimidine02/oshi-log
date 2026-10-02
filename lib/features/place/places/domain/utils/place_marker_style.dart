/// EN: Map marker hues aligned with the field-notes palette.
/// KO: 필드 노트 팔레트와 정렬된 지도 마커 hue.
library;

/// EN: Marker hue for a single-place pin based on GPS-verified visit status.
/// Verified (visited) places render in a teal hue approximating
/// `GBTColors.fieldTeal`; unvisited places use a blue hue approximating
/// `GBTColors.fieldBlue`. `BitmapDescriptor` only
/// accepts a hue (not an arbitrary RGB), so these values are tuned to sit as
/// close as possible to the brand colors within that model.
/// KO: GPS 인증(방문) 상태에 따른 단일 장소 핀의 마커 hue. 인증된(방문한)
/// 장소는 `GBTColors.fieldTeal`에 근접한 틸 hue로, 미방문 장소는
/// `GBTColors.fieldBlue`에 근접한 블루 hue로 렌더링합니다.
/// `BitmapDescriptor`는 임의의 RGB가 아닌 hue만 지원하므로, 해당 모델 안에서
/// 브랜드 색상에 가장 가깝도록 값을 조정했습니다.
double placeMarkerHueForVisit({required bool isVerified}) {
  return isVerified ? 176.0 : 210.0;
}

/// EN: Marker hue for a cluster pin (multiple nearby places grouped at the
/// current zoom level) — itinerary amber, so clusters remain distinct from
/// visited and unvisited pins.
/// KO: 클러스터 핀(현재 줌 레벨에서 인접한 여러 장소를 묶은 것)의 마커 hue —
/// 방문 및 미방문 핀과 구분되는 일정 앰버를 사용합니다.
const double placeClusterMarkerHue = 38.0;
