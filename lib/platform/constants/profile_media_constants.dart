/// EN: Shared profile media constants for crop and render consistency.
/// KO: 크롭/표시 일관성을 위한 프로필 미디어 공통 상수입니다.
library;

/// EN: Cover crop ratio X value.
/// KO: 커버 크롭 비율 X 값입니다.
const double profileCoverCropRatioX = 16;

/// EN: Cover crop ratio Y value.
/// KO: 커버 크롭 비율 Y 값입니다.
const double profileCoverCropRatioY = 9;

/// EN: Cover aspect ratio used by both editor preview and profile header.
/// KO: 편집 미리보기와 프로필 헤더에서 공통으로 사용하는 커버 비율입니다.
const double profileCoverAspectRatio =
    profileCoverCropRatioX / profileCoverCropRatioY;

/// EN: Maximum width for uploaded cover image.
/// KO: 업로드 커버 이미지 최대 너비입니다.
const int profileCoverMaxWidth = 2560;

/// EN: Maximum height for uploaded cover image.
/// KO: 업로드 커버 이미지 최대 높이입니다.
const int profileCoverMaxHeight = 1440;
