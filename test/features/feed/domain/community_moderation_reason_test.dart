import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/domain/entities/community_moderation.dart';

void main() {
  group('CommunityReportReasonX', () {
    test('fromApiValue maps extended reason codes', () {
      expect(
        CommunityReportReasonX.fromApiValue('TRADE_INDUCEMENT'),
        CommunityReportReason.tradeInducement,
      );
      expect(
        CommunityReportReasonX.fromApiValue('FALSE_REPORT_ABUSE'),
        CommunityReportReason.falseReportAbuse,
      );
      expect(
        CommunityReportReasonX.fromApiValue('MANIPULATION_ABUSE'),
        CommunityReportReason.manipulationAbuse,
      );
    });

    test(
      'requestApiValue keeps backward compatibility for extended reasons',
      () {
        expect(CommunityReportReason.spam.requestApiValue, 'SPAM');
        expect(CommunityReportReason.tradeInducement.requestApiValue, 'OTHER');
        expect(CommunityReportReason.falseReportAbuse.requestApiValue, 'OTHER');
        expect(
          CommunityReportReason.manipulationAbuse.requestApiValue,
          'OTHER',
        );
      },
    );

    test('buildRequestDescription injects marker for extended reasons', () {
      expect(
        CommunityReportReason.tradeInducement.buildRequestDescription(null),
        '[TRADE_INDUCEMENT]',
      );
      expect(
        CommunityReportReason.falseReportAbuse.buildRequestDescription(
          '반복 허위 신고',
        ),
        '[FALSE_REPORT_ABUSE] 반복 허위 신고',
      );
      expect(
        CommunityReportReason.manipulationAbuse.buildRequestDescription(
          '[MANIPULATION_ABUSE] 이미 포함됨',
        ),
        '[MANIPULATION_ABUSE] 이미 포함됨',
      );
      expect(CommunityReportReason.spam.buildRequestDescription('도배'), '도배');
    });
  });
}
