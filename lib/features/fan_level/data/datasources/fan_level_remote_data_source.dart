/// EN: Remote data source for the fan level system.
/// KO: 팬 레벨 시스템의 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/fan_level_dto.dart';

/// EN: Communicates with the fan level API endpoints.
///     All methods return [Result] so callers can handle errors without try/catch.
/// KO: 팬 레벨 API 엔드포인트와 통신합니다.
///     모든 메서드는 [Result]를 반환하므로 호출자가 try/catch 없이 오류를 처리할 수 있습니다.
class FanLevelRemoteDataSource {
  const FanLevelRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// EN: Fetches the authenticated user's fan level profile.
  /// KO: 인증된 사용자의 팬 레벨 프로필을 가져옵니다.
  Future<Result<FanLevelProfileDto>> fetchProfile() {
    return _apiClient.get<FanLevelProfileDto>(
      ApiEndpoints.fanLevelProfile,
      fromJson: (json) => FanLevelProfileDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Performs the daily check-in for the authenticated user.
  /// KO: 인증된 사용자의 일일 출석 체크를 수행합니다.
  Future<Result<CheckInResultDto>> checkIn() {
    return _apiClient.post<CheckInResultDto>(
      ApiEndpoints.fanLevelCheckIn,
      fromJson: (json) => CheckInResultDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }
}
