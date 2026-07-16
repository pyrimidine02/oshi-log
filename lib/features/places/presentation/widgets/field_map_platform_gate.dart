/// EN: Keeps native map platform views mounted only on the visible surface.
/// KO: 네이티브 지도 플랫폼 뷰를 보이는 화면에서만 유지합니다.
library;

/// EN: Returns whether the native map should render for the current route.
/// KO: 현재 라우트에서 네이티브 지도를 렌더링할지 반환합니다.
bool shouldRenderFieldMap({
  required bool isActive,
  required bool isRouteOffstage,
}) {
  return isActive && !isRouteOffstage;
}
