/// EN: Place guide domain entities.
/// KO: 장소 가이드 도메인 엔티티.
library;

import 'package:intl/intl.dart';

class PlaceGuideSummary {
  const PlaceGuideSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.hasImages,
    required this.imageCount,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime? updatedAt;
  final bool hasImages;
  final int imageCount;

  String get updatedAtLabel {
    if (updatedAt == null) return '';
    return DateFormat('yyyy.MM.dd').format(updatedAt!.toLocal());
  }
}
