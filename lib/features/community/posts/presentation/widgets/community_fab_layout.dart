import 'package:oshi_log/core/theme/gbt_spacing.dart';

/// EN: Resolves bottom padding for community compose FAB above curved nav bars.
/// KO: 곡률 하단바 위로 커뮤니티 작성 FAB를 올리기 위한 하단 패딩을 계산합니다.
double resolveCommunityFabBottomPadding({required double screenHeight}) {
  // EN: Keep iPhone 17 Pro Max as reference and scale proportionally.
  // KO: iPhone 17 Pro Max를 기준점으로 삼아 비례 스케일링합니다.
  const baselineScreenHeight = 932.0;
  const baselineVisualLiftCompensation = 38.0;
  const minVisualLiftCompensation = 28.0;
  const maxVisualLiftCompensation = 48.0;

  // EN: Community sub bottom nav visual block is 64dp base + 8dp shell padding.
  // KO: 커뮤니티 서브 하단바 시각 블록은 기본 64dp + 셸 패딩 8dp입니다.
  const subNavVisualHeight = GBTSpacing.bottomNavHeight + GBTSpacing.sm;
  // EN: Community sub bottom nav uses an extra 10dp bottom minimum inset.
  // KO: 커뮤니티 서브 하단바는 하단 최소 여백 10dp를 추가로 사용합니다.
  const subNavBottomInset = GBTSpacing.sm2;
  // EN: `FloatingActionButtonLocation.endFloat` already applies 16dp bottom margin.
  // KO: `FloatingActionButtonLocation.endFloat`는 기본 하단 여백 16dp를 포함합니다.
  const defaultFabFloatMargin = GBTSpacing.md;
  // EN: Keep the compose FAB about 5dp above nav top on both iOS and Android.
  // KO: iOS/Android 모두에서 작성 FAB를 하단바 상단 약 5dp 위로 유지합니다.
  const desiredGapAboveNav = 5.0;
  final normalizedScreenHeight = screenHeight <= 0
      ? baselineScreenHeight
      : screenHeight;
  final scaledVisualLiftCompensation =
      (baselineVisualLiftCompensation *
              (normalizedScreenHeight / baselineScreenHeight))
          .clamp(minVisualLiftCompensation, maxVisualLiftCompensation)
          .toDouble();
  // EN: Safe-area is already reflected in endFloat placement, so do not add
  // EN: it again to avoid iOS/Android over-elevation.
  // KO: endFloat 배치에 안전영역이 이미 반영되므로 다시 더하지 않아
  // KO: iOS/Android에서 과도하게 위로 뜨는 현상을 방지합니다.
  return subNavVisualHeight +
      subNavBottomInset +
      desiredGapAboveNav -
      defaultFabFloatMargin +
      scaledVisualLiftCompensation;
}
