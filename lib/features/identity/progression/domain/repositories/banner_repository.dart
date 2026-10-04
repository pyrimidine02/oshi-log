/// EN: Abstract repository interface for banner operations.
/// KO: 배너 작업을 위한 추상 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/progression/domain/entities/banner_entities.dart';

/// EN: Contract that all banner repository implementations must fulfill.
/// KO: 모든 배너 리포지토리 구현체가 이행해야 하는 계약.
abstract class BannerRepository {
  /// EN: Fetches the currently active banner for the authenticated user.
  ///     Returns [Success] with null when no banner is set.
  /// KO: 인증된 사용자의 현재 활성 배너를 가져옵니다.
  ///     배너가 설정되지 않은 경우 null과 함께 [Success]를 반환합니다.
  Future<Result<ActiveBanner?>> fetchActiveBanner();

  /// EN: Sets the active banner by its identifier.
  /// KO: 식별자로 활성 배너를 설정합니다.
  Future<Result<ActiveBanner>> setActiveBanner(String bannerId);

  /// EN: Clears the active banner — restores the default gradient background.
  /// KO: 활성 배너를 제거합니다 — 기본 그라디언트 배경으로 복원됩니다.
  Future<Result<void>> clearActiveBanner();

  /// EN: Fetches the full banner catalog with unlock state for the current user.
  /// KO: 현재 사용자의 해금 상태가 포함된 전체 배너 카탈로그를 가져옵니다.
  Future<Result<List<BannerItem>>> fetchBanners();
}
