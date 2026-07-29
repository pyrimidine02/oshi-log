import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/feed/presentation/models/feed_native_ad_placement.dart';

void main() {
  group('FeedNativeAdPlacement', () {
    test('does not insert sponsored slots before leading post threshold', () {
      for (
        var count = 0;
        count <= FeedNativeAdPlacement.leadingPostCount;
        count++
      ) {
        expect(
          FeedNativeAdPlacement.adCountForPostCount(count),
          0,
          reason: 'postCount=$count should not have sponsored slots',
        );
        expect(
          FeedNativeAdPlacement.totalItemCount(count),
          count,
          reason:
              'total items should match posts when no sponsored slot exists',
        );
      }
    });

    test('inserts first sponsored slot after leading posts', () {
      const postCount = FeedNativeAdPlacement.leadingPostCount + 1;
      expect(FeedNativeAdPlacement.totalItemCount(postCount), postCount + 1);
      expect(
        FeedNativeAdPlacement.isAdIndex(
          listIndex: FeedNativeAdPlacement.leadingPostCount,
          postCount: postCount,
        ),
        isTrue,
      );
      expect(
        FeedNativeAdPlacement.postIndexForListIndex(
          listIndex: FeedNativeAdPlacement.leadingPostCount + 1,
          postCount: postCount,
        ),
        FeedNativeAdPlacement.leadingPostCount,
      );
    });

    test('maps mixed list indices to post indices in order', () {
      const postCount = 60;
      final mappedPostIndices = <int>[];

      for (
        var listIndex = 0;
        listIndex < FeedNativeAdPlacement.totalItemCount(postCount);
        listIndex++
      ) {
        if (FeedNativeAdPlacement.isAdIndex(
          listIndex: listIndex,
          postCount: postCount,
        )) {
          continue;
        }
        mappedPostIndices.add(
          FeedNativeAdPlacement.postIndexForListIndex(
            listIndex: listIndex,
            postCount: postCount,
          ),
        );
      }

      expect(mappedPostIndices, List<int>.generate(postCount, (i) => i));
    });

    test('calculates ad ordinals for each sponsored slot', () {
      const postCount = 80;
      expect(
        FeedNativeAdPlacement.adOrdinalForIndex(
          listIndex: FeedNativeAdPlacement.leadingPostCount,
          postCount: postCount,
        ),
        0,
      );
    });

    test('caps sponsored slot count to keep density low', () {
      const postCount = 120;
      expect(FeedNativeAdPlacement.adCountForPostCount(postCount), 1);
    });
  });
}
