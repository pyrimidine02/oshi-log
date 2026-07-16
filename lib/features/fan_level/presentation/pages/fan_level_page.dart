/// EN: Fan level (덕력) page — shows grade badge, XP, progress bar,
///     recent activities, and daily check-in button.
/// KO: 팬 레벨(덕력) 페이지 — 등급 배지, XP, 진행 바,
///     최근 활동 목록, 일일 출석 체크 버튼을 표시합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_page_reveal.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/fan_level_controller.dart';
import '../../domain/entities/fan_level.dart';

/// EN: Root page widget for the fan level (덕력) feature.
/// KO: 팬 레벨(덕력) 기능의 루트 페이지 위젯.
class FanLevelPage extends ConsumerWidget {
  const FanLevelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(fanLevelControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '나의 덕력', en: 'Fan Level', ja: 'ファンレベル'),
      ),
      body: state.when(
        loading: () => _buildShimmer(isDark),
        error: (_, __) => GBTErrorState(
          message: context.l10n(
            ko: '덕력 정보를 불러오지 못했어요',
            en: 'Could not load fan level',
            ja: 'ファンレベルを読み込めませんでした',
          ),
          onRetry: () =>
              ref.read(fanLevelControllerProvider.notifier).refresh(),
        ),
        data: (profile) => profile == null
            ? GBTEmptyState(
                message: context.l10n(
                  ko: '아직 덕력 정보가 없어요',
                  en: 'No fan level data yet',
                  ja: 'ファンレベルデータはまだありません',
                ),
              )
            : _FanLevelContent(profile: profile),
      ),
    );
  }

  /// EN: Builds a shimmer skeleton while profile data is loading.
  /// KO: 프로필 데이터 로딩 중에 쉬머 스켈레톤을 구성합니다.
  Widget _buildShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      child: Column(
        children: [
          GBTShimmer(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark
                    ? GBTColors.darkSurfaceVariant
                    : GBTColors.surfaceVariant,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
          GBTShimmer(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? GBTColors.darkSurfaceVariant
                    : GBTColors.surfaceVariant,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EN: Main content — shown once profile data is available.
// KO: 메인 콘텐츠 — 프로필 데이터가 준비되면 표시됩니다.
// =============================================================================

class _FanLevelContent extends ConsumerStatefulWidget {
  const _FanLevelContent({required this.profile});

  final FanLevelProfile profile;

  @override
  ConsumerState<_FanLevelContent> createState() => _FanLevelContentState();
}

class _FanLevelContentState extends ConsumerState<_FanLevelContent> {
  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final scoredActivities =
        profile.recentActivities
            .where((activity) => activity.xpEarned > 0)
            .toList(growable: false)
          ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    final latestByType = _buildLatestScoredActivityMap(scoredActivities);

    return RefreshIndicator(
      onRefresh: () => ref.read(fanLevelControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
        children: [
          // EN: Staggered reveal animation applied to major content sections.
          // KO: 주요 콘텐츠 섹션에 순차 진입 애니메이션을 적용합니다.
          GBTPageReveal(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FanLevelDocumentHeader(),
              const SizedBox(height: GBTSpacing.lg),
              _GradeCard(profile: profile),
              const SizedBox(height: GBTSpacing.xl),
              _FanLevelSectionHeader(
                indexLabel: '02 / SCORE INDEX',
                title: context.l10n(
                  ko: '점수 부여 행위 전체',
                  en: 'All Scored Actions',
                  ja: 'スコア付与行動一覧',
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              ..._scoreAwardedActivityTypes.map(
                (type) => _ScoredActionTile(
                  activityType: type,
                  latestActivity: latestByType[type],
                ),
              ),
              const SizedBox(height: GBTSpacing.xl),
              _FanLevelSectionHeader(
                indexLabel: '03 / LEDGER',
                title: context.l10n(
                  ko: '점수 획득 내역',
                  en: 'Scored History',
                  ja: '獲得スコア履歴',
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              if (scoredActivities.isEmpty)
                _NoScoredActivityState()
              else
                ...scoredActivities.map(
                  (activity) => _ActivityTile(activity: activity),
                ),
              const SizedBox(height: GBTSpacing.xl),
            ],
          ),
        ],
      ),
    );
  }
}

/// EN: Editorial document heading shared by the fan-level ledger sections.
/// KO: 팬 레벨 대장 섹션을 묶는 에디토리얼 문서 헤더.
class _FanLevelDocumentHeader extends StatelessWidget {
  const _FanLevelDocumentHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAVEL RECORD / FAN LEVEL',
            style: GBTTypography.labelSmall.copyWith(
              color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '내 활동이 쌓인 여행 기록',
              en: 'Your travel activity, recorded',
              ja: '旅の活動を記録',
            ),
            style: GBTTypography.headlineSmall.copyWith(
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '방문과 참여로 얻은 XP와 등급 진행도를 확인하세요.',
              en: 'Review XP and grade progress earned through visits and participation.',
              ja: '訪問と参加で得たXPとグレード進行度を確認しましょう。',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Numbered section heading used by the activity index and history.
/// KO: 활동 인덱스와 기록에 사용하는 번호 섹션 헤더.
class _FanLevelSectionHeader extends StatelessWidget {
  const _FanLevelSectionHeader({required this.indexLabel, required this.title});

  final String indexLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(top: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indexLabel,
            style: GBTTypography.labelSmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextTertiary
                  : GBTColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            title,
            style: GBTTypography.titleMedium.copyWith(
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EN: Shared metadata for score-awarded actions.
// KO: 점수가 부여되는 행위의 공통 메타데이터.
// =============================================================================

const _scoreAwardedActivityTypes = <FanActivityType>[
  FanActivityType.dailyCheckIn,
  FanActivityType.placeVisit,
  FanActivityType.liveAttendance,
  FanActivityType.postCreated,
  FanActivityType.commentCreated,
  FanActivityType.postLiked,
  FanActivityType.adminGrant,
  FanActivityType.other,
];

// EN: Returns localized activity labels for fan score actions.
// KO: 팬 점수 행위의 다국어 라벨을 반환합니다.
String _activityTypeLabel(BuildContext context, FanActivityType type) {
  return switch (type) {
    FanActivityType.placeVisit => context.l10n(
      ko: '성지 방문',
      en: 'Place Visit',
      ja: '聖地訪問',
    ),
    FanActivityType.postCreated => context.l10n(
      ko: '게시글 작성',
      en: 'Post Created',
      ja: '投稿作成',
    ),
    FanActivityType.liveAttendance => context.l10n(
      ko: '라이브 참석',
      en: 'Live Attendance',
      ja: 'ライブ参加',
    ),
    FanActivityType.dailyCheckIn => context.l10n(
      ko: '출석 체크',
      en: 'Daily Check-in',
      ja: 'デイリーチェックイン',
    ),
    FanActivityType.commentCreated => context.l10n(
      ko: '댓글 작성',
      en: 'Comment Created',
      ja: 'コメント作成',
    ),
    FanActivityType.postLiked => context.l10n(
      ko: '게시글 좋아요',
      en: 'Post Liked',
      ja: '投稿いいね',
    ),
    FanActivityType.bookmark => context.l10n(
      ko: '북마크 추가',
      en: 'Bookmark Added',
      ja: 'ブックマーク追加',
    ),
    FanActivityType.collectionCompleted => context.l10n(
      ko: '컬렉션 완성',
      en: 'Collection Completed',
      ja: 'コレクション完成',
    ),
    FanActivityType.followReceived => context.l10n(
      ko: '팔로워 획득',
      en: 'Follower Gained',
      ja: 'フォロワー獲得',
    ),
    FanActivityType.adminGrant => context.l10n(
      ko: '관리자 지급',
      en: 'Admin Grant',
      ja: '管理者付与',
    ),
    FanActivityType.other => context.l10n(
      ko: '기타 활동',
      en: 'Other Activity',
      ja: 'その他の活動',
    ),
  };
}

// EN: Returns a semantic icon for each score action type.
// KO: 점수 행위 타입별 시맨틱 아이콘을 반환합니다.
IconData _activityTypeIcon(FanActivityType type) {
  return switch (type) {
    FanActivityType.placeVisit => Icons.place_outlined,
    FanActivityType.postCreated => Icons.edit_note_rounded,
    FanActivityType.liveAttendance => Icons.music_note_outlined,
    FanActivityType.dailyCheckIn => Icons.event_available_outlined,
    FanActivityType.commentCreated => Icons.chat_bubble_outline_rounded,
    FanActivityType.postLiked => Icons.thumb_up_off_alt_rounded,
    FanActivityType.bookmark => Icons.bookmark_outline_rounded,
    FanActivityType.collectionCompleted => Icons.collections_bookmark_outlined,
    FanActivityType.followReceived => Icons.people_outline_rounded,
    FanActivityType.adminGrant => Icons.shield_outlined,
    FanActivityType.other => Icons.bolt_outlined,
  };
}

// EN: Builds latest activity map keyed by action type.
// KO: 행위 타입을 키로 최신 활동 맵을 구성합니다.
Map<FanActivityType, FanActivity?> _buildLatestScoredActivityMap(
  List<FanActivity> scoredActivities,
) {
  final latest = <FanActivityType, FanActivity?>{
    for (final type in _scoreAwardedActivityTypes) type: null,
  };
  for (final activity in scoredActivities) {
    if (!latest.containsKey(activity.type)) {
      continue;
    }
    if (latest[activity.type] == null) {
      latest[activity.type] = activity;
    }
  }
  return latest;
}

// =============================================================================
// EN: Grade card — shows badge, total XP, and progress bar.
// KO: 등급 카드 — 배지, 총 XP, 진행 바를 표시합니다.
// =============================================================================

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.profile});

  final FanLevelProfile profile;

  // EN: Returns the accent color for the given grade and brightness — a
  // tier progression through the Journey Ticket palette: neutral (newbie)
  // → mint → blue → violet → gold → brand magenta (legend, the top tier).
  // KO: 주어진 등급과 밝기에 맞는 강조 색상 — "여정의 티켓" 팔레트를 따라
  // 뉴트럴(newbie) → 민트 → 블루 → 바이올렛 → 골드 → 브랜드 마젠타(legend,
  // 최고 등급)로 이어지는 등급 색상 진행입니다.
  Color _gradeColor(FanGrade grade, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return switch (grade) {
      FanGrade.newbie =>
        isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
      FanGrade.beginner => GBTSemanticColors.getDistanceColor(brightness),
      FanGrade.enthusiast => GBTSemanticColors.getInfoColor(brightness),
      FanGrade.devotee =>
        isDark ? GBTColors.darkSecondary : GBTColors.secondary,
      FanGrade.master => isDark ? GBTColors.darkAccent : GBTColors.accent,
      FanGrade.legend => isDark ? GBTColors.darkPrimary : GBTColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradeColor = _gradeColor(profile.grade, isDark);
    final gradeLabel = context.l10n(
      ko: profile.grade.koLabel,
      en: profile.grade.enLabel,
      ja: profile.grade.enLabel,
    );

    return Semantics(
      label: context.l10n(
        ko: '팬 레벨: $gradeLabel, 총 XP: ${profile.totalXp}',
        en: 'Fan level: $gradeLabel, Total XP: ${profile.totalXp}',
        ja: 'ファンレベル: $gradeLabel, 合計XP: ${profile.totalXp}',
      ),
      child: Container(
        padding: const EdgeInsets.all(GBTSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? GBTColors.darkSurface : GBTColors.surface,
          border: Border(
            left: BorderSide(color: gradeColor, width: 3),
            top: BorderSide(
              color: isDark ? GBTColors.darkBorder : GBTColors.border,
            ),
            bottom: BorderSide(
              color: isDark ? GBTColors.darkBorder : GBTColors.border,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: GBTSpacing.sm,
              runSpacing: GBTSpacing.xs,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // EN: Grade badge chip
                // KO: 등급 배지 칩
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                    vertical: GBTSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
                  ),
                  child: Text(
                    gradeLabel,
                    style: GBTTypography.labelMedium.copyWith(
                      color: gradeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  context.l10n(
                    ko: '순위 #${profile.rank}',
                    en: 'Rank #${profile.rank}',
                    ja: 'ランク #${profile.rank}',
                  ),
                  style: GBTTypography.bodySmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.md),
            // EN: Total XP display — gold stat number, matching the
            // stamps/ratings accent used across the collection screens.
            // KO: 총 XP 표시 — 도감·평점 화면에서 쓰는 골드 강조와 맞춘
            // 스탯 숫자.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${profile.totalXp}',
                    style: GBTTypography.statNumber.copyWith(
                      fontSize: 30,
                      color: isDark ? GBTColors.darkAccent : GBTColors.accent,
                    ),
                  ),
                  TextSpan(
                    text: ' XP',
                    style: GBTTypography.titleMedium.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
            if (profile.grade != FanGrade.legend) ...[
              // EN: XP progress bar toward the next level
              // KO: 다음 레벨까지의 XP 진행 바
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.progressRatio,
                  backgroundColor: isDark
                      ? GBTColors.darkSurfaceVariant
                      : GBTColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                '${profile.currentLevelXp} / ${profile.nextLevelXp} XP',
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textTertiary,
                ),
              ),
            ] else
              Text(
                context.l10n(
                  ko: '최고 등급 달성!',
                  en: 'Max level reached!',
                  ja: '最高レベル達成!',
                ),
                style: GBTTypography.bodySmall.copyWith(
                  color: gradeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Activity tile — single row in the recent activities list.
// KO: 활동 타일 — 최근 활동 목록의 단일 행.
// =============================================================================

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final FanActivity activity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateLabel = DateFormat('MM.dd').format(activity.earnedAt);

    // EN: Strip "[ADMIN] " prefix from admin-granted activity descriptions.
    // KO: 관리자 지급 항목의 "[ADMIN] " 접두사를 제거합니다.
    final rawDesc = activity.description;
    final fallbackLabel = _activityTypeLabel(context, activity.type);
    final activityLabel = rawDesc != null
        ? (rawDesc.startsWith('[ADMIN] ') ? rawDesc.substring(8) : rawDesc)
        : fallbackLabel;
    return Semantics(
      label: context.l10n(
        ko: '$activityLabel, +${activity.xpEarned} XP, $dateLabel',
        en: '$activityLabel, +${activity.xpEarned} XP, $dateLabel',
        ja: '$activityLabel, +${activity.xpEarned} XP, $dateLabel',
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
        child: Row(
          children: [
            // EN: Activity type icon badge
            // KO: 활동 유형 아이콘 배지
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? GBTColors.darkSurfaceVariant
                    : GBTColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _activityTypeIcon(activity.type),
                size: 18,
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activityLabel,
                    style: GBTTypography.bodySmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextPrimary
                          : GBTColors.textPrimary,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // EN: XP earned label — gold, matching the total XP accent.
            // KO: 획득 XP 라벨 — 총 XP 강조와 동일한 골드.
            Text(
              '+${activity.xpEarned} XP',
              style: GBTTypography.labelMedium.copyWith(
                color: isDark ? GBTColors.darkAccent : GBTColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Static list tile for score-awarded action categories.
// KO: 점수 부여 행위 카테고리 정적 목록 타일.
// =============================================================================

class _ScoredActionTile extends StatelessWidget {
  const _ScoredActionTile({required this.activityType, this.latestActivity});

  final FanActivityType activityType;
  final FanActivity? latestActivity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _activityTypeLabel(context, activityType);
    final subtitle = latestActivity == null
        ? context.l10n(
            ko: '아직 획득 내역이 없어요',
            en: 'No earned score yet',
            ja: 'まだ獲得履歴がありません',
          )
        : context.l10n(
            ko: '최근 획득: ${DateFormat('MM.dd').format(latestActivity!.earnedAt)}',
            en: 'Latest: ${DateFormat('MM.dd').format(latestActivity!.earnedAt)}',
            ja: '最新: ${DateFormat('MM.dd').format(latestActivity!.earnedAt)}',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.sm,
          vertical: GBTSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? GBTColors.darkBorderSubtle : GBTColors.divider,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? GBTColors.darkSurfaceVariant
                    : GBTColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _activityTypeIcon(activityType),
                size: 18,
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GBTTypography.bodySmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextPrimary
                          : GBTColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              latestActivity == null ? '-' : '+${latestActivity!.xpEarned} XP',
              style: GBTTypography.labelMedium.copyWith(
                color: latestActivity == null
                    ? (isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary)
                    : (isDark ? GBTColors.darkAccent : GBTColors.accent),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EN: Empty-state tile for score history.
// KO: 점수 획득 내역 비어있을 때의 상태 타일.
// =============================================================================

class _NoScoredActivityState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
          bottom: BorderSide(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
        ),
      ),
      child: Text(
        context.l10n(
          ko: '아직 점수 획득 내역이 없습니다.',
          en: 'No scored history yet.',
          ja: 'まだ獲得スコア履歴がありません。',
        ),
        style: GBTTypography.bodySmall.copyWith(
          color: isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
        ),
      ),
    );
  }
}
