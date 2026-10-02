/// EN: Remote data source for titles API calls.
/// KO: 칭호(Title) API 호출을 위한 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/identity/progression/data/dto/title_dto.dart';

/// EN: Remote data source that communicates with the titles endpoints.
///     Endpoint constants will be migrated to [ApiEndpoints] in a future task.
/// KO: 칭호 엔드포인트와 통신하는 원격 데이터 소스.
///     엔드포인트 상수는 향후 작업에서 [ApiEndpoints]로 이전될 예정입니다.
class TitlesRemoteDataSource {
  const TitlesRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ===========================================================================
  // EN: Catalog
  // KO: 칭호 카탈로그
  // ===========================================================================

  /// EN: Fetches the full title catalog.
  ///     When the caller is authenticated, [TitleCatalogItemDto.isEarned] and
  ///     [TitleCatalogItemDto.isActive] are populated by the server.
  ///     Unauthenticated callers receive both fields as null.
  /// KO: 전체 칭호 카탈로그를 가져옵니다.
  ///     인증된 호출자의 경우 서버가 [TitleCatalogItemDto.isEarned]와
  ///     [TitleCatalogItemDto.isActive]를 채워 반환합니다.
  ///     비인증 호출자는 두 필드를 null로 받습니다.
  Future<Result<List<TitleCatalogItemDto>>> fetchTitleCatalog({
    String? projectKey,
  }) async {
    return _apiClient.get<List<TitleCatalogItemDto>>(
      ApiEndpoints.titles,
      queryParameters: projectKey != null ? {'projectKey': projectKey} : null,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(TitleCatalogItemDto.fromJson)
              .toList(growable: false);
        }
        return const <TitleCatalogItemDto>[];
      },
    );
  }

  // ===========================================================================
  // EN: Authenticated user — own active title
  // KO: 인증된 사용자 — 본인 활성 칭호
  // ===========================================================================

  /// EN: Fetches the active title of the authenticated user.
  ///     Returns null data when no title is set (HTTP 204 from server).
  /// KO: 인증된 사용자의 활성 칭호를 가져옵니다.
  ///     칭호가 설정되지 않은 경우 null 데이터를 반환합니다 (서버 HTTP 204).
  Future<Result<ActiveTitleItemDto?>> fetchMyActiveTitle({
    String? projectKey,
  }) async {
    return _apiClient.get<ActiveTitleItemDto?>(
      ApiEndpoints.userMeTitle,
      queryParameters: projectKey != null ? {'projectKey': projectKey} : null,
      fromJson: (json) {
        // EN: HTTP 204 surfaces as null data; guard accordingly.
        // KO: HTTP 204는 null 데이터로 전달됩니다. 이를 처리합니다.
        if (json == null || json is! Map<String, dynamic>) return null;
        return ActiveTitleItemDto.fromJson(json);
      },
    );
  }

  /// EN: Sets the active title for the authenticated user.
  ///     The server responds with the newly active [ActiveTitleItemDto].
  /// KO: 인증된 사용자의 활성 칭호를 설정합니다.
  ///     서버는 새롭게 활성화된 [ActiveTitleItemDto]를 반환합니다.
  Future<Result<ActiveTitleItemDto>> setMyActiveTitle(
    String titleId, {
    String? projectKey,
  }) async {
    return _apiClient.put<ActiveTitleItemDto>(
      ApiEndpoints.userMeTitle,
      data: {'titleId': titleId},
      queryParameters: projectKey != null ? {'projectKey': projectKey} : null,
      fromJson: (json) => ActiveTitleItemDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Clears the active title for the authenticated user (HTTP 204).
  /// KO: 인증된 사용자의 활성 칭호를 초기화합니다 (HTTP 204).
  Future<Result<void>> clearMyActiveTitle({String? projectKey}) async {
    return _apiClient.delete<void>(
      ApiEndpoints.userMeTitle,
      queryParameters: projectKey != null ? {'projectKey': projectKey} : null,
    );
  }

  // ===========================================================================
  // EN: Other user — public active title
  // KO: 다른 사용자 — 공개 활성 칭호
  // ===========================================================================

  /// EN: Fetches the active title of an arbitrary user by [userId].
  ///     Returns null data when the user has no active title (HTTP 204).
  /// KO: [userId]로 지정된 임의 사용자의 활성 칭호를 가져옵니다.
  ///     사용자에게 활성 칭호가 없으면 null 데이터를 반환합니다 (HTTP 204).
  Future<Result<ActiveTitleItemDto?>> fetchUserActiveTitle(
    String userId, {
    String? projectKey,
  }) async {
    return _apiClient.get<ActiveTitleItemDto?>(
      ApiEndpoints.userTitle(userId),
      queryParameters: projectKey != null ? {'projectKey': projectKey} : null,
      fromJson: (json) {
        // EN: HTTP 204 surfaces as null data; guard accordingly.
        // KO: HTTP 204는 null 데이터로 전달됩니다. 이를 처리합니다.
        if (json == null || json is! Map<String, dynamic>) return null;
        return ActiveTitleItemDto.fromJson(json);
      },
    );
  }
}
