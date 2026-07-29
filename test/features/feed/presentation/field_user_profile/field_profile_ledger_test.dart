import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/feed/presentation/field_user_profile/field_user_profile_view_data.dart';
import 'package:oshi_log/features/feed/presentation/field_user_profile/widgets/field_profile_activity.dart';
import 'package:oshi_log/features/feed/presentation/field_user_profile/widgets/field_profile_ledger.dart';

void main() {
  testWidgets('ledger renders all factual metrics as ruled rows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
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
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(2),
            ),
            child: SingleChildScrollView(
              child: FieldProfileLedger(
                metrics: _metrics,
                onOpenFanLevel: () {},
                onOpenPlaceHistory: () {},
                onOpenLiveHistory: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('field-profile-ledger-row')), findsNWidgets(6));
    expect(find.text('1,250'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity rows preserve post and comment navigation', (
    tester,
  ) async {
    String? openedPostId;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: GBTTheme.dark,
        home: Scaffold(
          body: DefaultTabController(
            length: 2,
            child: FieldProfileActivity(
              posts: [
                PostSummary(
                  id: 'post-1',
                  projectId: 'project-1',
                  authorId: 'user-1',
                  title: '시부야 라이브 하우스 동선',
                  content: '신나이워세부터 걷는 루트',
                  createdAt: DateTime.utc(2026, 7, 15),
                ),
              ],
              comments: [
                PostComment(
                  id: 'comment-1',
                  postId: 'post-2',
                  projectId: 'project-1',
                  authorId: 'user-1',
                  content: '이 이벤트는 예약이 필요해요.',
                  createdAt: DateTime.utc(2026, 7, 14),
                ),
              ],
              onRefresh: () async {},
              onOpenPost: (postId, _) => openedPostId = postId,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('시부야 라이브 하우스 동선'));
    expect(openedPostId, 'post-1');

    await tester.tap(find.text('작성한 댓글'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 이벤트는 예약이 필요해요.'));
    expect(openedPostId, 'post-2');
    expect(tester.takeException(), isNull);
  });
}

const _metrics = [
  FieldProfileMetric(kind: FieldProfileMetricKind.xp, value: '1,250'),
  FieldProfileMetric(
    kind: FieldProfileMetricKind.level,
    value: 'Lv.8 · Stagehand Stagehand',
  ),
  FieldProfileMetric(kind: FieldProfileMetricKind.placeVisits, value: '14'),
  FieldProfileMetric(kind: FieldProfileMetricKind.liveVisits, value: '6'),
  FieldProfileMetric(kind: FieldProfileMetricKind.posts, value: '9'),
  FieldProfileMetric(kind: FieldProfileMetricKind.comments, value: '21'),
];
