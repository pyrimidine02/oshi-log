/// EN: Place guide DTOs.
/// KO: 장소 가이드 DTO.
library;

class PlaceGuideSummaryDto {
  const PlaceGuideSummaryDto({
    required this.id,
    required this.title,
    required this.contentPreview,
    required this.pinPriority,
    required this.isPublished,
    required this.hasImages,
    required this.imageCount,
    required this.createdAt,
    required this.updatedAt,
    required this.editorSubjectId,
  });

  final String id;
  final String title;
  final String contentPreview;
  final int pinPriority;
  final bool isPublished;
  final bool hasImages;
  final int imageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String editorSubjectId;

  factory PlaceGuideSummaryDto.fromJson(Map<String, dynamic> json) {
    return PlaceGuideSummaryDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contentPreview: json['contentPreview'] as String? ?? '',
      pinPriority: _int(json['pinPriority']),
      isPublished: json['isPublished'] as bool? ?? false,
      hasImages: json['hasImages'] as bool? ?? false,
      imageCount: _int(json['imageCount']),
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
      editorSubjectId: json['editorSubjectId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contentPreview': contentPreview,
      'pinPriority': pinPriority,
      'isPublished': isPublished,
      'hasImages': hasImages,
      'imageCount': imageCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'editorSubjectId': editorSubjectId,
    };
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
