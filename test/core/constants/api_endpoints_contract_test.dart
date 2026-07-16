import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/constants/api_constants.dart';
import 'package:girlsbandtabi_app/core/constants/api_v3_endpoints_catalog.dart';

void main() {
  group('ApiEndpoints contract (v3 api-docs snapshot)', () {
    test('all client-used endpoints exist with expected methods', () {
      final checks = <({String path, String method})>[
        (path: ApiEndpoints.login, method: 'POST'),
        (path: ApiEndpoints.register, method: 'POST'),
        (path: ApiEndpoints.emailVerifications, method: 'POST'),
        (path: ApiEndpoints.emailVerificationsConfirm, method: 'POST'),
        (path: ApiEndpoints.refresh, method: 'POST'),
        (path: ApiEndpoints.logout, method: 'POST'),
        (path: ApiEndpoints.oauthCallback('{provider}'), method: 'GET'),
        (path: ApiEndpoints.projects, method: 'GET'),
        (path: ApiEndpoints.projectUnits('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.projectUnits('{projectId}'), method: 'POST'),
        (path: ApiEndpoints.projectUnitsSearch('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.projectUnit('{projectId}', '{unitSlug}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.projectUnit('{projectId}', '{unitSlug}'),
          method: 'PUT',
        ),
        (
          path: ApiEndpoints.projectUnit('{projectId}', '{unitSlug}'),
          method: 'DELETE',
        ),
        (
          path: ApiEndpoints.unitMembers('{projectId}', '{unitId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.unitMembers('{projectId}', '{unitId}'),
          method: 'POST',
        ),
        (
          path: ApiEndpoints.unitMember(
            '{projectId}',
            '{unitId}',
            '{memberId}',
          ),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.unitMember(
            '{projectId}',
            '{unitId}',
            '{memberId}',
          ),
          method: 'PUT',
        ),
        (
          path: ApiEndpoints.unitMember(
            '{projectId}',
            '{unitId}',
            '{memberId}',
          ),
          method: 'DELETE',
        ),
        (path: ApiEndpoints.projectVoiceActors('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.projectVoiceActor('{projectId}', '{voiceActorId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.projectVoiceActorMembers(
            '{projectId}',
            '{voiceActorId}',
          ),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.projectVoiceActorCredits(
            '{projectId}',
            '{voiceActorId}',
          ),
          method: 'GET',
        ),
        (path: ApiEndpoints.homeSummary, method: 'GET'),
        (path: ApiEndpoints.homeSummaryByProject, method: 'GET'),
        (path: ApiEndpoints.search, method: 'GET'),
        (path: ApiEndpoints.searchDiscoveryPopular, method: 'GET'),
        (path: ApiEndpoints.searchDiscoveryCategories, method: 'GET'),
        (path: ApiEndpoints.places('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.place('{projectId}', '{placeId}'), method: 'GET'),
        (path: ApiEndpoints.placesNearby('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.placesWithinBounds('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.placesRegionsAvailable('{projectId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.placesRegionsFilter('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.placesRegionsMapBounds('{projectId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.placeGuides('{placeId}'), method: 'GET'),
        (path: ApiEndpoints.placeComments('{placeId}'), method: 'GET'),
        (path: ApiEndpoints.placeComments('{placeId}'), method: 'POST'),
        (
          path: ApiEndpoints.placeComment('{placeId}', '{commentId}'),
          method: 'DELETE',
        ),
        (path: ApiEndpoints.rankingsMostVisited('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.rankingsMostLiked('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.rankingsUsers('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.rankingsCurrentUser('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.fanSubjects, method: 'GET'),
        (path: ApiEndpoints.fanSubject('{subjectId}'), method: 'GET'),
        (path: ApiEndpoints.fanSubjectChildren('{subjectId}'), method: 'GET'),
        (path: ApiEndpoints.myFanSubjects, method: 'GET'),
        (path: ApiEndpoints.myFanSubject('{subjectId}'), method: 'PUT'),
        (path: ApiEndpoints.myFanSubject('{subjectId}'), method: 'DELETE'),
        (path: ApiEndpoints.liveEvents('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.liveEvent('{projectId}', '{liveEventId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.liveEventAttendances('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.liveEventAttendance(
            '{projectId}',
            '{liveEventId}',
          ),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.liveEventAttendance(
            '{projectId}',
            '{liveEventId}',
          ),
          method: 'PUT',
        ),
        (
          path: ApiEndpoints.liveEventSetlist('{projectId}', '{liveEventId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.liveEventVerification(
            '{projectId}',
            '{liveEventId}',
          ),
          method: 'POST',
        ),
        (path: ApiEndpoints.musicAlbums('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.musicAlbum('{projectId}', '{albumId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.musicSongs('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.musicSong('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongLyrics('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongParts('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongCallGuide('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongVersions('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongVersion(
            '{projectId}',
            '{songId}',
            '{versionCode}',
          ),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongCredits('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongDifficulty('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongMediaLinks('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongAvailability('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.musicSongLiveContext('{projectId}', '{songId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.news('{projectId}'), method: 'GET'),
        (
          path: ApiEndpoints.newsDetail('{projectId}', '{newsId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.posts('{projectCode}'), method: 'GET'),
        (path: ApiEndpoints.posts('{projectCode}'), method: 'POST'),
        (path: ApiEndpoints.travelReviews('{projectCode}'), method: 'GET'),
        (path: ApiEndpoints.travelReviews('{projectCode}'), method: 'POST'),
        (
          path: ApiEndpoints.travelReview('{projectCode}', '{reviewId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.travelReview('{projectCode}', '{reviewId}'),
          method: 'PATCH',
        ),
        (
          path: ApiEndpoints.travelReview('{projectCode}', '{reviewId}'),
          method: 'DELETE',
        ),
        (path: ApiEndpoints.postsCursor('{projectCode}'), method: 'GET'),
        (path: ApiEndpoints.postsSearch('{projectCode}'), method: 'GET'),
        (path: ApiEndpoints.postsTrending('{projectCode}'), method: 'GET'),
        (
          path: ApiEndpoints.postsByAuthor('{projectCode}', '{userId}'),
          method: 'GET',
        ),
        (path: ApiEndpoints.post('{projectCode}', '{postId}'), method: 'GET'),
        (path: ApiEndpoints.post('{projectCode}', '{postId}'), method: 'PUT'),
        (
          path: ApiEndpoints.post('{projectCode}', '{postId}'),
          method: 'DELETE',
        ),
        (
          path: ApiEndpoints.postComments('{projectCode}', '{postId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.postComments('{projectCode}', '{postId}'),
          method: 'POST',
        ),
        (
          path: ApiEndpoints.postComment(
            '{projectCode}',
            '{postId}',
            '{commentId}',
          ),
          method: 'PUT',
        ),
        (
          path: ApiEndpoints.postComment(
            '{projectCode}',
            '{postId}',
            '{commentId}',
          ),
          method: 'DELETE',
        ),
        (
          path: ApiEndpoints.postLike('{projectCode}', '{postId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.postLike('{projectCode}', '{postId}'),
          method: 'POST',
        ),
        (
          path: ApiEndpoints.postLike('{projectCode}', '{postId}'),
          method: 'DELETE',
        ),
        (
          path: ApiEndpoints.postBookmark('{projectCode}', '{postId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.postBookmark('{projectCode}', '{postId}'),
          method: 'POST',
        ),
        (
          path: ApiEndpoints.postBookmark('{projectCode}', '{postId}'),
          method: 'DELETE',
        ),
        (
          path: ApiEndpoints.postCommentsThread('{projectCode}', '{postId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.commentsByAuthor('{projectCode}', '{userId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.moderationPost('{projectCode}', '{postId}'),
          method: 'DELETE',
        ),
        (
          path: ApiEndpoints.moderationPostComment(
            '{projectCode}',
            '{postId}',
            '{commentId}',
          ),
          method: 'DELETE',
        ),
        (path: ApiEndpoints.moderationBans('{projectCode}'), method: 'GET'),
        (
          path: ApiEndpoints.moderationBan('{projectCode}', '{userId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.moderationBan('{projectCode}', '{userId}'),
          method: 'POST',
        ),
        (
          path: ApiEndpoints.moderationBan('{projectCode}', '{userId}'),
          method: 'DELETE',
        ),
        (path: ApiEndpoints.communityRecommendedFeed, method: 'GET'),
        (path: ApiEndpoints.communityRecommendedFeedCursor, method: 'GET'),
        (path: ApiEndpoints.communityFollowingFeedCursor, method: 'GET'),
        (path: ApiEndpoints.communityTranslations, method: 'POST'),
        (path: ApiEndpoints.communitySubscriptions, method: 'GET'),
        (path: ApiEndpoints.communityReports, method: 'POST'),
        (path: ApiEndpoints.communityReportsMe, method: 'GET'),
        (path: ApiEndpoints.communityReport('{reportId}'), method: 'GET'),
        (path: ApiEndpoints.communityReport('{reportId}'), method: 'DELETE'),
        (path: ApiEndpoints.userMe, method: 'GET'),
        (path: ApiEndpoints.userMe, method: 'PATCH'),
        (path: ApiEndpoints.userMeAccessLevel, method: 'GET'),
        (path: ApiEndpoints.userProfile('{userId}'), method: 'GET'),
        (path: ApiEndpoints.userFollow('{userId}'), method: 'GET'),
        (path: ApiEndpoints.userFollow('{userId}'), method: 'POST'),
        (path: ApiEndpoints.userFollow('{userId}'), method: 'DELETE'),
        (path: ApiEndpoints.userFollowers('{userId}'), method: 'GET'),
        (path: ApiEndpoints.userFollowing('{userId}'), method: 'GET'),
        (path: ApiEndpoints.userBlocked('{userId}'), method: 'GET'),
        (path: ApiEndpoints.userBlocks, method: 'GET'),
        (path: ApiEndpoints.userBlocks, method: 'POST'),
        (path: ApiEndpoints.userBlock('{targetUserId}'), method: 'DELETE'),
        (path: ApiEndpoints.userFavorites, method: 'GET'),
        (path: ApiEndpoints.userFavorites, method: 'POST'),
        (path: ApiEndpoints.userFavorites, method: 'DELETE'),
        (path: ApiEndpoints.notifications, method: 'GET'),
        (path: ApiEndpoints.notificationRead('{id}'), method: 'POST'),
        (path: ApiEndpoints.notificationSettings, method: 'GET'),
        (path: ApiEndpoints.notificationSettings, method: 'PUT'),
        (path: ApiEndpoints.verificationConfig, method: 'GET'),
        (path: ApiEndpoints.verificationChallenge, method: 'GET'),
        (path: ApiEndpoints.verificationKeys, method: 'POST'),
        (
          path: ApiEndpoints.placeVerification('{projectId}', '{placeId}'),
          method: 'POST',
        ),
        (path: ApiEndpoints.userVisits, method: 'GET'),
        (path: ApiEndpoints.userVisitsSummary, method: 'GET'),
        (path: ApiEndpoints.userVisitDetail('{visitId}'), method: 'GET'),
        (path: ApiEndpoints.uploadsDirect, method: 'POST'),
        (path: ApiEndpoints.uploadsPresignedUrl, method: 'POST'),
        (path: ApiEndpoints.uploadsConfirm('{uploadId}'), method: 'POST'),
        (path: ApiEndpoints.uploadsMy, method: 'GET'),
        (path: ApiEndpoints.uploadsDelete('{uploadId}'), method: 'DELETE'),
        (path: ApiEndpoints.verificationAppeals('{projectId}'), method: 'GET'),
        (path: ApiEndpoints.verificationAppeals('{projectId}'), method: 'POST'),
        (path: ApiEndpoints.projectRoleRequests, method: 'GET'),
        (path: ApiEndpoints.projectRoleRequests, method: 'POST'),
        (path: ApiEndpoints.projectRoleRequest('{requestId}'), method: 'GET'),
        (
          path: ApiEndpoints.projectRoleRequest('{requestId}'),
          method: 'DELETE',
        ),
        (path: ApiEndpoints.adminUserAccessLevel('{userId}'), method: 'GET'),
        (path: ApiEndpoints.adminUserAccessGrants('{userId}'), method: 'POST'),
        (
          path: ApiEndpoints.adminUserAccessGrantRevoke(
            '{userId}',
            '{grantId}',
          ),
          method: 'POST',
        ),
        (path: ApiEndpoints.adminUsersNotificationsBroadcast, method: 'POST'),
        (path: ApiEndpoints.adminUsersNotificationsTestSend, method: 'POST'),
        (path: ApiEndpoints.adminDashboard, method: 'GET'),
        (path: ApiEndpoints.adminModerationDashboard, method: 'GET'),
        (path: ApiEndpoints.adminCommunityReports, method: 'GET'),
        (path: ApiEndpoints.adminCommunityReport('{reportId}'), method: 'GET'),
        (
          path: ApiEndpoints.adminCommunityReport('{reportId}'),
          method: 'PATCH',
        ),
        (
          path: ApiEndpoints.adminCommunityReportAssign('{reportId}'),
          method: 'PATCH',
        ),
        (path: ApiEndpoints.adminProjectRoleRequests, method: 'GET'),
        (
          path: ApiEndpoints.adminProjectRoleRequest('{requestId}'),
          method: 'GET',
        ),
        (
          path: ApiEndpoints.adminProjectRoleRequestReview('{requestId}'),
          method: 'PATCH',
        ),
        (path: ApiEndpoints.adminMediaDeletions, method: 'GET'),
        (
          path: ApiEndpoints.adminMediaDeletionApprove('{requestId}'),
          method: 'POST',
        ),
        (
          path: ApiEndpoints.adminMediaDeletionReject('{requestId}'),
          method: 'POST',
        ),
      ];

      for (final check in checks) {
        expect(
          ApiV3EndpointCatalog.containsPath(check.path),
          isTrue,
          reason: 'Path missing in v3 catalog: ${check.path}',
        );
        final methods =
            ApiV3EndpointCatalog.pathMethods[check.path] ?? const [];
        expect(
          methods.contains(check.method),
          isTrue,
          reason: 'Method ${check.method} missing for ${check.path}',
        );
      }
    });
  });
}
