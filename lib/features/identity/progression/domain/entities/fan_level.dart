/// EN: Domain entities for the fan level (덕력) system.
/// KO: 팬 레벨(덕력) 시스템의 도메인 엔티티.
library;

/// EN: Fan level grade tiers.
/// KO: 팬 레벨 등급 티어.
enum FanGrade {
  /// EN: Newbie — just starting out.
  /// KO: 입문자 — 막 시작한 단계.
  newbie,

  /// EN: Beginner — getting into it.
  /// KO: 초보 팬 — 입문하는 단계.
  beginner,

  /// EN: Enthusiast — dedicated follower.
  /// KO: 열정 팬 — 열정적인 팔로워.
  enthusiast,

  /// EN: Devotee — deeply committed.
  /// KO: 헌신 팬 — 깊이 헌신하는 단계.
  devotee,

  /// EN: Master — expert fan.
  /// KO: 마스터 팬 — 전문가 팬.
  master,

  /// EN: Legend — ultimate fan.
  /// KO: 전설의 팬 — 최고의 팬.
  legend;

  /// EN: Korean display label.
  /// KO: 한국어 표시 라벨.
  String get koLabel => switch (this) {
    FanGrade.newbie => '입문자',
    FanGrade.beginner => '초보 팬',
    FanGrade.enthusiast => '열정 팬',
    FanGrade.devotee => '헌신 팬',
    FanGrade.master => '마스터 팬',
    FanGrade.legend => '전설의 팬',
  };

  /// EN: English display label.
  /// KO: 영어 표시 라벨.
  String get enLabel => switch (this) {
    FanGrade.newbie => 'Newbie',
    FanGrade.beginner => 'Beginner',
    FanGrade.enthusiast => 'Enthusiast',
    FanGrade.devotee => 'Devotee',
    FanGrade.master => 'Master',
    FanGrade.legend => 'Legend',
  };

  /// EN: Parses a raw string to the matching [FanGrade]; defaults to [newbie].
  /// KO: 원시 문자열을 [FanGrade]로 파싱합니다. 매칭되지 않으면 [newbie]를 반환합니다.
  static FanGrade fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'beginner' => FanGrade.beginner,
      'enthusiast' => FanGrade.enthusiast,
      'devotee' => FanGrade.devotee,
      'master' => FanGrade.master,
      'legend' => FanGrade.legend,
      _ => FanGrade.newbie,
    };
  }
}

/// EN: Activity type that earns fan XP.
/// KO: 팬 XP를 획득하는 활동 유형.
enum FanActivityType {
  placeVisit,
  postCreated,
  liveAttendance,
  dailyCheckIn,
  commentCreated,
  postLiked,

  /// EN: Bookmark added (currently no XP awarded).
  /// KO: 북마크 추가 (현재 XP 미부여).
  bookmark,

  /// EN: Collection completed (currently no XP awarded).
  /// KO: 컬렉션 완성 (현재 XP 미부여).
  collectionCompleted,

  /// EN: Follower gained (currently no XP awarded).
  /// KO: 팔로워 획득 (현재 XP 미부여).
  followReceived,

  /// EN: XP manually granted or adjusted by an admin.
  /// KO: 관리자가 수동으로 부여하거나 조정한 XP.
  adminGrant,
  other;

  /// EN: Korean display label for the activity type.
  /// KO: 활동 유형의 한국어 표시 라벨.
  String get koLabel => switch (this) {
    FanActivityType.placeVisit => '성지 방문',
    FanActivityType.postCreated => '게시글 작성',
    FanActivityType.liveAttendance => '라이브 참석',
    FanActivityType.dailyCheckIn => '출석 체크',
    FanActivityType.commentCreated => '댓글 작성',
    FanActivityType.postLiked => '게시글 좋아요',
    FanActivityType.bookmark => '북마크 추가',
    FanActivityType.collectionCompleted => '컬렉션 완성',
    FanActivityType.followReceived => '팔로워 획득',
    FanActivityType.adminGrant => '관리자 지급',
    FanActivityType.other => '기타',
  };

  /// EN: Parses a raw history action string from the server to the matching
  ///     [FanActivityType]. Note: history action values differ from the
  ///     activityType values the app sends to earn XP (e.g. VISIT vs PLACE_VISIT).
  /// KO: 서버의 히스토리 action 문자열을 [FanActivityType]으로 파싱합니다.
  ///     히스토리 action 값은 앱이 XP 획득 요청 시 보내는 activityType 값과 다릅니다
  ///     (예: VISIT vs PLACE_VISIT).
  static FanActivityType fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      // EN: History action values (server → app)
      // KO: 히스토리 action 값 (서버 → 앱)
      'visit' || 'place_visit' || 'placevisit' => FanActivityType.placeVisit,
      'post' || 'post_created' || 'postcreated' => FanActivityType.postCreated,
      'comment' ||
      'comment_created' ||
      'commentcreated' => FanActivityType.commentCreated,
      'attendance' ||
      'daily_check_in' ||
      'dailycheckin' => FanActivityType.dailyCheckIn,
      'post_liked' || 'postliked' => FanActivityType.postLiked,
      'live_attendance' || 'liveattendance' => FanActivityType.liveAttendance,
      'bookmark' => FanActivityType.bookmark,
      'collection_completed' ||
      'collectioncompleted' => FanActivityType.collectionCompleted,
      'follow_received' || 'followreceived' => FanActivityType.followReceived,
      'admin_grant' || 'admingrant' => FanActivityType.adminGrant,
      _ => FanActivityType.other,
    };
  }
}

/// EN: The user's complete fan level profile.
/// KO: 사용자의 전체 팬 레벨 프로필.
class FanLevelProfile {
  const FanLevelProfile({
    required this.userId,
    required this.grade,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.rank,
    this.hasCheckedInToday = false,
    this.consecutiveDays = 0,
    this.recentActivities = const [],
  });

  final String userId;
  final FanGrade grade;
  final int totalXp;

  /// EN: XP earned within the current level (used for the progress bar).
  /// KO: 현재 레벨에서 획득한 XP (진행 바에 사용됩니다).
  final int currentLevelXp;

  /// EN: Total XP threshold to reach the next level.
  /// KO: 다음 레벨에 도달하기 위한 총 XP 임계값.
  final int nextLevelXp;

  /// EN: User's ranking among all fans.
  /// KO: 전체 팬 중 사용자의 순위.
  final int rank;

  /// EN: Whether the user has already performed today's check-in.
  /// KO: 사용자가 오늘 이미 출석 체크를 수행했는지 여부.
  final bool hasCheckedInToday;

  /// EN: Current consecutive check-in streak in days.
  /// KO: 현재 연속 출석 체크 스트릭 일수.
  final int consecutiveDays;

  /// EN: Recent XP activity records (newest first).
  /// KO: 최근 XP 활동 기록 (최신순).
  final List<FanActivity> recentActivities;

  /// EN: Ratio of [currentLevelXp] to [nextLevelXp], clamped to [0, 1].
  ///     Returns 1.0 when the user has reached the legend (max) grade.
  /// KO: [currentLevelXp]와 [nextLevelXp]의 비율 (0~1 범위로 고정).
  ///     레전드(최고 등급)에 도달하면 1.0을 반환합니다.
  double get progressRatio =>
      nextLevelXp > 0 ? (currentLevelXp / nextLevelXp).clamp(0.0, 1.0) : 1.0;
}

/// EN: A single XP activity record for a fan.
/// KO: 팬의 단일 XP 활동 기록.
class FanActivity {
  const FanActivity({
    required this.id,
    required this.type,
    required this.xpEarned,
    required this.earnedAt,
    this.description,
  });

  final String id;
  final FanActivityType type;
  final int xpEarned;
  final DateTime earnedAt;

  /// EN: Optional human-readable description of the activity.
  /// KO: 활동에 대한 선택적 사람이 읽을 수 있는 설명.
  final String? description;
}

/// EN: Result returned after a successful daily check-in.
/// KO: 일일 출석 체크 성공 후 반환되는 결과.
class CheckInResult {
  const CheckInResult({
    required this.xpEarned,
    required this.bonusXpEarned,
    required this.newTotalXp,
    required this.newGrade,
    required this.streakDays,
    this.didLevelUp = false,
    this.bonusMessage,
  });

  /// EN: Base XP earned from this check-in (always 10).
  /// KO: 이번 출석 체크로 획득한 기본 XP (항상 10).
  final int xpEarned;

  /// EN: Bonus XP earned from streak multiplier (0 when no streak bonus).
  /// KO: 스트릭 보너스로 획득한 XP (보너스 없으면 0).
  final int bonusXpEarned;

  /// EN: New total XP after the check-in.
  /// KO: 출석 체크 후 새로운 총 XP.
  final int newTotalXp;

  /// EN: Grade after the check-in (may have changed if XP caused a level-up).
  /// KO: 출석 체크 후 등급 (XP로 레벨업이 발생했다면 변경될 수 있음).
  final FanGrade newGrade;

  /// EN: Consecutive days the user has checked in.
  /// KO: 사용자가 연속으로 출석 체크한 일수.
  final int streakDays;

  /// EN: Whether this check-in triggered a grade promotion.
  /// KO: 이번 출석 체크로 등급 승급이 발생했는지 여부.
  final bool didLevelUp;

  /// EN: Optional streak bonus message from the server (e.g. "3일 연속 출석! 보너스 5XP 추가 지급").
  /// KO: 서버에서 전달하는 스트릭 보너스 메시지 (예: "3일 연속 출석! 보너스 5XP 추가 지급").
  final String? bonusMessage;
}
