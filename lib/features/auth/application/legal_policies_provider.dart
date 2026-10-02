/// EN: Legal policy list provider — fetches from the public server endpoint.
/// KO: 공개 서버 엔드포인트에서 법률 정책 목록을 가져오는 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/legal_policy_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart' show apiClientProvider;
import '../../../core/utils/result.dart';
import '../data/datasources/auth_remote_data_source.dart';

/// EN: Fetches the latest legal policy list from the public server endpoint.
///     Fails instead of falling back to bundled constants: a consent recorded
///     against a stale local version makes the server demand re-consent right
///     after signup. Display surfaces may still fall back through
///     [resolveLegalPolicy]; consent submission must await this provider.
/// KO: 공개 서버 엔드포인트에서 최신 법률 정책 목록을 가져옵니다.
///     내장 상수로 폴백하지 않고 실패합니다 — 오래된 로컬 버전으로 동의를
///     기록하면 가입 직후 서버가 재동의를 요구하기 때문입니다. 화면 표시는
///     [resolveLegalPolicy]로 폴백할 수 있지만, 동의 제출은 이 프로바이더를
///     반드시 await 해야 합니다.
final legalPoliciesProvider = FutureProvider<List<LegalPolicyInfo>>((
  ref,
) async {
  final apiClient = ref.read(apiClientProvider);
  final result = await AuthRemoteDataSource(apiClient).fetchLegalPolicies();
  if (result is Success<List<Map<String, dynamic>>>) {
    final parsed = result.data
        .map(LegalPolicyInfo.fromJson)
        .whereType<LegalPolicyInfo>()
        .toList(growable: false);
    final hasAll = {
      LegalPolicyType.termsOfService,
      LegalPolicyType.privacyPolicy,
      LegalPolicyType.locationTerms,
    }.every((t) => parsed.any((p) => p.type == t));
    if (hasAll) return parsed;
  }
  throw const ServerFailure(
    'Legal policies unavailable',
    code: 'LEGAL_POLICIES_UNAVAILABLE',
  );
});
