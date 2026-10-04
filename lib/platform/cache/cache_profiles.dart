/// EN: Shared cache profile presets for feature repositories.
/// KO: 기능 리포지토리에서 공통으로 사용하는 캐시 프로필 프리셋입니다.
library;

import 'cache_manager.dart';

/// EN: A reusable cache profile with policy and TTL hints.
/// KO: 정책과 TTL 힌트를 함께 가지는 재사용 캐시 프로필입니다.
class CacheProfile {
  const CacheProfile({
    required this.readPolicy,
    this.ttl,
    this.revalidateAfter,
  });

  final CachePolicy readPolicy;
  final Duration? ttl;
  final Duration? revalidateAfter;

  /// EN: Returns effective policy considering user-triggered force refresh.
  /// KO: 사용자 강제 새로고침 여부를 반영한 최종 정책을 반환합니다.
  CachePolicy policyFor({required bool forceRefresh}) {
    return forceRefresh ? CachePolicy.networkFirst : readPolicy;
  }
}

/// EN: Centralized profile registry for current app read paths.
/// KO: 현재 앱 읽기 경로에 대한 중앙 프로필 레지스트리입니다.
abstract final class CacheProfiles {
  // EN: Home
  // KO: 홈
  static const homeSummary = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  // EN: Feed
  // KO: 피드
  static const feedNews = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 15),
  );

  static const feedPostList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const feedTrendingPosts = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const feedCommunitySubscriptions = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  static const feedPostDetail = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const feedPostComposeOptions = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 5),
  );

  static const feedPostComments = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  static const feedPostsByAuthor = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const feedCommentsByAuthor = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  static const feedReactionStatus = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 2),
    revalidateAfter: Duration(minutes: 1),
  );

  // EN: Favorites
  // KO: 즐겨찾기
  static const favoritesList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  // EN: Search
  // KO: 검색
  static const searchResults = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const searchPopularDiscovery = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  static const searchCategoryDiscovery = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  // EN: Live events
  // KO: 라이브 이벤트
  static const liveEventsList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  static const liveEventDetail = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  // EN: Places
  // KO: 장소
  static const placesStaticList = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(hours: 24),
    revalidateAfter: Duration(minutes: 30),
  );

  static const placesDetail = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 15),
  );

  static const placeGuides = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 10),
    revalidateAfter: Duration(minutes: 3),
  );

  static const placeComments = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 5),
    revalidateAfter: Duration(minutes: 2),
  );

  // EN: Projects
  // KO: 프로젝트
  static const projectsList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 30),
  );

  static const projectUnits = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 15),
  );

  static const projectUnitMembers = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 15),
  );

  static const voiceActorsList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  static const voiceActorDetail = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 20),
  );

  static const voiceActorMembers = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  static const voiceActorCredits = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  // EN: Visits
  // KO: 방문 기록
  static const visitsList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const visitsSummary = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const visitDetail = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const userRanking = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  // EN: Settings
  // KO: 설정
  static const settingsUserProfile = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  static const settingsUserProfileById = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const settingsNotificationSettings = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const settingsPrivacySettings = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  static const settingsPrivacyRequests = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 2),
  );

  static const settingsConsentHistory = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 10),
  );

  static const settingsUserBlocks = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 5),
  );

  static const settingsProjectRoleRequests = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 2),
  );

  static const settingsVerificationAppeals = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  // EN: Notifications
  // KO: 알림
  static const notificationsList = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 1),
  );

  // EN: Uploads
  // KO: 업로드
  static const uploadsMy = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 5),
    revalidateAfter: Duration(minutes: 2),
  );

  // EN: Admin ops
  // KO: 관리자 운영
  static const adminDashboard = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 3),
  );

  static const adminCommunityReports = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 2),
  );

  static const adminCommunityReportDetail = CacheProfile(
    readPolicy: CachePolicy.cacheFirst,
    ttl: Duration(minutes: 5),
    revalidateAfter: Duration(minutes: 1),
  );

  static const adminProjectRoleRequests = CacheProfile(
    readPolicy: CachePolicy.staleWhileRevalidate,
    ttl: Duration(minutes: 1),
  );
}
