/// EN: Repository implementation for hybrid ad slot decisions.
/// KO: 하이브리드 광고 슬롯 결정을 위한 리포지토리 구현입니다.
library;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/shared/ads/domain/entities/ad_slot_entities.dart';
import 'package:oshi_log/features/shared/ads/domain/repositories/ads_repository.dart';
import 'package:oshi_log/features/shared/ads/data/datasources/ads_remote_data_source.dart';
import 'package:oshi_log/features/shared/ads/data/dto/ad_slot_decision_dto.dart';

class AdsRepositoryImpl implements AdsRepository {
  AdsRepositoryImpl({required AdsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AdsRemoteDataSource _remoteDataSource;

  static const Duration _decisionTtl = Duration(minutes: 2);

  final Map<String, _DecisionCacheEntry> _decisionCache =
      <String, _DecisionCacheEntry>{};

  @override
  Future<Result<AdSlotDecision?>> getSlotDecision({
    required AdSlotRequest request,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(request);
    final cached = _decisionCache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _decisionTtl) {
      return Result.success(cached.decision);
    }

    final remoteResult = await _remoteDataSource.fetchSlotDecision(
      slot: request.placement.apiKey,
      ordinal: request.ordinal,
      projectKey: request.projectKey,
    );
    if (remoteResult is Err<AdSlotDecisionDto?>) {
      return Result.failure(remoteResult.failure);
    }
    if (remoteResult is! Success<AdSlotDecisionDto?>) {
      return const Result.success(null);
    }

    final dto = remoteResult.data;
    if (dto == null) {
      _decisionCache[cacheKey] = _DecisionCacheEntry(
        decision: null,
        cachedAt: DateTime.now(),
      );
      return const Result.success(null);
    }

    final decision = dto.toDomain(request.placement);
    _decisionCache[cacheKey] = _DecisionCacheEntry(
      decision: decision,
      cachedAt: DateTime.now(),
    );
    return Result.success(decision);
  }

  @override
  Future<Result<void>> trackEvent({
    required AdEventType eventType,
    required AdSlotRequest request,
    String? decisionId,
    String? campaignId,
  }) {
    final normalizedDecisionId = decisionId?.trim();
    if (normalizedDecisionId == null || normalizedDecisionId.isEmpty) {
      // EN: Backend requires decisionId for event ingestion.
      // KO: 백엔드 이벤트 수집은 decisionId를 필수로 요구합니다.
      return Future.value(const Result<void>.success(null));
    }
    return _remoteDataSource.trackEvent(
      AdEventRequestDto(
        eventType: eventType.apiKey,
        slot: request.placement.apiKey,
        ordinal: request.ordinal,
        projectKey: request.projectKey,
        decisionId: normalizedDecisionId,
        campaignId: campaignId,
      ),
    );
  }

  String _cacheKey(AdSlotRequest request) {
    final project = request.projectKey ?? '-';
    return '${request.placement.apiKey}:${request.ordinal}:$project';
  }
}

class _DecisionCacheEntry {
  const _DecisionCacheEntry({required this.decision, required this.cachedAt});

  final AdSlotDecision? decision;
  final DateTime cachedAt;
}
