/// EN: News domain entities.
/// KO: 뉴스 도메인 엔티티.
library;

import 'package:intl/intl.dart';

class NewsSummary {
  const NewsSummary({
    required this.id,
    required this.title,
    required this.publishedAt,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final DateTime publishedAt;
  final String? thumbnailUrl;

  String get dateLabel {
    return DateFormat('yyyy.MM.dd').format(publishedAt.toLocal());
  }
}

class NewsDetail {
  const NewsDetail({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.publishedAt,
    this.coverImageUrl,
    this.imageUrls = const [],
  });

  final String id;
  final String title;
  final String body;
  final String status;
  final DateTime publishedAt;
  final String? coverImageUrl;
  final List<String> imageUrls;

  String get dateLabel {
    return DateFormat('yyyy.MM.dd').format(publishedAt.toLocal());
  }
}
