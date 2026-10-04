/// EN: Repository contract for hybrid sponsored slots.
/// KO: 하이브리드 스폰서 슬롯을 위한 리포지토리 계약입니다.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/shared/ads/domain/entities/ad_slot_entities.dart';

abstract class AdsRepository {
  /// EN: Resolve the current slot decision from backend.
  /// KO: 현재 슬롯 결정을 백엔드에서 조회합니다.
  Future<Result<AdSlotDecision?>> getSlotDecision({
    required AdSlotRequest request,
    bool forceRefresh = false,
  });

  /// EN: Track ad event (impression/click).
  /// KO: 광고 이벤트(노출/클릭)를 추적합니다.
  Future<Result<void>> trackEvent({
    required AdEventType eventType,
    required AdSlotRequest request,
    String? decisionId,
    String? campaignId,
  });
}
