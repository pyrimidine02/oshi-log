/// EN: Remote datasource for ad slot decisions and tracking.
/// KO: 광고 슬롯 결정 및 추적을 위한 원격 데이터소스입니다.
library;

import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/shared/ads/data/dto/ad_slot_decision_dto.dart';

class AdsRemoteDataSource {
  const AdsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;
  static const String _legacyAdsDecisionPath = '/api/v1/ads/decisions';
  static const String _legacyAdsEventPath = '/api/v1/ads/event';

  Future<Result<AdSlotDecisionDto?>> fetchSlotDecision({
    required String slot,
    required int ordinal,
    String? projectKey,
  }) async {
    final query = <String, dynamic>{
      'slot': slot,
      'ordinal': ordinal,
      if (projectKey != null && projectKey.isNotEmpty) ...{
        'projectKey': projectKey,
        // EN: Compatibility key for servers using projectCode query.
        // KO: projectCode 쿼리를 사용하는 서버 호환 키입니다.
        'projectCode': projectKey,
      },
    };

    final result = await _fetchSlotDecisionFromPath(
      path: ApiEndpoints.adsDecision,
      query: query,
    );
    if (_isNotFound(result)) {
      return _fetchSlotDecisionFromPath(
        path: _legacyAdsDecisionPath,
        query: query,
      );
    }
    return result;
  }

  Future<Result<AdSlotDecisionDto?>> _fetchSlotDecisionFromPath({
    required String path,
    required Map<String, dynamic> query,
  }) async {
    final result = await _apiClient.get<dynamic>(path, queryParameters: query);

    if (result is Err<dynamic>) {
      return Result.failure(result.failure);
    }
    if (result is! Success<dynamic>) {
      return const Result.success(null);
    }

    final payload = result.data;
    if (payload is! Map<String, dynamic>) {
      return const Result.success(null);
    }
    return Result.success(AdSlotDecisionDto.fromJson(payload));
  }

  Future<Result<void>> trackEvent(AdEventRequestDto request) async {
    final payload = request.toJson();
    final result = await _postEvent(ApiEndpoints.adsEvents, payload);
    if (_isNotFound(result)) {
      return _postEvent(_legacyAdsEventPath, payload);
    }
    return result;
  }

  Future<Result<void>> _postEvent(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final result = await _apiClient.post<dynamic>(path, data: payload);
    if (result is Err<dynamic>) {
      return Result.failure(result.failure);
    }
    return const Result.success(null);
  }

  bool _isNotFound(Result<dynamic> result) {
    return result is Err<dynamic> &&
        result.failure is NotFoundFailure &&
        result.failure.code == '404';
  }
}
