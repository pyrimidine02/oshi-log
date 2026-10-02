/// EN: News DTOs aligned with Swagger schema.
/// KO: Swagger 스키마에 맞춘 뉴스 DTO.
library;

import 'package:oshi_log/core/models/image_meta_dto.dart';

class NewsSummaryDto {
  const NewsSummaryDto({
    required this.id,
    required this.title,
    required this.publishedAt,
    this.thumbnailUrl,
    this.thumbnailFilename,
    this.thumbnailSize,
  });

  final String id;
  final String title;
  final DateTime publishedAt;
  final String? thumbnailUrl;
  final String? thumbnailFilename;
  final int? thumbnailSize;

  factory NewsSummaryDto.fromJson(Map<String, dynamic> json) {
    return NewsSummaryDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      publishedAt: _dateTime(json['publishedAt']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailFilename: json['thumbnailFilename'] as String?,
      thumbnailSize: _intOrNull(json['thumbnailSize']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'publishedAt': publishedAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'thumbnailFilename': thumbnailFilename,
      'thumbnailSize': thumbnailSize,
    };
  }
}

class NewsDetailDto {
  const NewsDetailDto({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.publishedAt,
    required this.images,
    this.coverImage,
  });

  final String id;
  final String title;
  final String body;
  final String status;
  final DateTime publishedAt;
  final List<ImageMetaDto> images;
  final ImageMetaDto? coverImage;

  factory NewsDetailDto.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final images = <ImageMetaDto>[];
    if (imagesRaw is List) {
      images.addAll(
        imagesRaw.whereType<Map<String, dynamic>>().map(ImageMetaDto.fromJson),
      );
    }

    return NewsDetailDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? '',
      publishedAt: _dateTime(json['publishedAt']),
      images: images,
      coverImage: json['coverImage'] is Map<String, dynamic>
          ? ImageMetaDto.fromJson(json['coverImage'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'status': status,
      'publishedAt': publishedAt.toIso8601String(),
      'images': images.map((image) => image.toJson()).toList(),
      'coverImage': coverImage?.toJson(),
    };
  }
}

DateTime _dateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
