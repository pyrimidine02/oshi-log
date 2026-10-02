/// EN: App-owned implementation of the verification success hook — refreshes
///     visits/summary/ranking/title caches so the verification feature does
///     not depend on those features directly.
/// KO: 인증 성공 훅의 app 소유 구현입니다 — verification feature가 다른
///     feature에 직접 의존하지 않고도 방문/요약/랭킹/칭호 캐시를
///     새로고침합니다.
library;

import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/features/identity/progression/application/titles_controller.dart';
import 'package:oshi_log/features/place/visits/application/visits_controller.dart';

/// EN: Refreshes visit-related state after a successful place verification.
/// KO: 장소 인증 성공 후 방문 관련 상태를 새로고침합니다.
Future<void> refreshVisitDataAfterVerification(Ref ref, String? placeId) async {
  await ref
      .read(userVisitsControllerProvider.notifier)
      .load(forceRefresh: true);
  if (placeId != null && placeId.isNotEmpty) {
    ref.invalidate(visitSummaryProvider(placeId));
  }
  ref.invalidate(userRankingProvider);
  // EN: Invalidate title caches so the next title-picker open reflects
  //     any titles auto-granted by the backend after verification.
  // KO: 칭호 캐시를 무효화하여 인증 후 백엔드에서 자동 부여된 칭호를
  //     다음 칭호 피커 열기 시 반영합니다.
  final titlesRepo = await ref.read(titlesRepositoryProvider.future);
  await titlesRepo.invalidateTitleCaches();
  unawaited(ref.read(activeTitleProvider.notifier).refresh());
}
