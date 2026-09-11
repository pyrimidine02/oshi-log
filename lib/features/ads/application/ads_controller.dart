/// EN: Providers/controllers for hybrid ad slots.
/// KO: 하이브리드 광고 슬롯용 프로바이더/컨트롤러입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/ads_remote_data_source.dart';
import '../data/repositories/ads_repository_impl.dart';
import '../domain/entities/ad_slot_entities.dart';
import '../domain/repositories/ads_repository.dart';
import 'ads_runtime_service.dart';

/// EN: Consent-gated lifecycle for optional network ads.
/// KO: 선택적 네트워크 광고를 위한 동의 기반 생명주기입니다.
final adsRuntimeServiceProvider = Provider<AdsRuntimeService>((ref) {
  final service = AdsRuntimeService();
  ref.onDispose(service.dispose);
  return service;
});

/// EN: Whether the consent SDK requires a visible privacy-options entry point.
/// KO: 동의 SDK가 개인정보 옵션 진입점 표시를 요구하는지 반환합니다.
final adsPrivacyOptionsRequiredProvider = FutureProvider<bool>((ref) {
  return ref.watch(adsRuntimeServiceProvider).isPrivacyOptionsRequired();
});

/// EN: Ads repository provider.
/// KO: 광고 리포지토리 프로바이더입니다.
final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdsRepositoryImpl(remoteDataSource: AdsRemoteDataSource(apiClient));
});

/// EN: Slot decision provider with short-lived cache in repository.
/// KO: 리포지토리의 단기 캐시를 활용하는 슬롯 결정 프로바이더입니다.
final adSlotDecisionProvider = FutureProvider.autoDispose
    .family<AdSlotDecision?, AdSlotRequest>((ref, request) async {
      final repository = ref.watch(adsRepositoryProvider);
      final result = await repository.getSlotDecision(request: request);
      if (result is Success<AdSlotDecision?>) {
        return result.data;
      }
      return null;
    });

/// EN: Controller for fire-and-forget ad event tracking.
/// KO: 광고 이벤트 fire-and-forget 추적 컨트롤러입니다.
class AdEventTrackerController {
  const AdEventTrackerController(this._ref);

  final Ref _ref;

  Future<void> track({
    required AdEventType eventType,
    required AdSlotRequest request,
    String? decisionId,
    String? campaignId,
  }) async {
    final repository = _ref.read(adsRepositoryProvider);
    final result = await repository.trackEvent(
      eventType: eventType,
      request: request,
      decisionId: decisionId,
      campaignId: campaignId,
    );
    if (result is Err<void>) {
      // EN: Deliberately swallow event-tracking failures.
      // KO: 이벤트 추적 실패는 의도적으로 무시합니다.
      return;
    }
  }
}

/// EN: Ad event tracker provider.
/// KO: 광고 이벤트 추적기 프로바이더입니다.
final adEventTrackerProvider = Provider<AdEventTrackerController>((ref) {
  return AdEventTrackerController(ref);
});
