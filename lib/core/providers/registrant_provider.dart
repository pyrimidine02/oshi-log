/// EN: Riverpod provider for the public contributors endpoint.
/// KO: 공개 기여자 목록 엔드포인트용 Riverpod 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../models/registrant_dto.dart';
import 'core_providers.dart';

/// EN: Key type identifying an entity for the contributors lookup.
/// KO: 기여자 조회 엔티티를 식별하는 키 타입.
typedef ContributorKey = ({String entityType, String entityId});

/// EN: Fetches the deduplicated contributor list for any entity. Public — no auth.
/// KO: 모든 엔티티의 중복 제거된 기여자 목록을 조회합니다. 공개 — 인증 불필요.
///
/// Usage:
/// ```dart
/// ref.watch(contributorsProvider((entityType: 'places', entityId: placeId)));
/// ```
final contributorsProvider = FutureProvider.autoDispose
    .family<List<ContributorDto>, ContributorKey>((ref, key) async {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.get<List<ContributorDto>>(
        ApiEndpoints.contributors(key.entityType, key.entityId),
        fromJson: _decodeContributors,
      );
      return result.getOrThrow();
    });

List<ContributorDto> _decodeContributors(dynamic json) {
  // EN: Plain array response.
  // KO: 평탄 배열 응답.
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(ContributorDto.fromJson)
        .toList();
  }
  // EN: Wrapped in a `data` envelope.
  // KO: `data` 래퍼에 감싸인 경우.
  if (json is Map<String, dynamic>) {
    final inner = json['data'];
    if (inner is List) {
      return inner
          .whereType<Map<String, dynamic>>()
          .map(ContributorDto.fromJson)
          .toList();
    }
  }
  return const [];
}
