import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/community/moderation/presentation/widgets/community_report_sheet.dart';
import 'package:oshi_log/features/community/posts/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/community/reviews/application/travel_reviews_controller.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review.dart';
import 'package:oshi_log/features/community/reviews/presentation/sections/field_community_travel_section.dart';

void main() {
  for (final locale in ['ko', 'ja']) {
    for (final brightness in Brightness.values) {
      testWidgets('review actions fit 320dp 200% $locale $brightness', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(320, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var writes = 0;
        String? opened;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              travelReviewsProvider(
                'bandori',
              ).overrideWith((ref) async => [_review()]),
            ],
            child: _app(
              locale: locale,
              brightness: brightness,
              child: FieldCommunityTravelSection(
                projectCode: 'bandori',
                onWriteReview: () => writes++,
                onOpenReview: (reviewId) => opened = reviewId,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final write = find.byKey(const Key('travel-review-create-entry'));
        await tester.ensureVisible(write);
        expect(tester.getSize(write).height, greaterThanOrEqualTo(48));
        await tester.tap(write);
        final review = find.text('Public field report');
        await tester.scrollUntilVisible(
          review,
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.tap(review);
        expect(writes, 1);
        expect(opened, 'review-1');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('review failure keeps retry and then shows empty state', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          travelReviewsProvider('bandori').overrideWith((ref) async {
            if (++loads == 1) throw StateError('offline');
            return [];
          }),
        ],
        child: _app(
          child: FieldCommunityTravelSection(
            projectCode: 'bandori',
            onWriteReview: () {},
            onOpenReview: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.text('다시 시도');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.text('아직 공개된 레포가 없어요'), findsOneWidget);
  });

  testWidgets('moderation explains place correction separately at large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(child: const CommunityReportSheet()));
    expect(find.textContaining('장소 정보 수정'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('신고 접수'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app({
  required Widget child,
  String locale = 'ko',
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: const [Locale('ko'), Locale('ja')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: ThemeData(brightness: brightness),
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(320, 760),
      textScaler: TextScaler.linear(2),
    ),
    child: Scaffold(body: child),
  ),
);

TravelReviewSummary _review() => TravelReviewSummary(
  id: 'review-1',
  postId: 'post-1',
  projectId: 'bandori',
  post: PostSummary(
    id: 'post-1',
    projectId: 'bandori',
    authorId: 'author-1',
    title: 'Public field report',
    createdAt: DateTime(2026, 10, 1),
  ),
  stops: const [],
  events: const [],
  fanSubjects: const [],
  createdAt: DateTime(2026, 10, 1),
);
