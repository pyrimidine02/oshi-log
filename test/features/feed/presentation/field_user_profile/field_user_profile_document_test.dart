import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/feed_entities.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/field_user_profile/field_user_profile_view_data.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/field_user_profile/widgets/field_user_profile_document.dart';

void main() {
  testWidgets(
    'public profile reads as a traveler field card and activity ledger',
    (tester) async {
      await tester.pumpWidget(_TestApp(child: _document()));

      final card = find.byKey(const Key('traveler-field-card'));
      final ledger = find.byKey(const Key('traveler-field-ledger'));

      expect(find.text('TRAVELER FIELD CARD'), findsOneWidget);
      expect(card, findsOneWidget);
      expect(ledger, findsOneWidget);
      expect(
        tester.getTopLeft(card).dy,
        lessThan(tester.getTopLeft(ledger).dy),
      );
      expect(find.byType(Card), findsNothing);

      await tester.drag(find.byType(NestedScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();

      final tabs = find.byKey(const Key('traveler-activity-tabs'));
      expect(tabs, findsOneWidget);
      for (final label in const ['작성한 글', '작성한 댓글', '방문 기록']) {
        expect(
          find.descendant(of: tabs, matching: find.text(label)),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('follow and message remain usable at 320dp and 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _TestApp(
        mediaQueryData: const MediaQueryData(
          size: Size(320, 760),
          textScaler: TextScaler.linear(2),
        ),
        child: _document(),
      ),
    );
    await tester.pump();

    final follow = find.byKey(const Key('traveler-profile-follow'));
    final message = find.byKey(const Key('traveler-profile-message'));
    await tester.ensureVisible(follow);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(follow).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(message).height, greaterThanOrEqualTo(48));
  });

  testWidgets('visit ledger remains available while post activity fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(child: _document(activityErrorMessage: '활동을 불러오지 못했어요')),
    );

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    final tabs = find.byKey(const Key('traveler-activity-tabs'));
    await tester.tap(find.descendant(of: tabs, matching: find.text('방문 기록')));
    await tester.pumpAndSettle();

    expect(find.text('성지 14곳을 기록했어요.'), findsOneWidget);
    expect(find.text('활동을 불러오지 못했어요'), findsNothing);
  });
}

Widget _document({String? activityErrorMessage}) {
  return FieldUserProfileDocument(
    data: _viewData,
    posts: [
      PostSummary(
        id: 'post-1',
        projectId: 'project-1',
        authorId: 'user-1',
        title: '시부야 라이브 하우스 동선',
        content: '역에서 공연장까지 걸은 기록',
        createdAt: DateTime.utc(2026, 7, 15),
      ),
    ],
    comments: [
      PostComment(
        id: 'comment-1',
        postId: 'post-1',
        projectId: 'project-1',
        authorId: 'user-1',
        content: '이 공연은 예약이 필요해요.',
        createdAt: DateTime.utc(2026, 7, 15),
      ),
    ],
    isAuthenticated: true,
    isFollowing: false,
    isBlocked: false,
    isFollowBusy: false,
    isMoreBusy: false,
    onBack: () {},
    onAvatarTap: () {},
    onFollow: () {},
    onMessage: () {},
    onMore: () {},
    onFollowers: () {},
    onFollowing: () {},
    onRefresh: () async {},
    onOpenPost: (_, _) {},
    activityErrorMessage: activityErrorMessage,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.mediaQueryData});

  final Widget child;
  final MediaQueryData? mediaQueryData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: GBTTheme.light,
      home: Scaffold(
        body: mediaQueryData == null
            ? child
            : MediaQuery(data: mediaQueryData!, child: child),
      ),
    );
  }
}

final _viewData = FieldUserProfileViewData(
  userId: 'user-1',
  displayName: '마리',
  bio: '도쿄의 라이브 하우스와 성지를 기록합니다.',
  joinedAt: DateTime.utc(2024, 3, 2),
  avatarUrl: null,
  coverImageUrl: null,
  accountRole: 'USER',
  accessLevelLabel: '일반 회원',
  followerCount: 12,
  followingCount: 7,
  metrics: const [
    FieldProfileMetric(kind: FieldProfileMetricKind.xp, value: '1,250'),
    FieldProfileMetric(kind: FieldProfileMetricKind.level, value: 'Lv.8'),
    FieldProfileMetric(kind: FieldProfileMetricKind.placeVisits, value: '14'),
    FieldProfileMetric(kind: FieldProfileMetricKind.liveVisits, value: '6'),
    FieldProfileMetric(kind: FieldProfileMetricKind.posts, value: '9'),
    FieldProfileMetric(kind: FieldProfileMetricKind.comments, value: '21'),
  ],
);
