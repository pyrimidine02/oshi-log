/// EN: Riverpod providers and StateNotifier for the fan level (덕력) system.
/// KO: 팬 레벨(덕력) 시스템을 위한 Riverpod 프로바이더 및 StateNotifier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/fan_level_remote_data_source.dart';
import '../data/repositories/fan_level_repository_impl.dart';
import '../domain/entities/fan_level.dart';
import '../domain/repositories/fan_level_repository.dart';

// =============================================================================
// EN: Dependency provider
// KO: 의존성 프로바이더
// =============================================================================

/// EN: Provides the concrete [FanLevelRepository], wiring the remote data source.
///     Uses a sync [Provider] because [ApiClient] requires no async init.
/// KO: 원격 데이터 소스를 연결하여 구체적인 [FanLevelRepository]를 제공합니다.
///     [ApiClient]는 비동기 초기화가 필요 없으므로 동기 [Provider]를 사용합니다.
final fanLevelRepositoryProvider = Provider<FanLevelRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FanLevelRepositoryImpl(
    remoteDataSource: FanLevelRemoteDataSource(apiClient: apiClient),
  );
});

// =============================================================================
// EN: Fan level profile notifier
// KO: 팬 레벨 프로필 노티파이어
// =============================================================================

/// EN: Manages the fan level profile, including daily check-in support.
///     Loads on construction and exposes [refresh] and [checkIn] mutations.
/// KO: 일일 출석 체크 지원을 포함한 팬 레벨 프로필을 관리합니다.
///     생성 시 로드하며, [refresh]와 [checkIn] 변이를 제공합니다.
class FanLevelNotifier extends StateNotifier<AsyncValue<FanLevelProfile?>> {
  FanLevelNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final FanLevelRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.fetchProfile();
    if (!mounted) return;
    state = result.when(
      success: AsyncValue.data,
      failure: (f) {
        // EN: 404 means the user has no profile yet — show empty state, not error.
        // KO: 404는 아직 프로필이 없는 것이므로 에러가 아닌 빈 상태로 표시합니다.
        if (f is NotFoundFailure) return const AsyncValue.data(null);
        return AsyncValue.error(f, StackTrace.current);
      },
    );
  }

  /// EN: Reloads the fan level profile from the remote source.
  /// KO: 원격 소스에서 팬 레벨 프로필을 다시 불러옵니다.
  Future<void> refresh() => _load();

  /// EN: Performs the daily check-in, then refreshes the profile on success.
  ///     Returns the [CheckInResult] so the UI can show a confirmation message,
  ///     or null when the check-in fails.
  /// KO: 일일 출석 체크를 수행하고 성공 시 프로필을 새로 불러옵니다.
  ///     UI가 확인 메시지를 표시할 수 있도록 [CheckInResult]를 반환합니다.
  ///     출석 체크 실패 시 null을 반환합니다.
  Future<CheckInResult?> checkIn() async {
    final result = await _repository.checkIn();
    if (!mounted) return null;
    final checkInResult = result.when(success: (r) => r, failure: (_) => null);
    if (checkInResult != null) {
      await _load();
    }
    return checkInResult;
  }
}

// =============================================================================
// EN: Provider
// KO: 프로바이더
// =============================================================================

/// EN: Auto-disposing provider for [FanLevelNotifier].
///     Auto-disposed so fan level data is refreshed each time the page opens.
/// KO: [FanLevelNotifier]를 위한 자동 해제 프로바이더.
///     페이지가 열릴 때마다 팬 레벨 데이터를 새로 불러오도록 autoDispose를 사용합니다.
final fanLevelControllerProvider =
    StateNotifierProvider.autoDispose<
      FanLevelNotifier,
      AsyncValue<FanLevelProfile?>
    >((ref) {
      final repository = ref.watch(fanLevelRepositoryProvider);
      return FanLevelNotifier(repository);
    });

// =============================================================================
// EN: Internal placeholder notifiers for loading / error repository states.
// KO: 리포지토리 로딩/오류 상태용 내부 플레이스홀더 노티파이어.
// =============================================================================

class _LoadingFanLevelNotifier extends FanLevelNotifier {
  _LoadingFanLevelNotifier() : super(_NopFanLevelRepository()) {
    state = const AsyncValue.loading();
  }
}

class _ErrorFanLevelNotifier extends FanLevelNotifier {
  _ErrorFanLevelNotifier(Object error, StackTrace stack)
    : super(_NopFanLevelRepository()) {
    state = AsyncValue.error(error, stack);
  }
}

// =============================================================================
// EN: No-operation stub used only by placeholder notifiers.
// KO: 플레이스홀더 노티파이어에서만 사용되는 무작동 스텁.
// =============================================================================

class _NopFanLevelRepository implements FanLevelRepository {
  @override
  Future<Result<FanLevelProfile>> fetchProfile() async =>
      const Result.failure(UnknownFailure('not initialized'));

  @override
  Future<Result<CheckInResult>> checkIn() async =>
      const Result.failure(UnknownFailure('not initialized'));
}

// EN: Suppress unused warnings for the placeholder notifiers — they are
//     referenced only when the repository FutureProvider pattern is in use.
// KO: 플레이스홀더 노티파이어에 대한 미사용 경고를 억제합니다.
//     리포지토리 FutureProvider 패턴 사용 시에만 참조됩니다.
// ignore: unused_element
final _loadingRef = _LoadingFanLevelNotifier.new;
// ignore: unused_element
final _errorRef = _ErrorFanLevelNotifier.new;
