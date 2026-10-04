/// EN: Remote data source for banner API calls.
/// KO: 배너 API 호출을 위한 원격 데이터 소스.
library;

import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/progression/data/dto/banner_dto.dart';

/// EN: Remote data source that communicates with the banner endpoints.
/// KO: 배너 엔드포인트와 통신하는 원격 데이터 소스.
class BannerRemoteDataSource {
  const BannerRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // =========================================================================
  // EN: Active banner
  // KO: 활성 배너
  // =========================================================================

  /// EN: Fetches the currently active banner for the authenticated user.
  ///     Returns null data when no banner has been set.
  /// KO: 인증된 사용자의 현재 활성 배너를 가져옵니다.
  ///     배너가 설정되지 않은 경우 null 데이터를 반환합니다.
  Future<Result<ActiveBannerDto?>> fetchActiveBanner() async {
    final result = await _apiClient.get<ActiveBannerDto?>(
      ApiEndpoints.userBanner,
      fromJson: (json) {
        if (json == null || json is! Map<String, dynamic>) return null;
        return ActiveBannerDto.fromJson(json);
      },
    );
    return result;
  }

  /// EN: Sets the active banner for the authenticated user.
  /// KO: 인증된 사용자의 활성 배너를 설정합니다.
  Future<Result<ActiveBannerDto>> setActiveBanner(String bannerId) async {
    final result = await _apiClient.put<ActiveBannerDto>(
      ApiEndpoints.userBanner,
      data: {'bannerId': bannerId},
      fromJson: (json) => ActiveBannerDto.fromJson(
        json is Map<String, dynamic> ? json : <String, dynamic>{},
      ),
    );
    return result;
  }

  /// EN: Clears the active banner for the authenticated user.
  /// KO: 인증된 사용자의 활성 배너를 초기화합니다.
  Future<Result<void>> clearActiveBanner() async {
    final result = await _apiClient.delete<void>(ApiEndpoints.userBanner);
    return result;
  }

  /// EN: Fetches the full banner catalog with unlock status for the current user.
  /// KO: 현재 사용자의 해금 상태가 포함된 전체 배너 카탈로그를 가져옵니다.
  Future<Result<List<BannerItemDto>>> fetchBanners() async {
    final result = await _apiClient.get<List<BannerItemDto>>(
      ApiEndpoints.banners,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(BannerItemDto.fromJson)
              .toList(growable: false);
        }
        return const <BannerItemDto>[];
      },
    );
    return result;
  }
}
