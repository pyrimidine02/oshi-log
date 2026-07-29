import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/application/report_rate_limiter.dart';

void main() {
  test('canReport returns true for first report', () {
    final now = DateTime(2026, 2, 18, 10, 0, 0);
    final limiter = ReportRateLimiter(now: () => now);

    expect(limiter.canReport('post-1'), true);
  });

  test('canReport returns false right after recordReport', () {
    final now = DateTime(2026, 2, 18, 10, 0, 0);
    final limiter = ReportRateLimiter(now: () => now);

    limiter.recordReport('post-1');

    expect(limiter.canReport('post-1'), false);
  });

  test('remainingCooldown returns expected duration', () {
    var now = DateTime(2026, 2, 18, 10, 0, 0);
    final limiter = ReportRateLimiter(now: () => now);

    limiter.recordReport('post-1');
    now = now.add(const Duration(minutes: 2));

    expect(limiter.remainingCooldown('post-1'), const Duration(minutes: 3));
  });
}
