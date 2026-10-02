/// EN: Helpers for filtering/sorting project community bans in admin UI.
/// KO: 관리자 UI에서 프로젝트 커뮤니티 제재 목록 필터/정렬을 위한 헬퍼입니다.
library;

import '../domain/entities/community_moderation.dart';

enum CommunityBanSortOption { newest, oldest, expiresSoon }

List<ProjectCommunityBan> filterAndSortCommunityBans({
  required List<ProjectCommunityBan> bans,
  String query = '',
  CommunityBanSortOption sortOption = CommunityBanSortOption.newest,
  bool onlyPermanent = false,
  bool hideExpired = false,
  DateTime? now,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final nowValue = now ?? DateTime.now();

  final filtered = bans.where((ban) {
    if (onlyPermanent && ban.expiresAt != null) {
      return false;
    }
    if (hideExpired &&
        ban.expiresAt != null &&
        ban.expiresAt!.isBefore(nowValue)) {
      return false;
    }
    if (normalizedQuery.isEmpty) {
      return true;
    }
    final displayName = ban.bannedUserDisplayName?.toLowerCase() ?? '';
    final email = ban.bannedUserEmail?.toLowerCase() ?? '';
    final userId = ban.bannedUserId.toLowerCase();
    final reason = ban.reason?.toLowerCase() ?? '';
    return displayName.contains(normalizedQuery) ||
        email.contains(normalizedQuery) ||
        userId.contains(normalizedQuery) ||
        reason.contains(normalizedQuery);
  }).toList();

  filtered.sort((a, b) {
    switch (sortOption) {
      case CommunityBanSortOption.newest:
        return b.createdAt.compareTo(a.createdAt);
      case CommunityBanSortOption.oldest:
        return a.createdAt.compareTo(b.createdAt);
      case CommunityBanSortOption.expiresSoon:
        final aExpiry = a.expiresAt;
        final bExpiry = b.expiresAt;
        if (aExpiry == null && bExpiry == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (aExpiry == null) return 1;
        if (bExpiry == null) return -1;
        final expiresCompare = aExpiry.compareTo(bExpiry);
        if (expiresCompare != 0) {
          return expiresCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
    }
  });

  return filtered;
}
