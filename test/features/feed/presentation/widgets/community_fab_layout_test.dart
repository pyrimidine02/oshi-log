import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/presentation/widgets/community_fab_layout.dart';

void main() {
  group('resolveCommunityFabBottomPadding', () {
    test('keeps iPhone 17 Pro Max baseline position', () {
      final padding = resolveCommunityFabBottomPadding(screenHeight: 932);

      expect(padding, 109);
    });

    test('scales position by screen height while preserving ratio', () {
      final smaller = resolveCommunityFabBottomPadding(screenHeight: 780);
      final larger = resolveCommunityFabBottomPadding(screenHeight: 1024);

      expect(smaller, lessThan(109));
      expect(larger, greaterThan(109));
    });
  });
}
