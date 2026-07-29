import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/application/community_ban_view_helper.dart';
import 'package:oshi_log/features/feed/domain/entities/community_moderation.dart';

void main() {
  ProjectCommunityBan ban({
    required String id,
    required String userId,
    String? name,
    String? reason,
    DateTime? expiresAt,
    required DateTime createdAt,
  }) {
    return ProjectCommunityBan(
      id: id,
      projectId: 'project-1',
      bannedUserId: userId,
      moderatorUserId: 'moderator-1',
      createdAt: createdAt,
      bannedUserDisplayName: name,
      reason: reason,
      expiresAt: expiresAt,
    );
  }

  test('filters by query across name/userId/reason', () {
    final bans = [
      ban(
        id: 'b1',
        userId: 'user-a',
        name: 'Alice',
        reason: 'spam',
        createdAt: DateTime.parse('2026-02-28T00:00:00Z'),
      ),
      ban(
        id: 'b2',
        userId: 'user-b',
        name: 'Bob',
        reason: 'abuse',
        createdAt: DateTime.parse('2026-02-27T00:00:00Z'),
      ),
    ];

    final byName = filterAndSortCommunityBans(bans: bans, query: 'alice');
    final byId = filterAndSortCommunityBans(bans: bans, query: 'user-b');
    final byReason = filterAndSortCommunityBans(bans: bans, query: 'spam');

    expect(byName.map((e) => e.id), ['b1']);
    expect(byId.map((e) => e.id), ['b2']);
    expect(byReason.map((e) => e.id), ['b1']);
  });

  test('filters permanent and non-expired bans', () {
    final now = DateTime.parse('2026-03-01T00:00:00Z');
    final bans = [
      ban(
        id: 'permanent',
        userId: 'u1',
        createdAt: DateTime.parse('2026-02-28T00:00:00Z'),
      ),
      ban(
        id: 'active',
        userId: 'u2',
        expiresAt: DateTime.parse('2026-03-02T00:00:00Z'),
        createdAt: DateTime.parse('2026-02-27T00:00:00Z'),
      ),
      ban(
        id: 'expired',
        userId: 'u3',
        expiresAt: DateTime.parse('2026-02-20T00:00:00Z'),
        createdAt: DateTime.parse('2026-02-26T00:00:00Z'),
      ),
    ];

    final permanentOnly = filterAndSortCommunityBans(
      bans: bans,
      onlyPermanent: true,
      now: now,
    );
    final hideExpired = filterAndSortCommunityBans(
      bans: bans,
      hideExpired: true,
      now: now,
    );

    expect(permanentOnly.map((e) => e.id), ['permanent']);
    expect(hideExpired.map((e) => e.id), ['permanent', 'active']);
  });

  test('sorts by expiresSoon with permanent bans last', () {
    final bans = [
      ban(
        id: 'permanent',
        userId: 'u1',
        createdAt: DateTime.parse('2026-02-20T00:00:00Z'),
      ),
      ban(
        id: 'late-expiry',
        userId: 'u2',
        expiresAt: DateTime.parse('2026-03-10T00:00:00Z'),
        createdAt: DateTime.parse('2026-02-28T00:00:00Z'),
      ),
      ban(
        id: 'soon-expiry',
        userId: 'u3',
        expiresAt: DateTime.parse('2026-03-02T00:00:00Z'),
        createdAt: DateTime.parse('2026-02-27T00:00:00Z'),
      ),
    ];

    final sorted = filterAndSortCommunityBans(
      bans: bans,
      sortOption: CommunityBanSortOption.expiresSoon,
    );

    expect(sorted.map((e) => e.id), [
      'soon-expiry',
      'late-expiry',
      'permanent',
    ]);
  });

  test('sorts by newest and oldest createdAt order', () {
    final bans = [
      ban(
        id: 'older',
        userId: 'u1',
        createdAt: DateTime.parse('2026-02-10T00:00:00Z'),
      ),
      ban(
        id: 'newer',
        userId: 'u2',
        createdAt: DateTime.parse('2026-02-12T00:00:00Z'),
      ),
      ban(
        id: 'newest',
        userId: 'u3',
        createdAt: DateTime.parse('2026-02-13T00:00:00Z'),
      ),
    ];

    final newestSorted = filterAndSortCommunityBans(
      bans: bans,
      sortOption: CommunityBanSortOption.newest,
    );
    final oldestSorted = filterAndSortCommunityBans(
      bans: bans,
      sortOption: CommunityBanSortOption.oldest,
    );

    expect(newestSorted.map((e) => e.id), ['newest', 'newer', 'older']);
    expect(oldestSorted.map((e) => e.id), ['older', 'newer', 'newest']);
  });
}
