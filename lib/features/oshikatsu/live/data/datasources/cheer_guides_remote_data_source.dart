/// EN: Remote data source for cheer guides.
/// KO: 응원 가이드의 원격 데이터 소스.
library;

import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/data/dto/cheer_guide_dto.dart';

/// EN: Fetches cheer guide data from the remote API.
/// KO: 원격 API에서 응원 가이드 데이터를 가져옵니다.
class CheerGuidesRemoteDataSource {
  const CheerGuidesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// EN: Fetch the list of cheer guide summaries, optionally filtered by project.
  /// KO: 응원 가이드 요약 목록을 가져옵니다 (프로젝트 필터 선택 가능).
  Future<Result<List<CheerGuideSummaryDto>>> fetchSummaries({
    String? projectId,
  }) {
    return apiClient.get<List<CheerGuideSummaryDto>>(
      ApiEndpoints.cheerGuides,
      queryParameters: {
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
      },
      fromJson: (json) {
        List<dynamic> items;
        if (json is List) {
          items = json;
        } else if (json is Map<String, dynamic>) {
          items =
              (json['guides'] ?? json['items'] ?? json['data'] ?? const [])
                  as List<dynamic>;
        } else {
          items = const [];
        }
        return items
            .whereType<Map<String, dynamic>>()
            .map(CheerGuideSummaryDto.fromJson)
            .toList(growable: false);
      },
    );
  }

  /// EN: Fetch full cheer guide detail including all sections.
  /// KO: 모든 섹션을 포함한 응원 가이드 상세 정보를 가져옵니다.
  Future<Result<CheerGuideDto>> fetchGuideDetail(String guideId) {
    return apiClient.get<CheerGuideDto>(
      ApiEndpoints.cheerGuide(guideId),
      fromJson: (json) => CheerGuideDto.fromJson(json as Map<String, dynamic>),
    );
  }
}
