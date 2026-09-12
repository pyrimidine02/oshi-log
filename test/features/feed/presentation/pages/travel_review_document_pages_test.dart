import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/feed/application/travel_reviews_controller.dart';
import 'package:oshi_log/features/feed/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/feed/domain/entities/travel_review.dart';
import 'package:oshi_log/features/feed/domain/repositories/travel_reviews_repository.dart';
import 'package:oshi_log/features/feed/presentation/pages/travel_review_create_page.dart';
import 'package:oshi_log/features/feed/presentation/pages/travel_review_detail_page.dart';
import 'package:oshi_log/features/feed/presentation/widgets/travel_review_compose_sections.dart';
import 'package:oshi_log/features/feed/presentation/widgets/travel_review_edit_sheet.dart';

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

      expect(find.text('오늘의 순례를 기록하세요'), findsOneWidget);
      expect(find.text('FIELD REPORT'), findsNothing);
      expect(find.text('TRAVEL NOTE'), findsNothing);
      expect(find.text('TRIP CONTEXT'), findsNothing);
      expect(find.text('ROUTE'), findsNothing);
      expect(
        find.byKey(const ValueKey('travel-review-submit')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('travel-review-submit')))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'travel review metadata shows selected dates at 320dp and 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final routeNoteController = TextEditingController();
      addTearDown(routeNoteController.dispose);
      var pickedStart = false;
      var pickedEnd = false;
      var pickedEvents = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: TravelReviewComposeMetadata(
                  routeNoteController: routeNoteController,
                  tripStartedOn: DateTime(2026, 7, 15),
                  tripEndedOn: DateTime(2026, 7, 16),
                  selectedEvents: const [],
                  selectedSubjects: const [],
                  onPickStartDate: () => pickedStart = true,
                  onPickEndDate: () => pickedEnd = true,
                  onPickEvents: () => pickedEvents = true,
                  onPickSubjects: () {},
                  onRemoveEvent: (_) {},
                  onRemoveSubject: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('시작일 2026.07.15'), findsOneWidget);
      expect(find.text('종료일 2026.07.16'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('시작일 2026.07.15'));
      await tester.tap(find.text('종료일 2026.07.16'));
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, '라이브 선택'));
      await tester.tap(find.widgetWithText(OutlinedButton, '라이브 선택'));

      expect(pickedStart, isTrue);
      expect(pickedEnd, isTrue);
      expect(pickedEvents, isTrue);
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
            data: MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2),
            ),
            child: TravelReviewDetailPage(
              projectCode: 'bang-dream',
              reviewId: '1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PILGRIMAGE LOG'), findsNothing);
    expect(find.text('도쿄 순례'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(repository.lastDetailProjectCode, 'bang-dream');
    expect(tester.takeException(), isNull);
  });

  testWidgets('travel review edit sheet keeps primary and cancel actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          travelReviewsRepositoryProvider.overrideWithValue(
            _FakeTravelReviewsRepository(),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                size: const Size(320, 760),
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 280),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TravelReviewEditSheet(
                        projectCode: 'bang-dream',
                        review: _detail(),
                      ),
                    );
                  },
                  child: const Text('open-edit'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open-edit'));
    await tester.pumpAndSettle();

    final cancel = find.widgetWithText(TextButton, '취소');
    final submit = find.widgetWithText(FilledButton, '수정 완료');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();

    expect(cancel, findsOneWidget);
    expect(submit, findsOneWidget);
    expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));

    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(find.byType(TravelReviewEditSheet), findsNothing);
    expect(tester.takeException(), isNull);
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
