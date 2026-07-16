import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// EN: Returns whether a golden difference stays within the configured limit.
/// KO: Golden 차이가 설정한 허용 한도 이내인지 반환합니다.
bool isGoldenDifferenceAccepted(
  double difference, {
  required double tolerance,
}) {
  assert(
    0 <= difference && difference <= 1,
    'difference must be between 0 and 1',
  );
  assert(0 <= tolerance && tolerance <= 1, 'tolerance must be between 0 and 1');
  return difference <= tolerance;
}

/// EN: Allows a bounded pixel difference caused by Flutter rasterizer drift.
/// KO: Flutter 래스터라이저 차이로 인한 제한된 픽셀 차이를 허용합니다.
final class TolerantLocalFileComparator extends LocalFileComparator {
  TolerantLocalFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         0 <= precisionTolerance && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed =
        result.passed ||
        isGoldenDifferenceAccepted(
          result.diffPercent,
          tolerance: _precisionTolerance,
        );

    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
