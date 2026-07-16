/// EN: Repository interface for the fan level system.
/// KO: 팬 레벨 시스템의 리포지토리 인터페이스.
library;

import '../../../../core/utils/result.dart';
import '../entities/fan_level.dart';

/// EN: Defines the contract for fan level data operations.
///     Implementations may use remote API, local cache, or both.
/// KO: 팬 레벨 데이터 작업의 계약을 정의합니다.
///     구현체는 원격 API, 로컬 캐시 또는 둘 다 사용할 수 있습니다.
abstract class FanLevelRepository {
  /// EN: Fetches the authenticated user's fan level profile.
  /// KO: 인증된 사용자의 팬 레벨 프로필을 가져옵니다.
  Future<Result<FanLevelProfile>> fetchProfile();

  /// EN: Performs the daily check-in and returns the result.
  /// KO: 일일 출석 체크를 수행하고 결과를 반환합니다.
  Future<Result<CheckInResult>> checkIn();
}
