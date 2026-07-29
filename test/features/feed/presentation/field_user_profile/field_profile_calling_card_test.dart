import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/presentation/field_user_profile/field_user_profile_view_data.dart';
import 'package:oshi_log/features/feed/presentation/field_user_profile/widgets/field_profile_calling_card.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'calling card fits 320dp with large text in ${brightness.name} mode',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ko'),
            supportedLocales: const [Locale('ko')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: GBTTheme.light,
            darkTheme: GBTTheme.dark,
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 760),
                textScaler: TextScaler.linear(1.8),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: FieldProfileCallingCard(
                    data: _viewData,
                    activeTitleBadge: const Text('TOKYO WALKER'),
                    isMyProfile: false,
                    isAuthenticated: true,
                    isFollowing: false,
                    isBlocked: false,
                    isFollowBusy: false,
                    isMoreBusy: false,
                    onBack: () {},
                    onAvatarTap: () {},
                    onCoverTap: () {},
                    onFollow: () {},
                    onMore: () {},
                    onFollowers: () {},
                    onFollowing: () {},
                    onEdit: () {},
                    onOpenTitlePicker: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('마리의 FIELD LOG'), findsOneWidget);
        expect(find.text('팔로우'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('field-profile-follow'))).height,
          greaterThanOrEqualTo(48),
        );
      },
    );
  }

  testWidgets('calling card exposes a concise profile semantics label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: GBTTheme.light,
        home: Scaffold(
          body: FieldProfileCallingCard(
            data: _viewData,
            isMyProfile: true,
            isAuthenticated: true,
            isFollowing: false,
            isBlocked: false,
            isFollowBusy: false,
            isMoreBusy: false,
            onBack: () {},
            onAvatarTap: () {},
            onCoverTap: () {},
            onFollow: () {},
            onMore: () {},
            onFollowers: () {},
            onFollowing: () {},
            onEdit: () {},
            onOpenTitlePicker: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('마리.*프로필')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('self actions remain readable at 320dp and 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FieldProfileCallingCard(
                data: _viewData,
                isMyProfile: true,
                isAuthenticated: true,
                isFollowing: false,
                isBlocked: false,
                isFollowBusy: false,
                isMoreBusy: false,
                onBack: () {},
                onAvatarTap: () {},
                onCoverTap: () {},
                onFollow: () {},
                onMore: () {},
                onFollowers: () {},
                onFollowing: () {},
                onEdit: () {},
                onOpenTitlePicker: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('칭호'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('block-status loading does not disable the follow action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: GBTTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FieldProfileCallingCard(
              data: _viewData,
              isMyProfile: false,
              isAuthenticated: true,
              isFollowing: false,
              isBlocked: false,
              isFollowBusy: false,
              isMoreBusy: true,
              onBack: () {},
              onAvatarTap: () {},
              onCoverTap: () {},
              onFollow: () {},
              onMore: () {},
              onFollowers: () {},
              onFollowing: () {},
              onEdit: () {},
              onOpenTitlePicker: () {},
            ),
          ),
        ),
      ),
    );

    final follow = tester.widget<FilledButton>(
      find.byKey(const Key('field-profile-follow')),
    );
    expect(follow.onPressed, isNotNull);
  });
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
  metrics: [
    FieldProfileMetric(kind: FieldProfileMetricKind.xp, value: '1,250'),
    FieldProfileMetric(kind: FieldProfileMetricKind.level, value: 'Lv.8'),
    FieldProfileMetric(kind: FieldProfileMetricKind.placeVisits, value: '14'),
    FieldProfileMetric(kind: FieldProfileMetricKind.liveVisits, value: '6'),
    FieldProfileMetric(kind: FieldProfileMetricKind.posts, value: '9'),
    FieldProfileMetric(kind: FieldProfileMetricKind.comments, value: '21'),
  ],
);
