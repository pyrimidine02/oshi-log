/// EN: Abstract repository interface for the title (칭호) system.
/// KO: 칭호(Title) 시스템을 위한 추상 리포지토리 인터페이스.
library;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/identity/progression/domain/entities/title_entities.dart';

/// EN: Contract that all title repository implementations must fulfill.
///     All methods accept an optional [projectKey] parameter to scope
///     the request to a specific project; null means the global scope.
/// KO: 모든 칭호 리포지토리 구현체가 이행해야 하는 계약.
///     모든 메서드는 선택적 [projectKey] 파라미터를 받아 요청 범위를
///     특정 프로젝트로 제한합니다; null 이면 전역 범위입니다.
abstract class TitlesRepository {
  /// EN: Fetches the full title catalog, optionally filtered to a project.
  ///     When the user is authenticated the returned items include
  ///     [TitleCatalogItem.isEarned] and [TitleCatalogItem.isActive] flags.
  ///     For unauthenticated callers those flags are null.
  /// KO: 전체 칭호 카탈로그를 가져옵니다. [projectKey] 가 있으면 해당
  ///     프로젝트 범위로 필터링됩니다.
  ///     인증된 사용자의 경우 반환 항목에 [TitleCatalogItem.isEarned] 와
  ///     [TitleCatalogItem.isActive] 플래그가 포함됩니다.
  ///     비인증 호출자의 경우 해당 플래그는 null 입니다.
  Future<Result<List<TitleCatalogItem>>> fetchTitleCatalog({
    String? projectKey,
  });

  /// EN: Fetches the currently active title of the authenticated user.
  ///     Returns [Success] with null when no title is set.
  /// KO: 인증된 사용자의 현재 활성 칭호를 가져옵니다.
  ///     칭호가 설정되지 않은 경우 null 과 함께 [Success] 를 반환합니다.
  Future<Result<ActiveTitleItem?>> fetchMyActiveTitle({String? projectKey});

  /// EN: Sets the authenticated user's active title by its server-side ID.
  ///     Returns the updated [ActiveTitleItem] on success.
  /// KO: 서버 측 ID 로 인증된 사용자의 활성 칭호를 설정합니다.
  ///     성공 시 업데이트된 [ActiveTitleItem] 을 반환합니다.
  Future<Result<ActiveTitleItem>> setMyActiveTitle(
    String titleId, {
    String? projectKey,
  });

  /// EN: Clears the authenticated user's active title, restoring the default
  ///     (no title displayed) state.
  /// KO: 인증된 사용자의 활성 칭호를 해제하여 기본 상태(칭호 미표시)로
  ///     복원합니다.
  Future<Result<void>> clearMyActiveTitle({String? projectKey});

  /// EN: Fetches the currently active title for an arbitrary user by their ID.
  ///     Returns [Success] with null when the target user has no title set.
  /// KO: 특정 사용자 ID 에 해당하는 사용자의 현재 활성 칭호를 가져옵니다.
  ///     대상 사용자가 칭호를 설정하지 않은 경우 null 과 함께 [Success] 를
  ///     반환합니다.
  Future<Result<ActiveTitleItem?>> fetchUserActiveTitle(
    String userId, {
    String? projectKey,
  });

  /// EN: Invalidates the local title caches so the next fetch retrieves fresh
  ///     data from the server. Call after events that may change earned/active
  ///     title state (e.g. place verification).
  /// KO: 로컬 칭호 캐시를 무효화하여 다음 조회 시 서버에서 신선한 데이터를
  ///     가져오도록 합니다. 획득/활성 칭호 상태가 변경될 수 있는 이벤트
  ///     (예: 장소 인증) 이후에 호출합니다.
  Future<void> invalidateTitleCaches();
}
