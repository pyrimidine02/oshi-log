import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/feed/application/travel_reviews_controller.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/feed_entities.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/travel_review.dart';
import 'package:girlsbandtabi_app/features/feed/domain/repositories/travel_reviews_repository.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/pages/travel_review_create_page.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/pages/travel_review_detail_page.dart';

void main() {
  test('travel review reorder keeps legacy Flutter index semantics', () {
    final original = ['A', 'B', 'C'];

    final movedForward = reorderTravelReviewItems(original, 0, 3);
    final movedBackward = reorderTravelReviewItems(original, 2, 0);
    final appended = appendTravelReviewItem(movedForward, 'D');
    final removed = removeTravelReviewItem(appended, 1);

    expect(movedForward, ['B', 'C', 'A']);
    expect(movedBackward, ['C', 'A', 'B']);
    expect(appended, ['B', 'C', 'A', 'D']);
    expect(removed, ['B', 'A', 'D']);
    expect(original, ['A', 'B', 'C']);
  });

  testWidgets(
    'travel review compose is a field report at 320dp and 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedProjectKeyProvider.overrideWith((ref) => 'bang-dream'),
            travelReviewsRepositoryProvider.overrideWithValue(
              _FakeTravelReviewsRepository(),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 760),
                textScaler: TextScaler.linear(2),
              ),
              child: TravelReviewCreatePage(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('FIELD REPORT'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('travel-review-submit')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('travel review detail reads as a pilgrimage log', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeTravelReviewsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectKeyProvider.overrideWith((ref) => 'wrong-project'),
          travelReviewsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(320, 760)),
            child: TravelReviewDetailPage(
              projectCode: 'bang-dream',
              reviewId: '1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PILGRIMAGE LOG'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(repository.lastDetailProjectCode, 'bang-dream');
  });
}

class _FakeTravelReviewsRepository implements TravelReviewsRepository {
  String? lastDetailProjectCode;

  @override
  Future<Result<TravelReviewDetail>> create({
    required String projectCode,
    required TravelReviewDraft draft,
  }) async => Result.success(_detail());

  @override
  Future<Result<void>> delete({
    required String projectCode,
    required String reviewId,
  }) async => const Result.success(null);

  @override
  Future<Result<TravelReviewDetail>> getReview({
    required String projectCode,
    required String reviewId,
  }) async {
    lastDetailProjectCode = projectCode;
    return Result.success(_detail());
  }

  @override
  Future<Result<List<TravelReviewSummary>>> getReviews({
    required String projectCode,
    int page = 0,
    int size = 20,
  }) async => const Result.success([]);

  @override
  Future<Result<TravelReviewDetail>> update({
    required String projectCode,
    required String reviewId,
    required TravelReviewPatch patch,
  }) async => Result.success(_detail());
}

TravelReviewDetail _detail() {
  return TravelReviewDetail(
    id: 'review-1',
    postId: 'post-1',
    projectId: 'project-1',
    post: PostDetail(
      id: 'post-1',
      projectId: 'project-1',
      authorId: 'author-1',
      title: '도쿄 순례',
      content: '필드 노트',
      createdAt: DateTime(2026, 7, 15),
      authorName: '타비매니아',
      likeCount: 42,
      commentCount: 8,
    ),
    stops: const [],
    events: const [],
    fanSubjects: const [],
    createdAt: DateTime(2026, 7, 15),
  );
}
