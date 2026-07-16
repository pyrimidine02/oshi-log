import 'package:flutter_test/flutter_test.dart';

import '../../testing/tolerant_local_file_comparator.dart';

void main() {
  test('accepts only differences within the configured golden tolerance', () {
    expect(isGoldenDifferenceAccepted(0.0141, tolerance: 0.015), isTrue);
    expect(isGoldenDifferenceAccepted(0.0151, tolerance: 0.015), isFalse);
  });
}
