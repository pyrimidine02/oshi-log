/// EN: Place comment DTOs.
/// KO: 장소 댓글 DTO.
library;

import 'package:oshi_log/core/models/image_meta_dto.dart';

class PlaceCommentDetailDto {
  const PlaceCommentDetailDto({
    required this.id,
    required this.authorSubjectId,
    required this.bodyMarkdown,
    required this.bodyHtml,
    required this.tags,
    required this.photoUploadIds,
    required this.photos,
    required this.replyCount,
    required this.isAdminNote,
    required this.isPinnedByAdmin,
    required this.createdAt,
  });

  final String id;
  final String authorSubjectId;
  final String bodyMarkdown;
  final String? bodyHtml;
  final List<String> tags;
  final List<String> photoUploadIds;
  final List<ImageMetaDto> photos;
  final int replyCount;
  final bool isAdminNote;
  final bool isPinnedByAdmin;
  final DateTime? createdAt;

  factory PlaceCommentDetailDto.fromJson(Map<String, dynamic> json) {
    return PlaceCommentDetailDto(
      id: json['id'] as String? ?? '',
      authorSubjectId: json['authorSubjectId'] as String? ?? '',
      bodyMarkdown: json['bodyMarkdown'] as String? ?? '',
      bodyHtml: json['bodyHtml'] as String?,
      tags: _stringList(json['tags']),
      photoUploadIds: _stringList(json['photoUploadIds']),
      photos: _imageList(json['photos']),
      replyCount: _int(json['replyCount']),
      isAdminNote: json['isAdminNote'] as bool? ?? false,
      isPinnedByAdmin: json['isPinnedByAdmin'] as bool? ?? false,
      createdAt: _dateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorSubjectId': authorSubjectId,
      'bodyMarkdown': bodyMarkdown,
      'bodyHtml': bodyHtml,
      'tags': tags,
      'photoUploadIds': photoUploadIds,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'replyCount': replyCount,
      'isAdminNote': isAdminNote,
      'isPinnedByAdmin': isPinnedByAdmin,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class CreatePlaceCommentRequestDto {
  const CreatePlaceCommentRequestDto({
    required this.bodyMarkdown,
    required this.tags,
    required this.photoUploadIds,
    required this.isPublic,
  });

  final String bodyMarkdown;
  final List<String> tags;
  final List<String> photoUploadIds;
  final bool isPublic;

  Map<String, dynamic> toJson() {
    return {
      'bodyMarkdown': bodyMarkdown,
      'tags': tags,
      'photoUploadIds': photoUploadIds,
      'isPublic': isPublic,
    };
  }
}

class PlaceCommentResponseDto {
  const PlaceCommentResponseDto({required this.comment, this.message});

  final PlaceCommentDetailDto comment;
  final String? message;

  factory PlaceCommentResponseDto.fromJson(Map<String, dynamic> json) {
    return PlaceCommentResponseDto(
      comment: PlaceCommentDetailDto.fromJson(
        json['comment'] as Map<String, dynamic>? ?? const {},
      ),
      message: json['message'] as String?,
    );
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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return <String>[];
}

List<ImageMetaDto> _imageList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(ImageMetaDto.fromJson)
        .toList();
  }
  return <ImageMetaDto>[];
}
