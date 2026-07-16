/// EN: Immutable presentation data for the field-notes user profile.
/// KO: 필드 노트 사용자 프로필용 불변 프레젠테이션 데이터입니다.
library;

import 'package:intl/intl.dart';

import '../../../settings/domain/entities/user_profile.dart';

enum FieldProfileMetricKind {
  xp,
  level,
  placeVisits,
  liveVisits,
  posts,
  comments,
}

class FieldProfileMetric {
  const FieldProfileMetric({required this.kind, required this.value});

  final FieldProfileMetricKind kind;
  final String value;
}

/// EN: Factual profile values prepared for the calling card and ledger.
/// KO: 프로필 명함과 활동 원장에 사용할 사실 기반 값을 준비합니다.
class FieldUserProfileViewData {
  const FieldUserProfileViewData({
    required this.userId,
    required this.displayName,
    required this.joinedAt,
    required this.accountRole,
    required this.accessLevelLabel,
    required this.metrics,
    this.bio,
    this.avatarUrl,
    this.coverImageUrl,
    this.followerCount,
    this.followingCount,
  });

  final String userId;
  final String displayName;
  final String? bio;
  final DateTime joinedAt;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String accountRole;
  final String accessLevelLabel;
  final int? followerCount;
  final int? followingCount;
  final List<FieldProfileMetric> metrics;

  factory FieldUserProfileViewData.fromProfile({
    required UserProfile profile,
    int? followerCount,
    int? followingCount,
    int? fallbackTotalXp,
    int? fallbackFanLevel,
    String? fallbackFanGrade,
    int? fallbackUniquePlacesVisited,
    int? fallbackLiveAttendanceCount,
  }) {
    return FieldUserProfileViewData(
      userId: profile.id,
      displayName: profile.displayName,
      bio: _nonEmpty(profile.bio),
      joinedAt: profile.createdAt,
      avatarUrl: _nonEmpty(profile.avatarUrl),
      coverImageUrl: _nonEmpty(profile.coverImageUrl),
      accountRole: profile.accountRole,
      accessLevelLabel: profile.effectiveAccessLevelLabel,
      followerCount: followerCount,
      followingCount: followingCount,
      metrics: List<FieldProfileMetric>.unmodifiable([
        FieldProfileMetric(
          kind: FieldProfileMetricKind.xp,
          value: _count(profile.totalXp ?? fallbackTotalXp),
        ),
        FieldProfileMetric(
          kind: FieldProfileMetricKind.level,
          value: _level(
            profile.fanLevel ?? fallbackFanLevel,
            profile.fanGrade ?? fallbackFanGrade,
          ),
        ),
        FieldProfileMetric(
          kind: FieldProfileMetricKind.placeVisits,
          value: _count(
            profile.uniquePlacesVisited ?? fallbackUniquePlacesVisited,
          ),
        ),
        FieldProfileMetric(
          kind: FieldProfileMetricKind.liveVisits,
          value: _count(
            profile.liveAttendanceCount ?? fallbackLiveAttendanceCount,
          ),
        ),
        FieldProfileMetric(
          kind: FieldProfileMetricKind.posts,
          value: _count(profile.postCount),
        ),
        FieldProfileMetric(
          kind: FieldProfileMetricKind.comments,
          value: _count(profile.commentCount),
        ),
      ]),
    );
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String _count(int? value) {
    return value == null
        ? '—'
        : NumberFormat.decimalPattern('en').format(value);
  }

  static String _level(int? level, String? grade) {
    final normalizedGrade = _nonEmpty(grade);
    if (level != null && normalizedGrade != null) {
      return 'Lv.$level · $normalizedGrade';
    }
    if (level != null) return 'Lv.$level';
    return normalizedGrade ?? '—';
  }
}
