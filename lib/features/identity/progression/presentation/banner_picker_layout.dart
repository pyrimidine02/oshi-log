/// EN: Responsive layout policy for the profile-banner catalog.
/// KO: 프로필 배너 카탈로그의 반응형 레이아웃 정책입니다.
library;

/// EN: Immutable grid parameters selected for the available width.
/// KO: 사용 가능한 너비에 따라 선택되는 불변 그리드 매개변수입니다.
class BannerPickerLayout {
  const BannerPickerLayout({
    required this.columns,
    required this.childAspectRatio,
  });

  final int columns;
  final double childAspectRatio;
}

/// EN: Uses a single readable banner on narrow screens, then progressively
/// adds columns without ever creating the former fixed three-column squeeze.
/// KO: 좁은 화면에서는 읽기 쉬운 한 열을 사용하고, 기존 고정 3열 압축 없이
/// 너비가 넓어질 때만 점진적으로 열을 추가합니다.
BannerPickerLayout resolveBannerPickerLayout(double width) {
  if (width < 360) {
    return const BannerPickerLayout(columns: 1, childAspectRatio: 2.0);
  }
  if (width < 720) {
    return const BannerPickerLayout(columns: 2, childAspectRatio: 1.45);
  }
  return const BannerPickerLayout(columns: 3, childAspectRatio: 1.6);
}
